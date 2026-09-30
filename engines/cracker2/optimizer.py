from __future__ import annotations

import copy
from typing import List, Dict, Optional, Tuple, Any, Set, Union
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
from constants import ConstantEvaluator, fold_expression, ConstantValue


class TablePropertyMap:
    def __init__(self):
        # Map of (table_name_or_id, key) -> Expression
        self.properties: Dict[Tuple[str, Union[str, int]], Expression] = {}
        # Known global table mappings (e.g. from setmetatable({ [105] = bit32.band, ... }))
        self.global_table_props: Dict[Union[str, int], Expression] = {}

    def register_field(self, key: Union[str, int], expr: Expression):
        self.global_table_props[key] = expr

    def lookup_global(self, key: Union[str, int]) -> Optional[Expression]:
        return self.global_table_props.get(key)


class ASTOptimizer:
    def __init__(self):
        self.folded_constants_count = 0
        self.dead_branches_removed = 0
        self.propagated_variables_count = 0
        self.table_map = TablePropertyMap()
        self.alias_map: Dict[str, Expression] = {}

    def optimize(self, program: Program) -> Program:
        # Collect static table entries across program (e.g. Luraph dispatch tables)
        self.scan_table_constructors(program.body)

        # Pass 1: Constant folding & boolean simplification
        prog1 = self.optimize_program(program)

        # Pass 2: Propagate table members and function aliases
        prog2 = self.propagate_table_and_aliases(prog1)

        # Pass 3: Final fold on simplified AST
        prog3 = self.optimize_program(prog2)

        return prog3

    def scan_table_constructors(self, node: ASTNode):
        if node is None:
            return

        if isinstance(node, TableConstructor):
            for f in node.fields:
                if f.key:
                    k_val = None
                    if isinstance(f.key, NumberLiteral):
                        k_val = int(f.key.value) if isinstance(f.key.value, int) or (isinstance(f.key.value, float) and f.key.value.is_integer()) else f.key.value
                    elif isinstance(f.key, StringLiteral):
                        k_val = f.key.value
                    elif isinstance(f.key, Identifier):
                        k_val = f.key.name

                    if k_val is not None:
                        self.table_map.register_field(k_val, f.value)

        # Recurse
        if hasattr(node, "__dict__"):
            for k, v in node.__dict__.items():
                if isinstance(v, list):
                    for item in v:
                        if isinstance(item, ASTNode):
                            self.scan_table_constructors(item)
                elif isinstance(v, ASTNode):
                    self.scan_table_constructors(v)

    def optimize_program(self, program: Program) -> Program:
        new_body = self.optimize_block(program.body)
        return Program(body=new_body, token=program.token)

    def optimize_block(self, block: Block, env: Optional[Dict[str, ConstantValue]] = None) -> Block:
        if env is None:
            env = {}

        new_statements: List[Statement] = []
        is_terminated = False

        for stmt in block.statements:
            if is_terminated:
                self.dead_branches_removed += 1
                continue

            opt_stmt = self.optimize_statement(stmt, env)
            if opt_stmt is not None:
                if isinstance(opt_stmt, list):
                    new_statements.extend(opt_stmt)
                else:
                    new_statements.append(opt_stmt)

            if isinstance(stmt, (ReturnStatement, BreakStatement, ContinueStatement)):
                is_terminated = True

        return Block(statements=new_statements, token=block.token)

    def optimize_statement(self, stmt: Statement, env: Dict[str, ConstantValue]) -> Optional[Union[Statement, List[Statement]]]:
        if isinstance(stmt, LocalAssign):
            new_values = [fold_expression(v, env) for v in stmt.values]
            for i, target in enumerate(stmt.targets):
                if i < len(new_values):
                    ok, val = ConstantEvaluator.get_value(new_values[i])
                    if ok:
                        env[target.name] = val
                    else:
                        env.pop(target.name, None)
                else:
                    env[target.name] = None
            return LocalAssign(targets=stmt.targets, values=new_values, types=stmt.types, token=stmt.token)

        if isinstance(stmt, Assign):
            new_targets = [fold_expression(t, env) for t in stmt.targets]
            new_values = [fold_expression(v, env) for v in stmt.values]
            for target in new_targets:
                if isinstance(target, Identifier):
                    env.pop(target.name, None)
            return Assign(targets=new_targets, values=new_values, token=stmt.token)

        if isinstance(stmt, CompoundAssign):
            new_target = fold_expression(stmt.target, env)
            new_value = fold_expression(stmt.value, env)
            if isinstance(new_target, Identifier):
                env.pop(new_target.name, None)
            return CompoundAssign(target=new_target, op=stmt.op, value=new_value, token=stmt.token)

        if isinstance(stmt, CallStatement):
            new_call = fold_expression(stmt.call, env)
            return CallStatement(call=new_call, token=stmt.token)

        if isinstance(stmt, IfStatement):
            new_branches: List[Tuple[Expression, Block]] = []
            always_true_branch_body = None

            for cond, body in stmt.branches:
                folded_cond = fold_expression(cond, env)
                ok, val = ConstantEvaluator.get_value(folded_cond)

                if ok:
                    if ConstantEvaluator._is_truthy(val):
                        always_true_branch_body = self.optimize_block(body, env.copy())
                        self.dead_branches_removed += 1
                        break
                    else:
                        self.dead_branches_removed += 1
                        continue
                else:
                    opt_body = self.optimize_block(body, env.copy())
                    new_branches.append((folded_cond, opt_body))

            if always_true_branch_body is not None:
                if not new_branches:
                    return always_true_branch_body.statements

            opt_else = self.optimize_block(stmt.else_body, env.copy()) if stmt.else_body else None

            if not new_branches:
                if opt_else:
                    return opt_else.statements
                return None

            return IfStatement(branches=new_branches, else_body=opt_else, token=stmt.token)

        if isinstance(stmt, WhileStatement):
            folded_cond = fold_expression(stmt.condition, env)
            ok, val = ConstantEvaluator.get_value(folded_cond)
            if ok and not ConstantEvaluator._is_truthy(val):
                self.dead_branches_removed += 1
                return None
            opt_body = self.optimize_block(stmt.body, {})
            return WhileStatement(condition=folded_cond, body=opt_body, token=stmt.token)

        if isinstance(stmt, RepeatStatement):
            opt_body = self.optimize_block(stmt.body, {})
            folded_cond = fold_expression(stmt.condition, env)
            return RepeatStatement(body=opt_body, condition=folded_cond, token=stmt.token)

        if isinstance(stmt, ForNumeric):
            start = fold_expression(stmt.start, env)
            stop = fold_expression(stmt.stop, env)
            step = fold_expression(stmt.step, env) if stmt.step else None
            opt_body = self.optimize_block(stmt.body, {})
            return ForNumeric(var_name=stmt.var_name, start=start, stop=stop, step=step, body=opt_body, token=stmt.token)

        if isinstance(stmt, ForGeneric):
            iters = [fold_expression(it, env) for it in stmt.iterators]
            opt_body = self.optimize_block(stmt.body, {})
            return ForGeneric(var_names=stmt.var_names, iterators=iters, body=opt_body, token=stmt.token)

        if isinstance(stmt, DoBlock):
            opt_body = self.optimize_block(stmt.body, env.copy())
            return DoBlock(body=opt_body, token=stmt.token)

        if isinstance(stmt, ReturnStatement):
            new_vals = [fold_expression(v, env) for v in stmt.values]
            return ReturnStatement(values=new_vals, token=stmt.token)

        if isinstance(stmt, LocalFunctionDef):
            opt_body = self.optimize_block(stmt.body, {})
            return LocalFunctionDef(name=stmt.name, params=stmt.params, is_vararg=stmt.is_vararg, body=opt_body, token=stmt.token)

        if isinstance(stmt, FunctionDef):
            opt_body = self.optimize_block(stmt.body, {})
            return FunctionDef(name=stmt.name, params=stmt.params, is_vararg=stmt.is_vararg, body=opt_body, token=stmt.token)

        return stmt

    def propagate_table_and_aliases(self, program: Program) -> Program:
        """Propagate table lookup values (e.g. O[105] -> bit32.band) and local aliases."""
        local_alias_env: Dict[str, Expression] = {}

        def transform_expr(expr: Expression) -> Expression:
            if expr is None:
                return expr

            # Table indexing: O[105] -> lookup in global table map
            if isinstance(expr, IndexExpr):
                if isinstance(expr.index, NumberLiteral):
                    idx_val = int(expr.index.value) if isinstance(expr.index.value, int) or (isinstance(expr.index.value, float) and expr.index.value.is_integer()) else expr.index.value
                    prop = self.table_map.lookup_global(idx_val)
                    if prop is not None:
                        return copy.deepcopy(prop)
                elif isinstance(expr.index, StringLiteral):
                    prop = self.table_map.lookup_global(expr.index.value)
                    if prop is not None:
                        return copy.deepcopy(prop)

            # Member access: O.u4 -> lookup in global table map
            if isinstance(expr, MemberExpr):
                prop = self.table_map.lookup_global(expr.member)
                if prop is not None:
                    return copy.deepcopy(prop)

            # Local alias identifier lookup (e.g. `p` -> `bit32.band`)
            if isinstance(expr, Identifier):
                if expr.name in local_alias_env:
                    return copy.deepcopy(local_alias_env[expr.name])

            # Recurse on sub-expressions
            if isinstance(expr, BinaryExpr):
                expr.left = transform_expr(expr.left)
                expr.right = transform_expr(expr.right)
            elif isinstance(expr, UnaryExpr):
                expr.operand = transform_expr(expr.operand)
            elif isinstance(expr, CallExpr):
                expr.callee = transform_expr(expr.callee)
                expr.args = [transform_expr(a) for a in expr.args]
            elif isinstance(expr, MethodCallExpr):
                expr.receiver = transform_expr(expr.receiver)
                expr.args = [transform_expr(a) for a in expr.args]
            elif isinstance(expr, ParenthesizedExpr):
                expr.expression = transform_expr(expr.expression)
            elif isinstance(expr, IndexExpr):
                expr.table = transform_expr(expr.table)
                expr.index = transform_expr(expr.index)
            elif isinstance(expr, MemberExpr):
                expr.table = transform_expr(expr.table)

            return expr

        def transform_statement(stmt: Statement):
            if isinstance(stmt, LocalAssign):
                # Detect alias unpacking: local b, A, m = O[48], O[28], O[45]
                for i, target in enumerate(stmt.targets):
                    if i < len(stmt.values):
                        transformed_val = transform_expr(stmt.values[i])
                        stmt.values[i] = transformed_val
                        if isinstance(transformed_val, (MemberExpr, Identifier, StringLiteral, NumberLiteral, BooleanLiteral)):
                            local_alias_env[target.name] = transformed_val
            elif isinstance(stmt, Assign):
                stmt.targets = [transform_expr(t) for t in stmt.targets]
                stmt.values = [transform_expr(v) for v in stmt.values]
            elif isinstance(stmt, CompoundAssign):
                stmt.target = transform_expr(stmt.target)
                stmt.value = transform_expr(stmt.value)
            elif isinstance(stmt, CallStatement):
                stmt.call = transform_expr(stmt.call)
            elif isinstance(stmt, ReturnStatement):
                stmt.values = [transform_expr(v) for v in stmt.values]
            elif isinstance(stmt, IfStatement):
                stmt.branches = [(transform_expr(c), b) for c, b in stmt.branches]
                for _, b in stmt.branches:
                    transform_block(b)
                if stmt.else_body:
                    transform_block(stmt.else_body)
            elif isinstance(stmt, WhileStatement):
                stmt.condition = transform_expr(stmt.condition)
                transform_block(stmt.body)
            elif isinstance(stmt, RepeatStatement):
                transform_block(stmt.body)
                stmt.condition = transform_expr(stmt.condition)
            elif isinstance(stmt, ForNumeric):
                stmt.start = transform_expr(stmt.start)
                stmt.stop = transform_expr(stmt.stop)
                if stmt.step:
                    stmt.step = transform_expr(stmt.step)
                transform_block(stmt.body)
            elif isinstance(stmt, ForGeneric):
                stmt.iterators = [transform_expr(it) for it in stmt.iterators]
                transform_block(stmt.body)
            elif isinstance(stmt, DoBlock):
                transform_block(stmt.body)
            elif isinstance(stmt, (LocalFunctionDef, FunctionDef)):
                transform_block(stmt.body)

        def transform_block(block: Block):
            for s in block.statements:
                transform_statement(s)

        transform_block(program.body)
        return program


def optimize_ast(program: Program) -> Program:
    return ASTOptimizer().optimize(program)
