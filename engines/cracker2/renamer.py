from __future__ import annotations

import re
from typing import Dict, Set, Optional, List
from ast_nodes import (
    ASTNode,
    Program,
    Block,
    Statement,
    Expression,
    LocalAssign,
    Assign,
    LocalFunctionDef,
    FunctionDef,
    FunctionExpr,
    Identifier,
    StringLiteral,
    NumberLiteral,
    CallExpr,
    MemberExpr,
    ForNumeric,
    ForGeneric,
)
from lexer import KEYWORDS


class ScopeRenameContext:
    def __init__(self, parent: Optional[ScopeRenameContext] = None, is_function: bool = False):
        self.parent = parent
        self.is_function = is_function
        self.var_map: Dict[str, str] = {}
        self.used_names: Set[str] = set(KEYWORDS)
        if parent:
            self.used_names.update(parent.used_names)
        self.local_counter = 0

    def resolve(self, name: str) -> str:
        if name in self.var_map:
            return self.var_map[name]
        if self.parent:
            return self.parent.resolve(name)
        return name

    def allocate_name(self, old_name: str, hint: Optional[str] = None) -> str:
        if old_name in self.var_map:
            return self.var_map[old_name]

        # Preserve already clean/meaningful identifier names (e.g. print, math, message, count)
        if not self.is_obfuscated_name(old_name) and old_name not in self.used_names:
            self.var_map[old_name] = old_name
            self.used_names.add(old_name)
            return old_name

        base = hint if hint and hint not in self.used_names else "var"
        self.local_counter += 1
        new_name = f"{base}_{self.local_counter}"
        while new_name in self.used_names:
            self.local_counter += 1
            new_name = f"{base}_{self.local_counter}"

        self.used_names.add(new_name)
        self.var_map[old_name] = new_name
        return new_name

    def is_obfuscated_name(self, name: str) -> bool:
        # Register-like names: R0, R1, v_0, v0, etc.
        if re.match(r"^[RrVv]_\d+$", name) or re.match(r"^[Rr]\d+$", name):
            return True
        # Single-character upper/lower or underscore names (e.g. O, J, h, b, A, m, H, p, E, e, X, _, u)
        if len(name) == 1 and (name.isupper() or name in "_"):
            return True
        if re.match(r"^_\d+$", name):
            return True
        return False


