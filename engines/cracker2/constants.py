from __future__ import annotations

import math
from typing import Optional, Union, List, Dict, Any, Tuple
from ast_nodes import (
    ASTNode,
    Expression,
    NumberLiteral,
    StringLiteral,
    BooleanLiteral,
    NilLiteral,
    BinaryExpr,
    UnaryExpr,
    CallExpr,
    MemberExpr,
    IndexExpr,
    Identifier,
    TableConstructor,
    TableField,
    ParenthesizedExpr,
)


ConstantValue = Union[int, float, str, bool, None]


class ConstantEvaluator:
    @staticmethod
    def is_constant(expr: Expression) -> bool:
        if isinstance(expr, (NumberLiteral, StringLiteral, BooleanLiteral, NilLiteral)):
            return True
        if isinstance(expr, ParenthesizedExpr):
            return ConstantEvaluator.is_constant(expr.expression)
        return False

    @staticmethod
    def get_value(expr: Expression) -> Tuple[bool, ConstantValue]:
        if isinstance(expr, NumberLiteral):
            return True, expr.value
        if isinstance(expr, StringLiteral):
            return True, expr.value
        if isinstance(expr, BooleanLiteral):
            return True, expr.value
        if isinstance(expr, NilLiteral):
            return True, None
        if isinstance(expr, ParenthesizedExpr):
            return ConstantEvaluator.get_value(expr.expression)
        return False, None

    @staticmethod
    def value_to_literal(val: ConstantValue, token: Optional[Any] = None) -> Expression:
        if isinstance(val, bool):
            return BooleanLiteral(value=val, token=token)
        if isinstance(val, (int, float)):
            return NumberLiteral(value=val, raw=str(val), token=token)
        if isinstance(val, str):
            escaped = val.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")
            return StringLiteral(value=val, raw=f'"{escaped}"', token=token)
        return NilLiteral(token=token)

    @classmethod
    def eval_expr(cls, expr: Expression, env: Optional[Dict[str, ConstantValue]] = None) -> Tuple[bool, ConstantValue]:
        if env is None:
            env = {}

        if isinstance(expr, NumberLiteral):
            return True, expr.value
        if isinstance(expr, StringLiteral):
            return True, expr.value
        if isinstance(expr, BooleanLiteral):
            return True, expr.value
        if isinstance(expr, NilLiteral):
            return True, None

        if isinstance(expr, Identifier):
            if expr.name in env:
                return True, env[expr.name]
            return False, None

        if isinstance(expr, ParenthesizedExpr):
            return cls.eval_expr(expr.expression, env)

        if isinstance(expr, UnaryExpr):
            ok, val = cls.eval_expr(expr.operand, env)
            if not ok:
                return False, None
            return cls.eval_unary(expr.op, val)

        if isinstance(expr, BinaryExpr):
            ok_l, val_l = cls.eval_expr(expr.left, env)
            ok_r, val_r = cls.eval_expr(expr.right, env)

            # Short-circuit logical operators
            if expr.op == "and":
                if ok_l and not cls._is_truthy(val_l):
                    return True, val_l
                if ok_l and ok_r:
                    return True, val_r if cls._is_truthy(val_l) else val_l
            elif expr.op == "or":
                if ok_l and cls._is_truthy(val_l):
                    return True, val_l
                if ok_l and ok_r:
                    return True, val_l if cls._is_truthy(val_l) else val_r

            if not ok_l or not ok_r:
                return False, None

            return cls.eval_binary(expr.op, val_l, val_r)

        if isinstance(expr, CallExpr):
            return cls.eval_call(expr, env)

        return False, None

    @classmethod
    def _is_truthy(cls, val: ConstantValue) -> bool:
        if val is None or val is False:
            return False
        return True

    @classmethod
    def eval_unary(cls, op: str, val: ConstantValue) -> Tuple[bool, ConstantValue]:
        try:
            if op == "not":
                return True, not cls._is_truthy(val)
            if op == "-":
                if isinstance(val, (int, float)):
                    return True, -val
            if op == "#":
                if isinstance(val, str):
                    return True, len(val)
            if op == "~":
                if isinstance(val, int):
                    return True, (~val) & 0xFFFFFFFF
                if isinstance(val, float) and val.is_integer():
                    return True, (~int(val)) & 0xFFFFFFFF
        except Exception:
            pass
        return False, None

    @classmethod
    def eval_binary(cls, op: str, left: ConstantValue, right: ConstantValue) -> Tuple[bool, ConstantValue]:
        try:
            # String concatenation
            if op == "..":
                l_str = str(left) if isinstance(left, (str, int, float)) else None
                r_str = str(right) if isinstance(right, (str, int, float)) else None
                if l_str is not None and r_str is not None:
                    return True, l_str + r_str
                return False, None

            # Numeric arithmetic
            if isinstance(left, (int, float)) and isinstance(right, (int, float)):
                if op == "+":
                    res = left + right
                    return True, int(res) if isinstance(res, float) and res.is_integer() else res
                if op == "-":
                    res = left - right
                    return True, int(res) if isinstance(res, float) and res.is_integer() else res
                if op == "*":
                    res = left * right
                    return True, int(res) if isinstance(res, float) and res.is_integer() else res
                if op == "/":
                    if right == 0:
                        return False, None
                    res = left / right
                    return True, int(res) if res.is_integer() else res
                if op == "//":
                    if right == 0:
                        return False, None
                    return True, int(left // right)
                if op == "%":
                    if right == 0:
                        return False, None
                    res = left % right
                    return True, int(res) if isinstance(res, float) and res.is_integer() else res
                if op == "^":
                    res = left ** right
                    return True, int(res) if isinstance(res, float) and res.is_integer() else res

                # Bitwise operators (Lua 5.3+ / Luau)
                l_int = int(left) if isinstance(left, int) or (isinstance(left, float) and left.is_integer()) else None
                r_int = int(right) if isinstance(right, int) or (isinstance(right, float) and right.is_integer()) else None
                if l_int is not None and r_int is not None:
                    if op == "&":
                        return True, (l_int & r_int) & 0xFFFFFFFF
                    if op == "|":
                        return True, (l_int | r_int) & 0xFFFFFFFF
                    if op == "~":
                        return True, (l_int ^ r_int) & 0xFFFFFFFF
                    if op == "<<":
                        return True, (l_int << (r_int & 31)) & 0xFFFFFFFF
                    if op == ">>":
                        return True, (l_int >> (r_int & 31)) & 0xFFFFFFFF

                # Relational
                if op == "==":
                    return True, left == right
                if op == "~=":
                    return True, left != right
                if op == "<":
                    return True, left < right
                if op == "<=":
                    return True, left <= right
                if op == ">":
                    return True, left > right
                if op == ">=":
                    return True, left >= right

            # String equality / comparison
            if isinstance(left, str) and isinstance(right, str):
                if op == "==":
                    return True, left == right
                if op == "~=":
                    return True, left != right
                if op == "<":
                    return True, left < right
                if op == "<=":
                    return True, left <= right
                if op == ">":
                    return True, left > right
                if op == ">=":
                    return True, left >= right

            # General equality
            if op == "==":
                return True, left == right
            if op == "~=":
                return True, left != right

        except Exception:
            pass

        return False, None

    @classmethod
    def eval_call(cls, call: CallExpr, env: Optional[Dict[str, ConstantValue]] = None) -> Tuple[bool, ConstantValue]:
        callee_name = None
        if isinstance(call.callee, Identifier):
            callee_name = call.callee.name
        elif isinstance(call.callee, MemberExpr) and isinstance(call.callee.table, Identifier):
            callee_name = f"{call.callee.table.name}.{call.callee.member}"

        if not callee_name:
            return False, None

        # Evaluate arguments
        eval_args: List[ConstantValue] = []
        for arg in call.args:
            ok, val = cls.eval_expr(arg, env)
            if not ok:
                return False, None
            eval_args.append(val)

        try:
            # string.char(...)
            if callee_name == "string.char":
                chars = []
                for a in eval_args:
                    if isinstance(a, (int, float)):
                        chars.append(chr(int(a) & 0xFF))
                    else:
                        return False, None
                return True, "".join(chars)

            # string.byte(s, [i], [j])
            if callee_name == "string.byte" and eval_args and isinstance(eval_args[0], str):
                s = eval_args[0]
                idx = int(eval_args[1]) if len(eval_args) > 1 and isinstance(eval_args[1], (int, float)) else 1
                if 1 <= idx <= len(s):
                    return True, ord(s[idx - 1])
                return False, None

            # string.sub(s, i, [j])
            if callee_name == "string.sub" and len(eval_args) >= 2 and isinstance(eval_args[0], str):
                s = eval_args[0]
                start = int(eval_args[1])
                end = int(eval_args[2]) if len(eval_args) > 2 and isinstance(eval_args[2], (int, float)) else len(s)
                # Lua 1-based indexing with negative offsets
                if start < 0:
                    start = max(1, len(s) + start + 1)
                if end < 0:
                    end = len(s) + end + 1
                start = max(1, start)
                return True, s[start - 1 : end]

            # string.len(s)
            if callee_name == "string.len" and eval_args and isinstance(eval_args[0], str):
                return True, len(eval_args[0])

            # tonumber(s)
            if callee_name == "tonumber" and eval_args and isinstance(eval_args[0], (str, int, float)):
                try:
                    num = float(eval_args[0])
                    return True, int(num) if num.is_integer() else num
                except ValueError:
                    return False, None

            # tostring(v)
            if callee_name == "tostring" and eval_args:
                return True, str(eval_args[0])

            # bit32 functions
            if callee_name.startswith("bit32."):
                fn = callee_name[6:]
                int_args = [int(a) for a in eval_args if isinstance(a, (int, float))]
                if len(int_args) == len(eval_args):
                    if fn == "band":
                        res = 0xFFFFFFFF
                        for a in int_args:
                            res &= a
                        return True, res & 0xFFFFFFFF
                    if fn == "bor":
                        res = 0
                        for a in int_args:
                            res |= a
                        return True, res & 0xFFFFFFFF
                    if fn == "bxor":
                        res = 0
                        for a in int_args:
                            res ^= a
                        return True, res & 0xFFFFFFFF
                    if fn == "bnot" and len(int_args) == 1:
                        return True, (~int_args[0]) & 0xFFFFFFFF
                    if fn == "lshift" and len(int_args) >= 2:
                        return True, (int_args[0] << (int_args[1] & 31)) & 0xFFFFFFFF
                    if fn == "rshift" and len(int_args) >= 2:
                        return True, (int_args[0] >> (int_args[1] & 31)) & 0xFFFFFFFF
                    if fn == "arshift" and len(int_args) >= 2:
                        val = int_args[0]
                        shift = int_args[1] & 31
                        # signed 32-bit arithmetic shift
                        if val & 0x80000000:
                            val -= 0x100000000
                        return True, (val >> shift) & 0xFFFFFFFF

            # math functions
            if callee_name == "math.floor" and eval_args and isinstance(eval_args[0], (int, float)):
                return True, math.floor(eval_args[0])
            if callee_name == "math.ceil" and eval_args and isinstance(eval_args[0], (int, float)):
                return True, math.ceil(eval_args[0])
            if callee_name == "math.abs" and eval_args and isinstance(eval_args[0], (int, float)):
                return True, abs(eval_args[0])
            if callee_name == "math.min" and eval_args and all(isinstance(a, (int, float)) for a in eval_args):
                return True, min(eval_args)  # type: ignore
            if callee_name == "math.max" and eval_args and all(isinstance(a, (int, float)) for a in eval_args):
                return True, max(eval_args)  # type: ignore

        except Exception:
            pass

        return False, None


def fold_expression(expr: Expression, env: Optional[Dict[str, ConstantValue]] = None) -> Expression:
    """Recursively fold constant subexpressions within an expression."""
    if env is None:
        env = {}

    ok, val = ConstantEvaluator.eval_expr(expr, env)
    if ok:
        return ConstantEvaluator.value_to_literal(val, token=expr.token)

    if isinstance(expr, BinaryExpr):
        folded_left = fold_expression(expr.left, env)
        folded_right = fold_expression(expr.right, env)
        new_expr = BinaryExpr(op=expr.op, left=folded_left, right=folded_right, token=expr.token)
        ok2, val2 = ConstantEvaluator.eval_expr(new_expr, env)
        if ok2:
            return ConstantEvaluator.value_to_literal(val2, token=expr.token)
        return new_expr

    if isinstance(expr, UnaryExpr):
        folded_op = fold_expression(expr.operand, env)
        new_expr = UnaryExpr(op=expr.op, operand=folded_op, token=expr.token)
        ok2, val2 = ConstantEvaluator.eval_expr(new_expr, env)
        if ok2:
            return ConstantEvaluator.value_to_literal(val2, token=expr.token)
        return new_expr

    if isinstance(expr, ParenthesizedExpr):
        folded_inner = fold_expression(expr.expression, env)
        if ConstantEvaluator.is_constant(folded_inner):
            return folded_inner
        return ParenthesizedExpr(expression=folded_inner, token=expr.token)

    if isinstance(expr, TableConstructor):
        folded_fields = []
        for f in expr.fields:
            k = fold_expression(f.key, env) if f.key else None
            v = fold_expression(f.value, env)
            folded_fields.append(TableField(key=k, value=v, is_array_item=f.is_array_item, token=f.token))
        return TableConstructor(fields=folded_fields, token=expr.token)

    if isinstance(expr, CallExpr):
        folded_callee = fold_expression(expr.callee, env)
        folded_args = [fold_expression(a, env) for a in expr.args]
        new_call = CallExpr(callee=folded_callee, args=folded_args, token=expr.token)
        ok2, val2 = ConstantEvaluator.eval_call(new_call, env)
        if ok2:
            return ConstantEvaluator.value_to_literal(val2, token=expr.token)
        return new_call

    return expr
