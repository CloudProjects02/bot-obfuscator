from __future__ import annotations

import re
from typing import List, Optional
from ast_nodes import (
    ASTNode,
    Program,
    Block,
    Statement,
    Expression,
    LocalAssign,
    Assign,
    CompoundAssign,
    FunctionDef,
    LocalFunctionDef,
    IfStatement,
    WhileStatement,
    RepeatStatement,
    ForNumeric,
    ForGeneric,
    DoBlock,
    ReturnStatement,
    BreakStatement,
    ContinueStatement,
    CallStatement,
    GenericStatement,
    NumberLiteral,
    StringLiteral,
    BooleanLiteral,
    NilLiteral,
    VarargLiteral,
    Identifier,
    BinaryExpr,
    UnaryExpr,
    TableConstructor,
    TableField,
    IndexExpr,
    MemberExpr,
    CallExpr,
    MethodCallExpr,
    FunctionExpr,
    ParenthesizedExpr,
    IfExpr,
)
from structure import BINARY_PRECEDENCE, UNARY_PRECEDENCE


def block_has_continue(block: Block) -> bool:
    if not block or not block.statements:
        return False
    for stmt in block.statements:
        if isinstance(stmt, ContinueStatement):
            return True
        if isinstance(stmt, IfStatement):
            for _, b in stmt.branches:
                if block_has_continue(b):
                    return True
            if stmt.else_body and block_has_continue(stmt.else_body):
                return True
        if isinstance(stmt, DoBlock) and block_has_continue(stmt.body):
            return True
    return False


