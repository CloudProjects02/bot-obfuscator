from __future__ import annotations

import struct
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple, Union
from ast_nodes import (
    Program,
    Block,
    Statement,
    Expression,
    LocalAssign,
    Assign,
    CompoundAssign,
    CallStatement,
    CallExpr,
    MethodCallExpr,
    Identifier,
    StringLiteral,
    NumberLiteral,
    BooleanLiteral,
    NilLiteral,
    BinaryExpr,
    UnaryExpr,
    TableConstructor,
    TableField,
    IndexExpr,
    MemberExpr,
    ReturnStatement,
    FunctionDef,
    LocalFunctionDef,
    FunctionExpr,
    ParenthesizedExpr,
    IfExpr,
    IfStatement,
    WhileStatement,
    RepeatStatement,
    ForNumeric,
    ForGeneric,
    DoBlock,
    BreakStatement,
)


# Standard Lua 5.1 Opcode IDs
OP_MOVE = 0
OP_LOADK = 1
OP_LOADBOOL = 2
OP_LOADNIL = 3
OP_GETUPVAL = 4
OP_GETGLOBAL = 5
OP_GETTABLE = 6
OP_SETGLOBAL = 7
OP_SETUPVAL = 8
OP_SETTABLE = 9
OP_NEWTABLE = 10
OP_SELF = 11
OP_ADD = 12
OP_SUB = 13
OP_MUL = 14
OP_DIV = 15
OP_MOD = 16
OP_POW = 17
OP_UNM = 18
OP_NOT = 19
OP_LEN = 20
OP_CONCAT = 21
OP_JMP = 22
OP_EQ = 23
OP_LT = 24
OP_LE = 25
OP_TEST = 26
OP_TESTSET = 27
OP_CALL = 28
OP_TAILCALL = 29
OP_RETURN = 30
OP_FORLOOP = 31
OP_FORPREP = 32
OP_TFORLOOP = 33
OP_SETLIST = 34
OP_CLOSE = 35
OP_CLOSURE = 36
OP_VARARG = 37


def int2fb(x: int) -> int:
    """Convert integer to Lua 5.1 floating point byte (eeeeexxx)."""
    if x < 0:
        return 0
    if x < 8:
        return x
    e = 0
    while x >= 16:
        x = (x + 1) >> 1
        e += 1
    return ((e + 1) << 3) | (int(x) - 8)


def encode_iABC(op: int, a: int, b: int, c: int) -> int:
    return (op & 0x3F) | ((a & 0xFF) << 6) | ((c & 0x1FF) << 14) | ((b & 0x1FF) << 23)


def encode_iABx(op: int, a: int, bx: int) -> int:
    return (op & 0x3F) | ((a & 0xFF) << 6) | ((bx & 0x3FFFF) << 14)


def encode_iAsBx(op: int, a: int, sbx: int) -> int:
    bx = sbx + 131071
    return (op & 0x3F) | ((a & 0xFF) << 6) | ((bx & 0x3FFFF) << 14)


