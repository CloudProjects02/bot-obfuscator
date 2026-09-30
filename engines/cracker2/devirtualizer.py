from __future__ import annotations

import re
from typing import List, Dict, Optional, Tuple, Any, Set
from ast_nodes import (
    ASTNode,
    Program,
    Block,
    Statement,
    Expression,
    LocalAssign,
    Assign,
    CallStatement,
    CallExpr,
    Identifier,
    StringLiteral,
    NumberLiteral,
    TableConstructor,
    TableField,
    IfStatement,
    WhileStatement,
    BinaryExpr,
    UnaryExpr,
    IndexExpr,
    MemberExpr,
    ReturnStatement,
)
from vm_detector import VMAnalysisReport


class VMInstructionDecompiler:
    """Disassembles and decompiles virtual machine instruction handlers into semantic operations."""

    @staticmethod
    def decompile_handler_stmt(stmt: Statement) -> Optional[str]:
        # Detect registers[A] = registers[B] + registers[C]
        if isinstance(stmt, Assign) and len(stmt.targets) == 1 and len(stmt.values) == 1:
            tgt = stmt.targets[0]
            val = stmt.values[0]

            if isinstance(val, BinaryExpr):
                return f"REGISTER_OP: {val.op}"
            if isinstance(val, UnaryExpr):
                return f"UNARY_OP: {val.op}"
            if isinstance(val, CallExpr):
                return "CALL_OP"
            if isinstance(val, IndexExpr):
                return "GET_TABLE_OP"

        if isinstance(stmt, ReturnStatement):
            return "RETURN_OP"

        return None


class Devirtualizer:
    def __init__(self, vm_report: VMAnalysisReport):
        self.vm_report = vm_report
        self.recovered_opcodes: Dict[int, str] = {}
        self.is_partial = False

    def devirtualize(self, program: Program) -> Tuple[Program, str]:
        """Attempt static devirtualization on recognized VM structures."""
        if not self.vm_report.vm_detected:
            return program, "No VM detected (native code preserved)"

        # Scan for opcode switch branches in the VM dispatcher
        self.scan_dispatcher_opcodes(program.body)

        status = f"analyzed ({len(self.recovered_opcodes)} opcodes mapped)" if self.recovered_opcodes else "analyzed (bytecode virtualized)"
        return program, status

    def scan_dispatcher_opcodes(self, node: ASTNode):
        if node is None:
            return

        if isinstance(node, IfStatement):
            for cond, body in node.branches:
                # Check for comparison against opcode integer (e.g. A == 36, A < 39, A >= 26)
                if isinstance(cond, BinaryExpr):
                    op_num = None
                    if isinstance(cond.right, NumberLiteral):
                        op_num = int(cond.right.value)
                    elif isinstance(cond.left, NumberLiteral):
                        op_num = int(cond.left.value)

                    if op_num is not None:
                        # Inspect body statements
                        for s in body.statements:
                            op_type = VMInstructionDecompiler.decompile_handler_stmt(s)
                            if op_type:
                                self.recovered_opcodes[op_num] = op_type
                                break

        # Recurse
        if hasattr(node, "__dict__"):
            for k, v in node.__dict__.items():
                if isinstance(v, list):
                    for item in v:
                        if isinstance(item, ASTNode):
                            self.scan_dispatcher_opcodes(item)
                elif isinstance(v, ASTNode):
                    self.scan_dispatcher_opcodes(v)


def devirtualize_program(program: Program, vm_report: VMAnalysisReport) -> Tuple[Program, str]:
    return Devirtualizer(vm_report).devirtualize(program)
