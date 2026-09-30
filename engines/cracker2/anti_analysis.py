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
    CallExpr,
    MemberExpr,
    Identifier,
    StringLiteral,
    TableConstructor,
    WhileStatement,
    IfStatement,
    RepeatStatement,
    BinaryExpr,
    UnaryExpr,
)


@dataclass
class AntiAnalysisReport:
    debug_inspection: bool = False
    environment_checks: bool = False
    dynamic_compilation: bool = False
    opaque_predicates: bool = False
    control_flow_flattening: bool = False
    vm_dispatcher: bool = False
    metatable_tampering: bool = False
    integrity_self_checks: bool = False
    tamper_signals: List[str] = field(default_factory=list)

    def format(self) -> str:
        lines = ["[Anti-Analysis]"]
        lines.append(f"Debug inspection: {'detected' if self.debug_inspection else 'not detected'}")
        lines.append(f"Environment checks: {'detected' if self.environment_checks else 'not detected'}")
        lines.append(f"Dynamic compilation: {'detected' if self.dynamic_compilation else 'not detected'}")
        lines.append(f"Opaque predicates: {'detected' if self.opaque_predicates else 'not detected'}")
        lines.append(f"Control-flow flattening: {'likely' if self.control_flow_flattening else 'unlikely'}")
        lines.append(f"VM dispatcher: {'likely' if self.vm_dispatcher else 'unlikely'}")
        lines.append(f"Metatable tampering: {'detected' if self.metatable_tampering else 'not detected'}")
        lines.append(f"Integrity self-checks: {'detected' if self.integrity_self_checks else 'not detected'}")

        if self.tamper_signals:
            lines.append("\nDetected Patterns & Locations:")
            for sig in self.tamper_signals:
                lines.append(f" - {sig}")
        return "\n".join(lines)


class AntiAnalysisDetector:
    DEBUG_FUNCTIONS = {
        "debug.getinfo",
        "debug.getupvalue",
        "debug.setupvalue",
        "debug.gethook",
        "debug.sethook",
        "debug.traceback",
        "debug.getlocal",
        "debug.setlocal",
        "debug.getmetatable",
        "debug.setmetatable",
    }

    ENV_FUNCTIONS = {
        "getfenv",
        "setfenv",
        "getgenv",
        "getrenv",
        "getrawmetatable",
        "setreadonly",
        "make_readonly",
        "isreadonly",
        "hookfunction",
        "hookmetamethod",
        "newcclosure",
    }

    DYNAMIC_COMPILERS = {
        "loadstring",
        "load",
        "loadfile",
        "dofile",
    }

    def __init__(self):
        self.report = AntiAnalysisReport()

    def analyze(self, program: Program, raw_source: Optional[str] = None) -> AntiAnalysisReport:
        self.walk_ast(program)

        if raw_source:
            self.analyze_source_heuristics(raw_source)

        return self.report

    def walk_ast(self, node: ASTNode):
        if node is None:
            return

        if isinstance(node, CallExpr):
            fn_name = self.get_callee_name(node.callee)
            if fn_name:
                if fn_name in self.DEBUG_FUNCTIONS or fn_name.startswith("debug."):
                    self.report.debug_inspection = True
                    self.report.tamper_signals.append(f"Debug library inspection via `{fn_name}` at line {node.line}")

                if fn_name in self.ENV_FUNCTIONS:
                    self.report.environment_checks = True
                    self.report.tamper_signals.append(f"Environment tampering check `{fn_name}` at line {node.line}")

                if fn_name in self.DYNAMIC_COMPILERS:
                    self.report.dynamic_compilation = True
                    self.report.tamper_signals.append(f"Dynamic code compilation `{fn_name}` at line {node.line}")

                if fn_name == "setmetatable":
                    self.report.metatable_tampering = True

        if isinstance(node, (WhileStatement, RepeatStatement)):
            # Check for large dispatch loops / state machines
            if len(node.body.statements) > 10:
                self.report.vm_dispatcher = True
                self.report.control_flow_flattening = True

        if isinstance(node, IfStatement):
            # Check for opaque predicates (e.g. 0 == h % 2, 1 ~= X, not not (128 <= J))
            for cond, _ in node.branches:
                if isinstance(cond, UnaryExpr) and cond.op == "not" and isinstance(cond.operand, UnaryExpr) and cond.operand.op == "not":
                    self.report.opaque_predicates = True
                elif isinstance(cond, BinaryExpr) and cond.op in ("==", "~="):
                    if isinstance(cond.left, BinaryExpr) and cond.left.op == "%":
                        self.report.opaque_predicates = True

        # Walk children
        if hasattr(node, "__dict__"):
            for k, v in node.__dict__.items():
                if isinstance(v, list):
                    for item in v:
                        if isinstance(item, ASTNode):
                            self.walk_ast(item)
                elif isinstance(v, ASTNode):
                    self.walk_ast(v)

    def analyze_source_heuristics(self, source: str):
        if "debug.getinfo" in source or "debug.traceback" in source:
            self.report.debug_inspection = True
        if "getfenv" in source or "setfenv" in source or "getgenv" in source:
            self.report.environment_checks = True
        if "loadstring" in source:
            self.report.dynamic_compilation = True
        if "setmetatable" in source and "__index" in source:
            self.report.metatable_tampering = True
        if "LPH" in source or "Luraph" in source:
            self.report.vm_dispatcher = True
            self.report.control_flow_flattening = True
            self.report.integrity_self_checks = True

    def get_callee_name(self, callee: Expression) -> Optional[str]:
        if isinstance(callee, Identifier):
            return callee.name
        if isinstance(callee, MemberExpr) and isinstance(callee.table, Identifier):
            return f"{callee.table.name}.{callee.member}"
        return None


def detect_anti_analysis(program: Program, raw_source: Optional[str] = None) -> AntiAnalysisReport:
    return AntiAnalysisDetector().analyze(program, raw_source)
