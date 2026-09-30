from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import List, Dict, Set, Optional, Tuple, Any
from ast_nodes import (
    ASTNode,
    Program,
    Block,
    Statement,
    Expression,
    WhileStatement,
    RepeatStatement,
    IfStatement,
    TableConstructor,
    TableField,
    IndexExpr,
    MemberExpr,
    Identifier,
    NumberLiteral,
    Assign,
    LocalAssign,
    BinaryExpr,
    UnaryExpr,
    CallExpr,
)


@dataclass
class VMAnalysisReport:
    vm_detected: bool = False
    confidence: str = "none"  # 'high', 'medium', 'low', 'none'
    possible_opcode_count: int = 0
    possible_register_array: Optional[str] = None
    possible_instruction_stream: Optional[str] = None
    possible_pc_variable: Optional[str] = None
    indicators: List[str] = field(default_factory=list)
    handlers: Dict[int, str] = field(default_factory=dict)

    def format(self) -> str:
        if not self.vm_detected:
            return "[VM / Virtualized Code]\nVM-like dispatcher: not detected"

        lines = ["[VM / Virtualized Code]"]
        lines.append("VM-like dispatcher detected")
        lines.append(f"Confidence: {self.confidence}")
        if self.possible_opcode_count > 0:
            lines.append(f"Possible opcode count: {self.possible_opcode_count}")
        if self.possible_register_array:
            lines.append(f"Possible register array: {self.possible_register_array}")
        if self.possible_pc_variable:
            lines.append(f"Possible PC variable: {self.possible_pc_variable}")
        if self.possible_instruction_stream:
            lines.append(f"Possible instruction stream: {self.possible_instruction_stream}")

        if self.indicators:
            lines.append("\nIndicators:")
            for ind in self.indicators:
                lines.append(f" - {ind}")

        return "\n".join(lines)


class VMDetector:
    def __init__(self):
        self.report = VMAnalysisReport()

    def analyze(self, program: Program, raw_source: Optional[str] = None) -> VMAnalysisReport:
        self.scan_ast(program)

        if raw_source:
            self.scan_source(raw_source)

        return self.report

    def scan_ast(self, node: ASTNode):
        if node is None:
            return

        # Check for dispatcher while/repeat loop
        if isinstance(node, (WhileStatement, RepeatStatement)):
            if len(node.body.statements) >= 3:
                # Inspect for nested binary if switches
                if_count = sum(1 for s in node.body.statements if isinstance(s, IfStatement))
                if if_count >= 1:
                    self.report.vm_detected = True
                    self.report.indicators.append(f"Interpreter dispatch loop at line {node.line}")

        # Check for nested if-statement binary decision trees (opcode decoders)
        if isinstance(node, IfStatement):
            depth = self.get_if_nesting_depth(node)
            if depth >= 4:
                self.report.vm_detected = True
                self.report.indicators.append(f"Deep binary decision tree (depth {depth}) at line {node.line}")
                op_count = self.count_leaf_branches(node)
                self.report.possible_opcode_count = max(self.report.possible_opcode_count, op_count)

        # Check for register array lookups: F[R[v]] or registers[idx]
        if isinstance(node, IndexExpr):
            if isinstance(node.table, Identifier) and isinstance(node.index, (IndexExpr, Identifier, NumberLiteral)):
                tbl_name = node.table.name
                if tbl_name in ("F", "R", "registers", "stack", "env"):
                    self.report.possible_register_array = tbl_name

        # Recurse
        if hasattr(node, "__dict__"):
            for k, v in node.__dict__.items():
                if isinstance(v, list):
                    for item in v:
                        if isinstance(item, ASTNode):
                            self.scan_ast(item)
                elif isinstance(v, ASTNode):
                    self.scan_ast(v)

    def scan_source(self, source: str):
        # Look for Luraph VM patterns
        if "Luraph" in source or "LPH" in source:
            self.report.vm_detected = True
            self.report.confidence = "high"
            self.report.indicators.append("Luraph v15 VM signature")

            # Look for register array references: F[...], R[...]
            reg_match = re.search(r'([A-Za-z_][A-Za-z0-9_]*)\[[A-Za-z_][A-Za-z0-9_]*\[[A-Za-z_][A-Za-z0-9_]*\]\]', source)
            if reg_match:
                self.report.possible_register_array = reg_match.group(1)

            # Look for PC stepping: V += 1, V -= 1, pc = pc + 1
            pc_match = re.search(r'([A-Za-z_][A-Za-z0-9_]*)\s*[\+\-]=\s*1', source)
            if pc_match:
                self.report.possible_pc_variable = pc_match.group(1)

            # Look for opcode tests: A >= 26, A < 39
            op_comparisons = re.findall(r'[A-Za-z_][A-Za-z0-9_]*\s*(?:<=|>=|<|>|==)\s*(\d+)', source)
            if op_comparisons:
                max_op = max(int(x) for x in op_comparisons)
                self.report.possible_opcode_count = max(self.report.possible_opcode_count, max_op + 1)

            if "buffer.fromstring" in source or "buffer.readu32" in source or "buffer.readi16" in source:
                self.report.possible_instruction_stream = "Luau Bytecode Buffer"
            elif "string.unpack" in source or "string.byte" in source:
                self.report.possible_instruction_stream = "String Bytecode Stream"

        elif self.report.vm_detected:
            if self.report.possible_opcode_count > 30:
                self.report.confidence = "high"
            else:
                self.report.confidence = "medium"

    def get_if_nesting_depth(self, if_node: IfStatement) -> int:
        max_d = 1
        for _, body in if_node.branches:
            for s in body.statements:
                if isinstance(s, IfStatement):
                    max_d = max(max_d, 1 + self.get_if_nesting_depth(s))
        if if_node.else_body:
            for s in if_node.else_body.statements:
                if isinstance(s, IfStatement):
                    max_d = max(max_d, 1 + self.get_if_nesting_depth(s))
        return max_d

    def count_leaf_branches(self, if_node: IfStatement) -> int:
        count = len(if_node.branches)
        for _, body in if_node.branches:
            for s in body.statements:
                if isinstance(s, IfStatement):
                    count += self.count_leaf_branches(s)
        if if_node.else_body:
            count += 1
            for s in if_node.else_body.statements:
                if isinstance(s, IfStatement):
                    count += self.count_leaf_branches(s)
        return count


def detect_vm(program: Program, raw_source: Optional[str] = None) -> VMAnalysisReport:
    return VMDetector().analyze(program, raw_source)