class LuaProtoBuilder:
    def __init__(self, name: str = "@source.lua", is_vararg: bool = True, num_params: int = 0):
        self.name = name
        self.is_vararg = is_vararg
        self.num_params = num_params
        self.num_upvalues = 0
        self.max_stack_size = max(num_params + 2, 2)
        self.instructions: List[int] = []
        self.constants: List[Any] = []
        self.prototypes: List[LuaProtoBuilder] = []
        self.upvalues: List[str] = []
        self.lineinfo: List[int] = []
        self.reg_top = num_params

    def alloc_reg(self) -> int:
        r = self.reg_top
        self.reg_top += 1
        if self.reg_top > self.max_stack_size:
            self.max_stack_size = self.reg_top
        return r

    def free_reg(self, count: int = 1):
        self.reg_top = max(self.num_params, self.reg_top - count)

    def add_const(self, val: Any) -> int:
        if val in self.constants:
            return self.constants.index(val)
        idx = len(self.constants)
        self.constants.append(val)
        return idx

    def emit(self, inst: int, line: int = 1) -> int:
        idx = len(self.instructions)
        self.instructions.append(inst)
        self.lineinfo.append(line)
        return idx

    def patch_sBx(self, inst_idx: int, sbx: int):
        inst = self.instructions[inst_idx]
        op = inst & 0x3F
        a = (inst >> 6) & 0xFF
        self.instructions[inst_idx] = encode_iAsBx(op, a, sbx)

    def serialize(self) -> bytes:
        buf = bytearray()

        encoded_name = self.name.encode("utf-8") + b"\x00"
        buf.extend(struct.pack("<I", len(encoded_name)))
        buf.extend(encoded_name)

        buf.extend(struct.pack("<II", 0, 0))

        buf.extend(
            struct.pack(
                "<BBBB",
                self.num_upvalues,
                self.num_params,
                2 if self.is_vararg else 0,
                max(self.max_stack_size, 2),
            )
        )

        buf.extend(struct.pack("<I", len(self.instructions)))
        for inst in self.instructions:
            buf.extend(struct.pack("<I", inst))

        buf.extend(struct.pack("<I", len(self.constants)))
        for c in self.constants:
            if c is None:
                buf.append(0)
            elif isinstance(c, bool):
                buf.append(1)
                buf.append(1 if c else 0)
            elif isinstance(c, (int, float)):
                buf.append(3)
                buf.extend(struct.pack("<d", float(c)))
            elif isinstance(c, str):
                buf.append(4)
                enc = c.encode("utf-8") + b"\x00"
                buf.extend(struct.pack("<I", len(enc)))
                buf.extend(enc)
            else:
                buf.append(0)

        buf.extend(struct.pack("<I", len(self.prototypes)))
        for p in self.prototypes:
            buf.extend(p.serialize())

        buf.extend(struct.pack("<I", len(self.lineinfo)))
        for line in self.lineinfo:
            buf.extend(struct.pack("<I", line))

        buf.extend(struct.pack("<I", 0))
        buf.extend(struct.pack("<I", 0))

        return bytes(buf)


