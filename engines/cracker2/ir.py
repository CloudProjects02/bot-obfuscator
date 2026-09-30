from __future__ import annotations

from dataclasses import dataclass, field
from typing import List, Dict, Optional, Any, Union
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


@dataclass
class IRInstruction:
    op: str
    dest: Optional[str] = None
    args: List[Any] = field(default_factory=list)
    label: Optional[str] = None

    def __str__(self) -> str:
        if self.op == "LABEL":
            return f"{self.label}:"
        args_str = ", ".join(str(a) for a in self.args)
        if self.dest:
            return f"  {self.dest} = {self.op} {args_str}".rstrip()
        return f"  {self.op} {args_str}".rstrip()


@dataclass
class IRFunction:
    id: int
    name: str
    params: List[str]
    is_vararg: bool
    instructions: List[IRInstruction] = field(default_factory=list)

    def format(self) -> str:
        lines = [f"function {self.name}({', '.join(self.params)}):"]
        for inst in self.instructions:
            lines.append(str(inst))
        return "\n".join(lines)


class IRBuilder:
    def __init__(self):
        self.temp_counter = 0
        self.label_counter = 0
        self.functions: List[IRFunction] = []
        self.current_function: Optional[IRFunction] = None

    def new_temp(self, prefix: str = "t") -> str:
        self.temp_counter += 1
        return f"{prefix}_{self.temp_counter}"

    def new_label(self, prefix: str = "L") -> str:
        self.label_counter += 1
        return f"{prefix}_{self.label_counter}"

    def emit(self, op: str, dest: Optional[str] = None, args: Optional[List[Any]] = None, label: Optional[str] = None) -> IRInstruction:
        inst = IRInstruction(op=op, dest=dest, args=args or [], label=label)
        if self.current_function is not None:
            self.current_function.instructions.append(inst)
        return inst

    def build(self, program: Program) -> List[IRFunction]:
        root_fn = IRFunction(id=0, name="<main>", params=[], is_vararg=True)
        self.functions.append(root_fn)
        self.current_function = root_fn

        self.lower_block(program.body)
        return self.functions

    def lower_block(self, block: Block):
        for stmt in block.statements:
            self.lower_statement(stmt)

    def lower_statement(self, stmt: Statement):
        if isinstance(stmt, LocalAssign):
            for i, target in enumerate(stmt.targets):
                if i < len(stmt.values):
                    val_temp = self.lower_expression(stmt.values[i])
                    self.emit("MOVE", dest=target.name, args=[val_temp])
                else:
                    self.emit("LOAD_CONST", dest=target.name, args=[None])
            return

        if isinstance(stmt, Assign):
            val_temps = [self.lower_expression(v) for v in stmt.values]
            for i, target in enumerate(stmt.targets):
                val_temp = val_temps[i] if i < len(val_temps) else self.emit("LOAD_CONST", dest=self.new_temp(), args=[None]).dest
                if isinstance(target, Identifier):
                    self.emit("SET_GLOBAL", args=[target.name, val_temp])
                elif isinstance(target, IndexExpr):
                    tbl = self.lower_expression(target.table)
                    idx = self.lower_expression(target.index)
                    self.emit("SET_TABLE", args=[tbl, idx, val_temp])
                elif isinstance(target, MemberExpr):
                    tbl = self.lower_expression(target.table)
                    self.emit("SET_TABLE", args=[tbl, f'"{target.member}"', val_temp])
            return

        if isinstance(stmt, CompoundAssign):
            base_op = stmt.op.rstrip("=")
            val_temp = self.lower_expression(stmt.value)
            if isinstance(stmt.target, Identifier):
                old_val = self.lower_expression(stmt.target)
                res = self.emit("BINOP", dest=stmt.target.name, args=[base_op, old_val, val_temp]).dest
            elif isinstance(stmt.target, IndexExpr):
                tbl = self.lower_expression(stmt.target.table)
                idx = self.lower_expression(stmt.target.index)
                old_val = self.emit("GET_TABLE", dest=self.new_temp(), args=[tbl, idx]).dest
                res = self.emit("BINOP", dest=self.new_temp(), args=[base_op, old_val, val_temp]).dest
                self.emit("SET_TABLE", args=[tbl, idx, res])
            return

        if isinstance(stmt, CallStatement):
            self.lower_expression(stmt.call)
            return

        if isinstance(stmt, IfStatement):
            end_label = self.new_label("endif")
            for cond, body in stmt.branches:
                next_branch = self.new_label("next_branch")
                cond_temp = self.lower_expression(cond)
                self.emit("JUMP_IF_FALSE", args=[cond_temp, next_branch])
                self.lower_block(body)
                self.emit("JUMP", args=[end_label])
                self.emit("LABEL", label=next_branch)

            if stmt.else_body:
                self.lower_block(stmt.else_body)

            self.emit("LABEL", label=end_label)
            return

        if isinstance(stmt, WhileStatement):
            loop_header = self.new_label("while_hdr")
            loop_exit = self.new_label("while_exit")
            self.emit("LABEL", label=loop_header)
            cond_temp = self.lower_expression(stmt.condition)
            self.emit("JUMP_IF_FALSE", args=[cond_temp, loop_exit])
            self.lower_block(stmt.body)
            self.emit("JUMP", args=[loop_header])
            self.emit("LABEL", label=loop_exit)
            return

        if isinstance(stmt, RepeatStatement):
            loop_header = self.new_label("repeat_hdr")
            self.emit("LABEL", label=loop_header)
            self.lower_block(stmt.body)
            cond_temp = self.lower_expression(stmt.condition)
            self.emit("JUMP_IF_FALSE", args=[cond_temp, loop_header])
            return

        if isinstance(stmt, ForNumeric):
            start_temp = self.lower_expression(stmt.start)
            stop_temp = self.lower_expression(stmt.stop)
            step_temp = self.lower_expression(stmt.step) if stmt.step else self.emit("LOAD_CONST", dest=self.new_temp(), args=[1]).dest
            self.emit("MOVE", dest=stmt.var_name, args=[start_temp])

            loop_header = self.new_label("for_hdr")
            loop_exit = self.new_label("for_exit")
            self.emit("LABEL", label=loop_header)
            # check cond
            check_temp = self.emit("BINOP", dest=self.new_temp(), args=["<=", stmt.var_name, stop_temp]).dest
            self.emit("JUMP_IF_FALSE", args=[check_temp, loop_exit])
            self.lower_block(stmt.body)
            # step
            self.emit("BINOP", dest=stmt.var_name, args=["+", stmt.var_name, step_temp])
            self.emit("JUMP", args=[loop_header])
            self.emit("LABEL", label=loop_exit)
            return

        if isinstance(stmt, ForGeneric):
            iter_temps = [self.lower_expression(it) for it in stmt.iterators]
            loop_header = self.new_label("tfor_hdr")
            loop_exit = self.new_label("tfor_exit")
            self.emit("LABEL", label=loop_header)
            # Call iterator
            if iter_temps:
                res = self.emit("CALL", dest=stmt.var_names[0], args=[iter_temps[0]]).dest
                self.emit("JUMP_IF_FALSE", args=[res, loop_exit])
            self.lower_block(stmt.body)
            self.emit("JUMP", args=[loop_header])
            self.emit("LABEL", label=loop_exit)
            return

        if isinstance(stmt, ReturnStatement):
            val_temps = [self.lower_expression(v) for v in stmt.values]
            self.emit("RETURN", args=val_temps)
            return

        if isinstance(stmt, BreakStatement):
            self.emit("BREAK")
            return

        if isinstance(stmt, ContinueStatement):
            self.emit("CONTINUE")
            return

        if isinstance(stmt, LocalFunctionDef):
            fn_id = len(self.functions)
            child_fn = IRFunction(id=fn_id, name=stmt.name, params=stmt.params, is_vararg=stmt.is_vararg)
            self.functions.append(child_fn)
            saved_fn = self.current_function
            self.current_function = child_fn
            self.lower_block(stmt.body)
            self.current_function = saved_fn
            self.emit("CLOSURE", dest=stmt.name, args=[fn_id])
            return

        if isinstance(stmt, FunctionDef):
            fn_id = len(self.functions)
            name_str = stmt.name.name if isinstance(stmt.name, Identifier) else "func"
            child_fn = IRFunction(id=fn_id, name=name_str, params=stmt.params, is_vararg=stmt.is_vararg)
            self.functions.append(child_fn)
            saved_fn = self.current_function
            self.current_function = child_fn
            self.lower_block(stmt.body)
            self.current_function = saved_fn
            fn_temp = self.emit("CLOSURE", dest=self.new_temp(), args=[fn_id]).dest
            if isinstance(stmt.name, Identifier):
                self.emit("SET_GLOBAL", args=[stmt.name.name, fn_temp])
            return

    def lower_expression(self, expr: Expression) -> str:
        if isinstance(expr, NumberLiteral):
            dest = self.new_temp("num")
            self.emit("LOAD_CONST", dest=dest, args=[expr.value])
            return dest

        if isinstance(expr, StringLiteral):
            dest = self.new_temp("str")
            self.emit("LOAD_CONST", dest=dest, args=[f'"{expr.value}"'])
            return dest

        if isinstance(expr, BooleanLiteral):
            dest = self.new_temp("bool")
            self.emit("LOAD_CONST", dest=dest, args=[expr.value])
            return dest

        if isinstance(expr, NilLiteral):
            dest = self.new_temp("nil")
            self.emit("LOAD_CONST", dest=dest, args=[None])
            return dest

        if isinstance(expr, Identifier):
            return expr.name

        if isinstance(expr, BinaryExpr):
            l = self.lower_expression(expr.left)
            r = self.lower_expression(expr.right)
            dest = self.new_temp("bin")
            self.emit("BINOP", dest=dest, args=[expr.op, l, r])
            return dest

        if isinstance(expr, UnaryExpr):
            opnd = self.lower_expression(expr.operand)
            dest = self.new_temp("un")
            self.emit("UNOP", dest=dest, args=[expr.op, opnd])
            return dest

        if isinstance(expr, ParenthesizedExpr):
            return self.lower_expression(expr.expression)

        if isinstance(expr, IndexExpr):
            tbl = self.lower_expression(expr.table)
            idx = self.lower_expression(expr.index)
            dest = self.new_temp("idx")
            self.emit("GET_TABLE", dest=dest, args=[tbl, idx])
            return dest

        if isinstance(expr, MemberExpr):
            tbl = self.lower_expression(expr.table)
            dest = self.new_temp("mem")
            self.emit("GET_TABLE", dest=dest, args=[tbl, f'"{expr.member}"'])
            return dest

        if isinstance(expr, CallExpr):
            callee = self.lower_expression(expr.callee)
            args = [self.lower_expression(a) for a in expr.args]
            dest = self.new_temp("call")
            self.emit("CALL", dest=dest, args=[callee] + args)
            return dest

        if isinstance(expr, MethodCallExpr):
            rcv = self.lower_expression(expr.receiver)
            args = [self.lower_expression(a) for a in expr.args]
            dest = self.new_temp("mcall")
            self.emit("METHOD_CALL", dest=dest, args=[rcv, expr.method] + args)
            return dest

        if isinstance(expr, TableConstructor):
            dest = self.new_temp("tbl")
            self.emit("NEW_TABLE", dest=dest)
            for i, f in enumerate(expr.fields):
                val_temp = self.lower_expression(f.value)
                if f.key:
                    key_temp = self.lower_expression(f.key)
                    self.emit("SET_TABLE", args=[dest, key_temp, val_temp])
                else:
                    self.emit("SET_TABLE", args=[dest, i + 1, val_temp])
            return dest

        if isinstance(expr, FunctionExpr):
            fn_id = len(self.functions)
            child_fn = IRFunction(id=fn_id, name=f"anon_{fn_id}", params=expr.params, is_vararg=expr.is_vararg)
            self.functions.append(child_fn)
            saved_fn = self.current_function
            self.current_function = child_fn
            self.lower_block(expr.body)
            self.current_function = saved_fn
            dest = self.new_temp("fn")
            self.emit("CLOSURE", dest=dest, args=[fn_id])
            return dest

        dest = self.new_temp("val")
        self.emit("LOAD_CONST", dest=dest, args=[None])
        return dest


def build_ir(program: Program) -> List[IRFunction]:
    return IRBuilder().build(program)