class ScopeAwareRenamer:
    def __init__(self):
        self.root_context = ScopeRenameContext()

    def rename_program(self, program: Program) -> Program:
        self.rename_block(program.body, self.root_context)
        return program

    def rename_block(self, block: Block, ctx: ScopeRenameContext):
        for stmt in block.statements:
            self.rename_statement(stmt, ctx)

    def rename_statement(self, stmt: Statement, ctx: ScopeRenameContext):
        if isinstance(stmt, LocalAssign):
            for i, target in enumerate(stmt.targets):
                hint = "val"
                if i < len(stmt.values):
                    val = stmt.values[i]
                    if isinstance(val, StringLiteral):
                        hint = "message" if " " in val.value else "str"
                    elif isinstance(val, NumberLiteral):
                        hint = "num"
                    elif isinstance(val, CallExpr) and isinstance(val.callee, Identifier):
                        hint = val.callee.name.lower()
                    elif isinstance(val, FunctionExpr):
                        hint = "fn"

                new_target_name = ctx.allocate_name(target.name, hint)
                target.name = new_target_name

            for val in stmt.values:
                self.rename_expression(val, ctx)

        elif isinstance(stmt, Assign):
            for t in stmt.targets:
                self.rename_expression(t, ctx)
            for v in stmt.values:
                self.rename_expression(v, ctx)

        elif isinstance(stmt, LocalFunctionDef):
            new_fn_name = ctx.allocate_name(stmt.name, "fn")
            stmt.name = new_fn_name

            fn_ctx = ScopeRenameContext(parent=ctx, is_function=True)
            new_params: List[str] = []
            seen_param_names: Set[str] = set()

            for idx, p in enumerate(stmt.params):
                p_hint = f"arg_{idx + 1}"
                new_p = fn_ctx.allocate_name(p if p not in seen_param_names else f"{p}_{idx+1}", p_hint)
                seen_param_names.add(p)
                new_params.append(new_p)

            stmt.params = new_params
            self.rename_block(stmt.body, fn_ctx)

        elif isinstance(stmt, FunctionDef):
            self.rename_expression(stmt.name, ctx)

            fn_ctx = ScopeRenameContext(parent=ctx, is_function=True)
            new_params = []
            seen_param_names = set()

            for idx, p in enumerate(stmt.params):
                p_hint = f"arg_{idx + 1}"
                new_p = fn_ctx.allocate_name(p if p not in seen_param_names else f"{p}_{idx+1}", p_hint)
                seen_param_names.add(p)
                new_params.append(new_p)

            stmt.params = new_params
            self.rename_block(stmt.body, fn_ctx)

        elif isinstance(stmt, ForNumeric):
            self.rename_expression(stmt.start, ctx)
            self.rename_expression(stmt.stop, ctx)
            if stmt.step:
                self.rename_expression(stmt.step, ctx)

            loop_ctx = ScopeRenameContext(parent=ctx)
            stmt.var_name = loop_ctx.allocate_name(stmt.var_name, "i")
            self.rename_block(stmt.body, loop_ctx)

        elif isinstance(stmt, ForGeneric):
            for it in stmt.iterators:
                self.rename_expression(it, ctx)

            loop_ctx = ScopeRenameContext(parent=ctx)
            stmt.var_names = [loop_ctx.allocate_name(v, "item") for v in stmt.var_names]
            self.rename_block(stmt.body, loop_ctx)

        else:
            # General statement traversal
            if hasattr(stmt, "__dict__"):
                for k, v in stmt.__dict__.items():
                    if isinstance(v, Block):
                        block_ctx = ScopeRenameContext(parent=ctx)
                        self.rename_block(v, block_ctx)
                    elif isinstance(v, Expression):
                        self.rename_expression(v, ctx)
                    elif isinstance(v, list):
                        for item in v:
                            if isinstance(item, tuple):
                                for sub in item:
                                    if isinstance(sub, Expression):
                                        self.rename_expression(sub, ctx)
                                    elif isinstance(sub, Block):
                                        b_ctx = ScopeRenameContext(parent=ctx)
                                        self.rename_block(sub, b_ctx)
                            elif isinstance(item, Expression):
                                self.rename_expression(item, ctx)
                            elif isinstance(item, Block):
                                b_ctx = ScopeRenameContext(parent=ctx)
                                self.rename_block(item, b_ctx)

    def rename_expression(self, expr: Expression, ctx: ScopeRenameContext):
        if expr is None:
            return

        if isinstance(expr, Identifier):
            expr.name = ctx.resolve(expr.name)

        elif isinstance(expr, FunctionExpr):
            fn_ctx = ScopeRenameContext(parent=ctx, is_function=True)
            new_params = []
            seen_param_names = set()

            for idx, p in enumerate(expr.params):
                p_hint = f"arg_{idx + 1}"
                new_p = fn_ctx.allocate_name(p if p not in seen_param_names else f"{p}_{idx+1}", p_hint)
                seen_param_names.add(p)
                new_params.append(new_p)

            expr.params = new_params
            self.rename_block(expr.body, fn_ctx)

        else:
            if hasattr(expr, "__dict__"):
                for k, v in expr.__dict__.items():
                    if isinstance(v, Expression):
                        self.rename_expression(v, ctx)
                    elif isinstance(v, Block):
                        b_ctx = ScopeRenameContext(parent=ctx)
                        self.rename_block(v, b_ctx)
                    elif isinstance(v, list):
                        for item in v:
                            if isinstance(item, Expression):
                                self.rename_expression(item, ctx)
                            elif hasattr(item, "value") and isinstance(item.value, Expression):
                                self.rename_expression(item.value, ctx)
                                if hasattr(item, "key") and isinstance(item.key, Expression):
                                    self.rename_expression(item.key, ctx)


def rename_variables(program: Program) -> Program:
    return ScopeAwareRenamer().rename_program(program)