class LuaCompiler:
    """Compiles an AST Program into a standard Lua 5.1 Binary Chunk (.luac) for decompilers."""

    def __init__(self):
        self.root_proto = LuaProtoBuilder()

    def compile(self, program: Program, source_name: str = "@source.lua") -> bytes:
        self.root_proto = LuaProtoBuilder(name=source_name, is_vararg=True)
        scope_vars: Dict[str, int] = {}
        self.compile_block(program.body, self.root_proto, scope_vars)

        self.root_proto.emit(encode_iABC(OP_RETURN, 0, 1, 0))

        header = b"\x1bLua\x51\x00\x01\x04\x04\x04\x08\x00"
        return header + self.root_proto.serialize()

    def compile_block(self, block: Block, proto: LuaProtoBuilder, scope_vars: Dict[str, int]):
        for stmt in block.statements:
            self.compile_statement(stmt, proto, scope_vars)

    def compile_condition(self, cond: Expression, proto: LuaProtoBuilder, scope_vars: Dict[str, int]) -> int:
        """Compiles a condition and returns the instruction index of the OP_JMP that jumps on FALSE."""
        if isinstance(cond, BinaryExpr) and cond.op in ("==", "~=", "<", "<=", ">", ">="):
            r_left = proto.alloc_reg()
            self.compile_expr_into_reg(cond.left, r_left, proto, scope_vars)
            r_right = proto.alloc_reg()
            self.compile_expr_into_reg(cond.right, r_right, proto, scope_vars)

            # In Lua 5.1, condition opcodes skip next instruction (the jump) if condition matches A:
            # OP_EQ 1 r_left r_right -> if equal, skip jump; if not equal, execute jump
            if cond.op == "==":
                proto.emit(encode_iABC(OP_EQ, 1, r_left, r_right))
            elif cond.op == "~=":
                proto.emit(encode_iABC(OP_EQ, 0, r_left, r_right))
            elif cond.op == "<":
                proto.emit(encode_iABC(OP_LT, 1, r_left, r_right))
            elif cond.op == "<=":
                proto.emit(encode_iABC(OP_LE, 1, r_left, r_right))
            elif cond.op == ">":
                proto.emit(encode_iABC(OP_LT, 1, r_right, r_left))
            elif cond.op == ">=":
                proto.emit(encode_iABC(OP_LE, 1, r_right, r_left))

            proto.free_reg(2)
            jmp_idx = proto.emit(encode_iAsBx(OP_JMP, 0, 0))
            return jmp_idx

        elif isinstance(cond, UnaryExpr) and cond.op == "not":
            if isinstance(cond.operand, BinaryExpr) and cond.operand.op in ("==", "~=", "<", "<=", ">", ">="):
                r_left = proto.alloc_reg()
                self.compile_expr_into_reg(cond.operand.left, r_left, proto, scope_vars)
                r_right = proto.alloc_reg()
                self.compile_expr_into_reg(cond.operand.right, r_right, proto, scope_vars)

                if cond.operand.op == "==":
                    proto.emit(encode_iABC(OP_EQ, 0, r_left, r_right))
                elif cond.operand.op == "~=":
                    proto.emit(encode_iABC(OP_EQ, 1, r_left, r_right))
                elif cond.operand.op == "<":
                    proto.emit(encode_iABC(OP_LT, 0, r_left, r_right))
                elif cond.operand.op == "<=":
                    proto.emit(encode_iABC(OP_LE, 0, r_left, r_right))
                elif cond.operand.op == ">":
                    proto.emit(encode_iABC(OP_LT, 0, r_right, r_left))
                elif cond.operand.op == ">=":
                    proto.emit(encode_iABC(OP_LE, 0, r_right, r_left))

                proto.free_reg(2)
                jmp_idx = proto.emit(encode_iAsBx(OP_JMP, 0, 0))
                return jmp_idx
            else:
                cond_reg = proto.alloc_reg()
                self.compile_expr_into_reg(cond.operand, cond_reg, proto, scope_vars)
                proto.emit(encode_iABC(OP_TEST, cond_reg, 0, 1))
                proto.free_reg(1)
                jmp_idx = proto.emit(encode_iAsBx(OP_JMP, 0, 0))
                return jmp_idx

        elif isinstance(cond, ParenthesizedExpr):
            return self.compile_condition(cond.expression, proto, scope_vars)

        else:
            cond_reg = proto.alloc_reg()
            self.compile_expr_into_reg(cond, cond_reg, proto, scope_vars)
            proto.emit(encode_iABC(OP_TEST, cond_reg, 0, 0))
            proto.free_reg(1)
            jmp_idx = proto.emit(encode_iAsBx(OP_JMP, 0, 0))
            return jmp_idx

    def compile_statement(self, stmt: Statement, proto: LuaProtoBuilder, scope_vars: Dict[str, int]):
        if isinstance(stmt, LocalAssign):
            for i, target in enumerate(stmt.targets):
                val_expr = stmt.values[i] if i < len(stmt.values) else None
                reg = proto.alloc_reg()
                scope_vars[target.name] = reg
                if val_expr:
                    self.compile_expr_into_reg(val_expr, reg, proto, scope_vars)
                else:
                    proto.emit(encode_iABC(OP_LOADNIL, reg, reg, 0))

        elif isinstance(stmt, Assign):
            for i, target in enumerate(stmt.targets):
                val_expr = stmt.values[i] if i < len(stmt.values) else None
                if isinstance(target, Identifier):
                    if target.name in scope_vars:
                        reg = scope_vars[target.name]
                        if val_expr:
                            self.compile_expr_into_reg(val_expr, reg, proto, scope_vars)
                    else:
                        temp_reg = proto.alloc_reg()
                        if val_expr:
                            self.compile_expr_into_reg(val_expr, temp_reg, proto, scope_vars)
                        k_idx = proto.add_const(target.name)
                        proto.emit(encode_iABx(OP_SETGLOBAL, temp_reg, k_idx))
                        proto.free_reg()
                elif isinstance(target, IndexExpr):
                    t_reg = proto.alloc_reg()
                    self.compile_expr_into_reg(target.table, t_reg, proto, scope_vars)
                    k_reg = proto.alloc_reg()
                    self.compile_expr_into_reg(target.index, k_reg, proto, scope_vars)
                    v_reg = proto.alloc_reg()
                    if val_expr:
                        self.compile_expr_into_reg(val_expr, v_reg, proto, scope_vars)
                    proto.emit(encode_iABC(OP_SETTABLE, t_reg, k_reg, v_reg))
                    proto.free_reg(3)
                elif isinstance(target, MemberExpr):
                    t_reg = proto.alloc_reg()
                    self.compile_expr_into_reg(target.table, t_reg, proto, scope_vars)
                    k_idx = proto.add_const(target.member)
                    v_reg = proto.alloc_reg()
                    if val_expr:
                        self.compile_expr_into_reg(val_expr, v_reg, proto, scope_vars)
                    if k_idx < 256:
                        proto.emit(encode_iABC(OP_SETTABLE, t_reg, k_idx | 0x100, v_reg))
                        proto.free_reg(2)
                    else:
                        k_reg = proto.alloc_reg()
                        proto.emit(encode_iABx(OP_LOADK, k_reg, k_idx))
                        proto.emit(encode_iABC(OP_SETTABLE, t_reg, k_reg, v_reg))
                        proto.free_reg(3)

        elif isinstance(stmt, CompoundAssign):
            binary = BinaryExpr(left=stmt.target, op=stmt.op[:-1], right=stmt.value)
            self.compile_statement(Assign(targets=[stmt.target], values=[binary]), proto, scope_vars)

        elif isinstance(stmt, CallStatement):
            self.compile_call(stmt.call, proto, scope_vars, is_stmt=True)

        elif isinstance(stmt, LocalFunctionDef):
            fn_reg = proto.alloc_reg()
            scope_vars[stmt.name] = fn_reg
            sub_proto = self.compile_function(stmt.params, stmt.is_vararg, stmt.body, stmt.name)
            p_idx = len(proto.prototypes)
            proto.prototypes.append(sub_proto)
            proto.emit(encode_iABx(OP_CLOSURE, fn_reg, p_idx))

        elif isinstance(stmt, FunctionDef):
            sub_proto = self.compile_function(stmt.params, stmt.is_vararg, stmt.body)
            p_idx = len(proto.prototypes)
            proto.prototypes.append(sub_proto)
            fn_reg = proto.alloc_reg()
            proto.emit(encode_iABx(OP_CLOSURE, fn_reg, p_idx))
            if isinstance(stmt.name, Identifier):
                k_idx = proto.add_const(stmt.name.name)
                proto.emit(encode_iABx(OP_SETGLOBAL, fn_reg, k_idx))
            proto.free_reg()

        elif isinstance(stmt, IfStatement):
            jump_to_end_list: List[int] = []

            for cond, body in stmt.branches:
                jmp_to_next = self.compile_condition(cond, proto, scope_vars)

                self.compile_block(body, proto, scope_vars.copy())
                end_jmp = proto.emit(encode_iAsBx(OP_JMP, 0, 0))
                jump_to_end_list.append(end_jmp)

                proto.patch_sBx(jmp_to_next, len(proto.instructions) - jmp_to_next - 1)

            if stmt.else_body:
                self.compile_block(stmt.else_body, proto, scope_vars.copy())

            end_pc = len(proto.instructions)
            for jmp in jump_to_end_list:
                proto.patch_sBx(jmp, end_pc - jmp - 1)

        elif isinstance(stmt, WhileStatement):
            loop_start = len(proto.instructions)
            exit_jmp = self.compile_condition(stmt.condition, proto, scope_vars)

            self.compile_block(stmt.body, proto, scope_vars.copy())
            proto.emit(encode_iAsBx(OP_JMP, 0, loop_start - len(proto.instructions) - 1))
            proto.patch_sBx(exit_jmp, len(proto.instructions) - exit_jmp - 1)

        elif isinstance(stmt, RepeatStatement):
            loop_start = len(proto.instructions)
            self.compile_block(stmt.body, proto, scope_vars.copy())
            exit_jmp = self.compile_condition(stmt.condition, proto, scope_vars)
            proto.patch_sBx(exit_jmp, loop_start - exit_jmp - 1)

        elif isinstance(stmt, ForNumeric):
            base_reg = proto.alloc_reg()
            self.compile_expr_into_reg(stmt.start, base_reg, proto, scope_vars)
            limit_reg = proto.alloc_reg()
            self.compile_expr_into_reg(stmt.stop, limit_reg, proto, scope_vars)
            step_reg = proto.alloc_reg()
            if stmt.step:
                self.compile_expr_into_reg(stmt.step, step_reg, proto, scope_vars)
            else:
                k_one = proto.add_const(1)
                proto.emit(encode_iABx(OP_LOADK, step_reg, k_one))

            prep_idx = proto.emit(encode_iAsBx(OP_FORPREP, base_reg, 0))
            loop_body_vars = scope_vars.copy()
            loop_body_vars[stmt.var_name] = proto.alloc_reg()

            self.compile_block(stmt.body, proto, loop_body_vars)
            proto.free_reg()

            loop_idx = proto.emit(encode_iAsBx(OP_FORLOOP, base_reg, 0))
            proto.patch_sBx(prep_idx, loop_idx - prep_idx - 1)
            proto.patch_sBx(loop_idx, (prep_idx + 1) - loop_idx - 1)
            proto.free_reg(3)

        elif isinstance(stmt, DoBlock):
            self.compile_block(stmt.body, proto, scope_vars.copy())

        elif isinstance(stmt, ReturnStatement):
            if not stmt.values:
                proto.emit(encode_iABC(OP_RETURN, 0, 1, 0))
            else:
                first_reg = proto.reg_top
                for val in stmt.values:
                    r = proto.alloc_reg()
                    self.compile_expr_into_reg(val, r, proto, scope_vars)
                proto.emit(encode_iABC(OP_RETURN, first_reg, len(stmt.values) + 1, 0))
                proto.free_reg(len(stmt.values))

    def compile_function(self, params: List[str], is_vararg: bool, body: Block, name: str = "") -> LuaProtoBuilder:
        sub_proto = LuaProtoBuilder(name=name or "@func", is_vararg=is_vararg, num_params=len(params))
        child_vars: Dict[str, int] = {}
        for idx, p in enumerate(params):
            child_vars[p] = idx

        self.compile_block(body, sub_proto, child_vars)
        sub_proto.emit(encode_iABC(OP_RETURN, 0, 1, 0))
        return sub_proto

    def compile_call(self, call: Union[CallExpr, MethodCallExpr], proto: LuaProtoBuilder, scope_vars: Dict[str, int], is_stmt: bool = False) -> int:
        if isinstance(call, MethodCallExpr):
            rcv_reg = proto.alloc_reg()
            self.compile_expr_into_reg(call.receiver, rcv_reg, proto, scope_vars)
            k_method = proto.add_const(call.method)
            if k_method < 256:
                proto.emit(encode_iABC(OP_SELF, rcv_reg, rcv_reg, k_method | 0x100))
            else:
                m_reg = proto.alloc_reg()
                proto.emit(encode_iABx(OP_LOADK, m_reg, k_method))
                proto.emit(encode_iABC(OP_SELF, rcv_reg, rcv_reg, m_reg))
                proto.free_reg(1)

            for arg in call.args:
                arg_reg = proto.alloc_reg()
                self.compile_expr_into_reg(arg, arg_reg, proto, scope_vars)

            num_args = len(call.args) + 1
            num_results = 0 if is_stmt else 1
            proto.emit(encode_iABC(OP_CALL, rcv_reg, num_args + 1, num_results + 1))
            proto.free_reg(len(call.args) + 1)
            if is_stmt:
                proto.free_reg(1)
            return rcv_reg

        func_reg = proto.alloc_reg()
        self.compile_expr_into_reg(call.callee, func_reg, proto, scope_vars)

        for arg in call.args:
            arg_reg = proto.alloc_reg()
            self.compile_expr_into_reg(arg, arg_reg, proto, scope_vars)

        num_args = len(call.args)
        num_results = 0 if is_stmt else 1
        proto.emit(encode_iABC(OP_CALL, func_reg, num_args + 1, num_results + 1))
        proto.free_reg(num_args)

        if is_stmt:
            proto.free_reg(1)
            return func_reg
        return func_reg

    def compile_expr_into_reg(self, expr: Expression, target_reg: int, proto: LuaProtoBuilder, scope_vars: Dict[str, int]):
        if isinstance(expr, NumberLiteral):
            k_idx = proto.add_const(expr.value)
            proto.emit(encode_iABx(OP_LOADK, target_reg, k_idx))

        elif isinstance(expr, StringLiteral):
            k_idx = proto.add_const(expr.value)
            proto.emit(encode_iABx(OP_LOADK, target_reg, k_idx))

        elif isinstance(expr, BooleanLiteral):
            proto.emit(encode_iABC(OP_LOADBOOL, target_reg, 1 if expr.value else 0, 0))

        elif isinstance(expr, NilLiteral):
            proto.emit(encode_iABC(OP_LOADNIL, target_reg, target_reg, 0))

        elif isinstance(expr, Identifier):
            if expr.name in scope_vars:
                proto.emit(encode_iABC(OP_MOVE, target_reg, scope_vars[expr.name], 0))
            else:
                k_idx = proto.add_const(expr.name)
                proto.emit(encode_iABx(OP_GETGLOBAL, target_reg, k_idx))

        elif isinstance(expr, ParenthesizedExpr):
            self.compile_expr_into_reg(expr.expression, target_reg, proto, scope_vars)

        elif isinstance(expr, FunctionExpr):
            sub_proto = self.compile_function(expr.params, expr.is_vararg, expr.body)
            p_idx = len(proto.prototypes)
            proto.prototypes.append(sub_proto)
            proto.emit(encode_iABx(OP_CLOSURE, target_reg, p_idx))

        elif isinstance(expr, BinaryExpr):
            if expr.op in ("==", "~=", "<", "<=", ">", ">="):
                r_left = proto.alloc_reg()
                self.compile_expr_into_reg(expr.left, r_left, proto, scope_vars)
                r_right = proto.alloc_reg()
                self.compile_expr_into_reg(expr.right, r_right, proto, scope_vars)

                if expr.op == "==":
                    proto.emit(encode_iABC(OP_EQ, 1, r_left, r_right))
                elif expr.op == "~=":
                    proto.emit(encode_iABC(OP_EQ, 0, r_left, r_right))
                elif expr.op == "<":
                    proto.emit(encode_iABC(OP_LT, 1, r_left, r_right))
                elif expr.op == "<=":
                    proto.emit(encode_iABC(OP_LE, 1, r_left, r_right))
                elif expr.op == ">":
                    proto.emit(encode_iABC(OP_LT, 1, r_right, r_left))
                elif expr.op == ">=":
                    proto.emit(encode_iABC(OP_LE, 1, r_right, r_left))

                proto.free_reg(2)
                proto.emit(encode_iAsBx(OP_JMP, 0, 1))
                proto.emit(encode_iABC(OP_LOADBOOL, target_reg, 0, 1))
                proto.emit(encode_iABC(OP_LOADBOOL, target_reg, 1, 0))
            else:
                r_left = proto.alloc_reg()
                self.compile_expr_into_reg(expr.left, r_left, proto, scope_vars)
                r_right = proto.alloc_reg()
                self.compile_expr_into_reg(expr.right, r_right, proto, scope_vars)

                op_map = {
                    "+": OP_ADD,
                    "-": OP_SUB,
                    "*": OP_MUL,
                    "/": OP_DIV,
                    "%": OP_MOD,
                    "^": OP_POW,
                    "..": OP_CONCAT,
                }
                if expr.op in op_map:
                    proto.emit(encode_iABC(op_map[expr.op], target_reg, r_left, r_right))
                else:
                    proto.emit(encode_iABC(OP_ADD, target_reg, r_left, r_right))
                proto.free_reg(2)

        elif isinstance(expr, UnaryExpr):
            r_op = proto.alloc_reg()
            self.compile_expr_into_reg(expr.operand, r_op, proto, scope_vars)
            if expr.op == "-":
                proto.emit(encode_iABC(OP_UNM, target_reg, r_op, 0))
            elif expr.op == "not":
                proto.emit(encode_iABC(OP_NOT, target_reg, r_op, 0))
            elif expr.op == "#":
                proto.emit(encode_iABC(OP_LEN, target_reg, r_op, 0))
            proto.free_reg(1)

        elif isinstance(expr, (CallExpr, MethodCallExpr)):
            res_reg = self.compile_call(expr, proto, scope_vars, is_stmt=False)
            if res_reg != target_reg:
                proto.emit(encode_iABC(OP_MOVE, target_reg, res_reg, 0))
                proto.free_reg(1)

        elif isinstance(expr, TableConstructor):
            array_count = sum(1 for f in expr.fields if f.key is None)
            hash_count = len(expr.fields) - array_count
            proto.emit(encode_iABC(OP_NEWTABLE, target_reg, int2fb(array_count), int2fb(hash_count)))

            for idx, field in enumerate(expr.fields):
                val_reg = proto.alloc_reg()
                self.compile_expr_into_reg(field.value, val_reg, proto, scope_vars)
                if field.key is not None:
                    if isinstance(field.key, StringLiteral):
                        k_idx = proto.add_const(field.key.value)
                        if k_idx < 256:
                            proto.emit(encode_iABC(OP_SETTABLE, target_reg, k_idx | 0x100, val_reg))
                        else:
                            k_reg = proto.alloc_reg()
                            proto.emit(encode_iABx(OP_LOADK, k_reg, k_idx))
                            proto.emit(encode_iABC(OP_SETTABLE, target_reg, k_reg, val_reg))
                            proto.free_reg(1)
                        proto.free_reg(1)
                    elif isinstance(field.key, NumberLiteral):
                        k_idx = proto.add_const(field.key.value)
                        if k_idx < 256:
                            proto.emit(encode_iABC(OP_SETTABLE, target_reg, k_idx | 0x100, val_reg))
                        else:
                            k_reg = proto.alloc_reg()
                            proto.emit(encode_iABx(OP_LOADK, k_reg, k_idx))
                            proto.emit(encode_iABC(OP_SETTABLE, target_reg, k_reg, val_reg))
                            proto.free_reg(1)
                        proto.free_reg(1)
                    else:
                        k_reg = proto.alloc_reg()
                        self.compile_expr_into_reg(field.key, k_reg, proto, scope_vars)
                        proto.emit(encode_iABC(OP_SETTABLE, target_reg, k_reg, val_reg))
                        proto.free_reg(2)
                else:
                    k_idx = proto.add_const(idx + 1)
                    if k_idx < 256:
                        proto.emit(encode_iABC(OP_SETTABLE, target_reg, k_idx | 0x100, val_reg))
                    else:
                        k_reg = proto.alloc_reg()
                        proto.emit(encode_iABx(OP_LOADK, k_reg, k_idx))
                        proto.emit(encode_iABC(OP_SETTABLE, target_reg, k_reg, val_reg))
                        proto.free_reg(1)
                    proto.free_reg(1)

        elif isinstance(expr, IndexExpr):
            t_reg = proto.alloc_reg()
            self.compile_expr_into_reg(expr.table, t_reg, proto, scope_vars)
            k_reg = proto.alloc_reg()
            self.compile_expr_into_reg(expr.index, k_reg, proto, scope_vars)
            proto.emit(encode_iABC(OP_GETTABLE, target_reg, t_reg, k_reg))
            proto.free_reg(2)

        elif isinstance(expr, MemberExpr):
            t_reg = proto.alloc_reg()
            self.compile_expr_into_reg(expr.table, t_reg, proto, scope_vars)
            k_idx = proto.add_const(expr.member)
            if k_idx < 256:
                proto.emit(encode_iABC(OP_GETTABLE, target_reg, t_reg, k_idx | 0x100))
            else:
                k_reg = proto.alloc_reg()
                proto.emit(encode_iABx(OP_LOADK, k_reg, k_idx))
                proto.emit(encode_iABC(OP_GETTABLE, target_reg, t_reg, k_reg))
                proto.free_reg(1)
            proto.free_reg(1)

        elif isinstance(expr, IfExpr):
            cond = expr.branches[0][0]
            then_expr = expr.branches[0][1]
            else_expr = expr.else_expr

            jmp_else = self.compile_condition(cond, proto, scope_vars)
            self.compile_expr_into_reg(then_expr, target_reg, proto, scope_vars)
            jmp_end = proto.emit(encode_iAsBx(OP_JMP, 0, 0))

            proto.patch_sBx(jmp_else, len(proto.instructions) - jmp_else - 1)
            self.compile_expr_into_reg(else_expr, target_reg, proto, scope_vars)
            proto.patch_sBx(jmp_end, len(proto.instructions) - jmp_end - 1)

        else:
            proto.emit(encode_iABC(OP_LOADNIL, target_reg, target_reg, 0))


def compile_program_to_bytecode(program: Program, output_path: str | Path) -> bytes:
    compiler = LuaCompiler()
    bc = compiler.compile(program)
    out = Path(output_path)
    out.write_bytes(bc)
    return bc