class LuaCodeGenerator:
    def __init__(self, indent_size: int = 4):
        self.indent_size = indent_size
        self.indent_level = 0
        self.inside_continue_loop = False

    def indent_str(self) -> str:
        return " " * (self.indent_level * self.indent_size)

    def generate(self, program: Program, header_comment: Optional[str] = None) -> str:
        lines: List[str] = []
        if header_comment:
            lines.append(header_comment.strip())
        for stmt in program.body.statements:
            code = self.emit_statement(stmt)
            if code:
                lines.append(code)
        return "\n\n".join(lines) + ("\n" if lines else "")

    def emit_block(self, block: Block) -> str:
        self.indent_level += 1
        lines: List[str] = []
        for stmt in block.statements:
            code = self.emit_statement(stmt)
            if code:
                lines.append(code)
        self.indent_level -= 1
        return "\n".join(lines)

    def emit_statement(self, stmt: Statement) -> str:
        prefix = self.indent_str()

        if isinstance(stmt, LocalAssign):
            targets_str = ", ".join(t.name for t in stmt.targets)
            if stmt.values:
                vals_str = ", ".join(self.emit_expression(v) for v in stmt.values)
                return f"{prefix}local {targets_str} = {vals_str}"
            return f"{prefix}local {targets_str}"

        if isinstance(stmt, Assign):
            targets_str = ", ".join(self.emit_expression(t) for t in stmt.targets)
            vals_str = ", ".join(self.emit_expression(v) for v in stmt.values)
            return f"{prefix}{targets_str} = {vals_str}"

        if isinstance(stmt, CompoundAssign):
            target_str = self.emit_expression(stmt.target)
            val_str = self.emit_expression(stmt.value)
            op = stmt.op[:-1]  # Desugar '+=' to '+', '-=' to '-', etc.
            return f"{prefix}{target_str} = {target_str} {op} {val_str}"

        if isinstance(stmt, LocalFunctionDef):
            params_str = ", ".join(stmt.params + (["..."] if stmt.is_vararg else []))
            body_code = self.emit_block(stmt.body)
            header = f"{prefix}local function {stmt.name}({params_str})"
            if body_code:
                return f"{header}\n{body_code}\n{prefix}end"
            return f"{header}\n{prefix}end"

        if isinstance(stmt, FunctionDef):
            name_str = self.emit_expression(stmt.name)
            params_str = ", ".join(stmt.params + (["..."] if stmt.is_vararg else []))
            body_code = self.emit_block(stmt.body)
            header = f"{prefix}function {name_str}({params_str})"
            if body_code:
                return f"{header}\n{body_code}\n{prefix}end"
            return f"{header}\n{prefix}end"

        if isinstance(stmt, IfStatement):
            lines = []
            for i, (cond, body) in enumerate(stmt.branches):
                cond_str = self.emit_expression(cond)
                kw = "if" if i == 0 else "elseif"
                lines.append(f"{prefix}{kw} {cond_str} then")
                body_code = self.emit_block(body)
                if body_code:
                    lines.append(body_code)

            if stmt.else_body:
                lines.append(f"{prefix}else")
                else_code = self.emit_block(stmt.else_body)
                if else_code:
                    lines.append(else_code)

            lines.append(f"{prefix}end")
            return "\n".join(lines)

        if isinstance(stmt, WhileStatement):
            cond_str = self.emit_expression(stmt.condition)
            has_cont = block_has_continue(stmt.body)
            header = f"{prefix}while {cond_str} do"
            if has_cont:
                prev = self.inside_continue_loop
                self.inside_continue_loop = True
                self.indent_level += 1
                body_code = self.emit_block(stmt.body)
                self.indent_level -= 1
                self.inside_continue_loop = prev
                inner_pfx = " " * (self.indent_size * (self.indent_level + 1))
                return f"{header}\n{inner_pfx}repeat\n{body_code}\n{inner_pfx}until true\n{prefix}end"
            else:
                body_code = self.emit_block(stmt.body)
                if body_code:
                    return f"{header}\n{body_code}\n{prefix}end"
                return f"{header}\n{prefix}end"

        if isinstance(stmt, RepeatStatement):
            body_code = self.emit_block(stmt.body)
            cond_str = self.emit_expression(stmt.condition)
            header = f"{prefix}repeat"
            if body_code:
                return f"{header}\n{body_code}\n{prefix}until {cond_str}"
            return f"{header}\n{prefix}until {cond_str}"

        if isinstance(stmt, ForNumeric):
            start_str = self.emit_expression(stmt.start)
            stop_str = self.emit_expression(stmt.stop)
            step_str = f", {self.emit_expression(stmt.step)}" if stmt.step else ""
            has_cont = block_has_continue(stmt.body)
            header = f"{prefix}for {stmt.var_name} = {start_str}, {stop_str}{step_str} do"
            if has_cont:
                prev = self.inside_continue_loop
                self.inside_continue_loop = True
                self.indent_level += 1
                body_code = self.emit_block(stmt.body)
                self.indent_level -= 1
                self.inside_continue_loop = prev
                inner_pfx = " " * (self.indent_size * (self.indent_level + 1))
                return f"{header}\n{inner_pfx}repeat\n{body_code}\n{inner_pfx}until true\n{prefix}end"
            else:
                body_code = self.emit_block(stmt.body)
                if body_code:
                    return f"{header}\n{body_code}\n{prefix}end"
                return f"{header}\n{prefix}end"

        if isinstance(stmt, ForGeneric):
            vars_str = ", ".join(stmt.var_names)
            iters_str = ", ".join(self.emit_expression(it) for it in stmt.iterators)
            has_cont = block_has_continue(stmt.body)
            header = f"{prefix}for {vars_str} in {iters_str} do"
            if has_cont:
                prev = self.inside_continue_loop
                self.inside_continue_loop = True
                self.indent_level += 1
                body_code = self.emit_block(stmt.body)
                self.indent_level -= 1
                self.inside_continue_loop = prev
                inner_pfx = " " * (self.indent_size * (self.indent_level + 1))
                return f"{header}\n{inner_pfx}repeat\n{body_code}\n{inner_pfx}until true\n{prefix}end"
            else:
                body_code = self.emit_block(stmt.body)
                if body_code:
                    return f"{header}\n{body_code}\n{prefix}end"
                return f"{header}\n{prefix}end"

        if isinstance(stmt, DoBlock):
            body_code = self.emit_block(stmt.body)
            header = f"{prefix}do"
            if body_code:
                return f"{header}\n{body_code}\n{prefix}end"
            return f"{header}\n{prefix}end"

        if isinstance(stmt, ReturnStatement):
            if stmt.values:
                vals_str = ", ".join(self.emit_expression(v) for v in stmt.values)
                return f"{prefix}return {vals_str}"
            return f"{prefix}return"

        if isinstance(stmt, BreakStatement):
            return f"{prefix}break"

        if isinstance(stmt, ContinueStatement):
            if self.inside_continue_loop:
                return f"{prefix}break"
            return f"{prefix}continue"

        if isinstance(stmt, CallStatement):
            return f"{prefix}{self.emit_expression(stmt.call)}"

        if isinstance(stmt, GenericStatement):
            toks_str = " ".join(t.value for t in stmt.raw_tokens)
            return f"{prefix}{toks_str}"

        return ""

    def emit_expression(self, expr: Expression, parent_prec: int = 0) -> str:
        if isinstance(expr, NumberLiteral):
            return expr.raw if expr.raw else str(expr.value)

        if isinstance(expr, StringLiteral):
            val = expr.value
            escaped = (
                val.replace("\\", "\\\\")
                .replace('"', '\\"')
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t")
            )
            return f'"{escaped}"'

        if isinstance(expr, BooleanLiteral):
            return "true" if expr.value else "false"

        if isinstance(expr, NilLiteral):
            return "nil"

        if isinstance(expr, VarargLiteral):
            return "..."

        if isinstance(expr, Identifier):
            return expr.name

        if isinstance(expr, BinaryExpr):
            prec, _ = BINARY_PRECEDENCE.get(expr.op, (0, False))
            left_str = self.emit_expression(expr.left, prec)
            right_str = self.emit_expression(expr.right, prec + 1)
            code = f"{left_str} {expr.op} {right_str}"
            if prec < parent_prec:
                return f"({code})"
            return code

        if isinstance(expr, UnaryExpr):
            opnd_str = self.emit_expression(expr.operand, UNARY_PRECEDENCE)
            space = " " if expr.op == "not" else ""
            code = f"{expr.op}{space}{opnd_str}"
            if parent_prec > UNARY_PRECEDENCE:
                return f"({code})"
            return code

        if isinstance(expr, ParenthesizedExpr):
            inner = self.emit_expression(expr.expression)
            return f"({inner})"

        if isinstance(expr, IndexExpr):
            tbl_str = self.emit_expression(expr.table, 13)
            idx_str = self.emit_expression(expr.index)
            return f"{tbl_str}[{idx_str}]"

        if isinstance(expr, MemberExpr):
            tbl_str = self.emit_expression(expr.table, 13)
            return f"{tbl_str}.{expr.member}"

        if isinstance(expr, CallExpr):
            callee_str = self.emit_expression(expr.callee, 13)
            args_str = ", ".join(self.emit_expression(a) for a in expr.args)
            return f"{callee_str}({args_str})"

        if isinstance(expr, MethodCallExpr):
            rcv_str = self.emit_expression(expr.receiver, 13)
            args_str = ", ".join(self.emit_expression(a) for a in expr.args)
            return f"{rcv_str}:{expr.method}({args_str})"

        if isinstance(expr, TableConstructor):
            if not expr.fields:
                return "{}"

            # Determine if this is a large or multiline table
            is_multiline = len(expr.fields) > 3 or any(
                isinstance(f.value, (FunctionExpr, TableConstructor)) for f in expr.fields
            )

            if not is_multiline:
                field_strs = []
                for f in expr.fields:
                    val_str = self.emit_expression(f.value)
                    if f.key:
                        if isinstance(f.key, StringLiteral) and re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", f.key.value):
                            field_strs.append(f"{f.key.value} = {val_str}")
                        else:
                            key_str = self.emit_expression(f.key)
                            field_strs.append(f"[{key_str}] = {val_str}")
                    else:
                        field_strs.append(val_str)
                return "{" + ", ".join(field_strs) + "}"

            # Format multiline table cleanly
            self.indent_level += 1
            field_lines = []
            for f in expr.fields:
                val_str = self.emit_expression(f.value)
                pfx = self.indent_str()
                if f.key:
                    if isinstance(f.key, StringLiteral) and re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", f.key.value):
                        field_lines.append(f"{pfx}{f.key.value} = {val_str},")
                    else:
                        key_str = self.emit_expression(f.key)
                        field_lines.append(f"{pfx}[{key_str}] = {val_str},")
                else:
                    field_lines.append(f"{pfx}{val_str},")
            self.indent_level -= 1

            close_pfx = self.indent_str()
            return "{\n" + "\n".join(field_lines) + f"\n{close_pfx}}}"

        if isinstance(expr, FunctionExpr):
            params_str = ", ".join(expr.params + (["..."] if expr.is_vararg else []))
            body_code = self.emit_block(expr.body)
            prefix = self.indent_str()
            if body_code:
                return f"function({params_str})\n{body_code}\n{prefix}end"
            return f"function({params_str}) end"

        if isinstance(expr, IfExpr):
            # Desugar to standard Lua 5.1 ternary: (cond and then_val or else_val)
            if len(expr.branches) == 1:
                cond_str = self.emit_expression(expr.branches[0][0])
                then_str = self.emit_expression(expr.branches[0][1])
                else_str = self.emit_expression(expr.else_expr)
                return f"({cond_str} and {then_str} or {else_str})"
            else:
                res = self.emit_expression(expr.else_expr)
                for cond, val in reversed(expr.branches):
                    c_str = self.emit_expression(cond)
                    v_str = self.emit_expression(val)
                    res = f"({c_str} and {v_str} or {res})"
                return res

        return "nil"


def generate_lua(program: Program, header_comment: Optional[str] = None) -> str:
    return LuaCodeGenerator().generate(program, header_comment=header_comment)
