from __future__ import annotations

from typing import List, Optional, Tuple, Dict, Any, Union
from lexer import Token, tokenize, LexerError
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


# Operator Precedences (higher number = tighter binding)
BINARY_PRECEDENCE: Dict[str, Tuple[int, bool]] = {
    # op: (precedence, is_right_associative)
    "or": (1, False),
    "and": (2, False),
    "<": (3, False),
    ">": (3, False),
    "<=": (3, False),
    ">=": (3, False),
    "~=": (3, False),
    "==": (3, False),
    "|": (4, False),
    "~": (5, False),
    "&": (6, False),
    "<<": (7, False),
    ">>": (7, False),
    "..": (8, True),   # Right-associative
    "+": (9, False),
    "-": (9, False),
    "*": (10, False),
    "/": (10, False),
    "//": (10, False),
    "%": (10, False),
    "^": (12, True),   # Right-associative
}

UNARY_PRECEDENCE = 11
UNARY_OPERATORS = {"not", "#", "-", "~"}

COMPOUND_OPS = {
    "+=",
    "-=",
    "*=",
    "/=",
    "//=",
    "%=",
    "^=",
    "..=",
    "&=",
    "|=",
    "<<=",
    ">>=",
}


class ParserError(Exception):
    def __init__(self, message: str, token: Optional[Token] = None):
        if token is not None:
            super().__init__(f"{message} at line {token.line}, column {token.column} (token: '{token.value}')")
        else:
            super().__init__(message)
        self.token = token


class Parser:
    def __init__(self, tokens: List[Token]):
        self.tokens = tokens
        self.index = 0

    def current(self) -> Token:
        if self.index >= len(self.tokens):
            return self.tokens[-1]
        return self.tokens[self.index]

    def peek(self, offset: int = 1) -> Token:
        idx = self.index + offset
        if idx >= len(self.tokens):
            return self.tokens[-1]
        return self.tokens[idx]

    def advance(self) -> Token:
        token = self.current()
        if self.index < len(self.tokens):
            self.index += 1
        return token

    def match(self, kind: str, value: Optional[str] = None) -> bool:
        curr = self.current()
        if curr.kind != kind:
            return False
        if value is not None and curr.value != value:
            return False
        return True

    def consume(self, kind: str, value: Optional[str] = None) -> Token:
        if not self.match(kind, value):
            expected = f"{kind}({value})" if value is not None else kind
            raise ParserError(f"Expected token {expected}, found {self.current().kind}('{self.current().value}')", self.current())
        return self.advance()

    def parse(self) -> Program:
        body = self.parse_block(is_root=True)
        return Program(body=body, token=self.tokens[0] if self.tokens else None)

    # -------------------------------------------------------------------------
    # Statements
    # -------------------------------------------------------------------------

    def parse_block(self, is_root: bool = False, end_keywords: Optional[set] = None) -> Block:
        if end_keywords is None:
            end_keywords = {"end", "else", "elseif", "until"}

        statements: List[Statement] = []
        first_token = self.current()

        while self.current().kind != "EOF":
            # Optional semicolons
            if self.match("OP", ";"):
                self.advance()
                continue

            # Check block termination
            if not is_root and self.current().kind == "KEYWORD" and self.current().value in end_keywords:
                break

            saved_index = self.index
            try:
                stmt = self.parse_statement()
                if stmt is not None:
                    statements.append(stmt)
            except Exception:
                # Recovery: advance one token and attempt generic recovery
                self.index = saved_index
                recovered = self.recover_statement(end_keywords)
                if recovered is not None:
                    statements.append(recovered)

            if self.index == saved_index:
                self.advance()

        return Block(statements=statements, token=first_token)

    def parse_statement(self) -> Optional[Statement]:
        tok = self.current()

        if tok.kind == "OP" and tok.value == ";":
            self.advance()
            return None

        if tok.kind == "KEYWORD":
            if tok.value == "local":
                return self.parse_local()
            if tok.value == "function":
                return self.parse_function_def()
            if tok.value == "if":
                return self.parse_if()
            if tok.value == "while":
                return self.parse_while()
            if tok.value == "repeat":
                return self.parse_repeat()
            if tok.value == "for":
                return self.parse_for()
            if tok.value == "do":
                return self.parse_do()
            if tok.value == "return":
                return self.parse_return()
            if tok.value == "break":
                self.advance()
                return BreakStatement(token=tok)
            if tok.value == "continue":
                self.advance()
                return ContinueStatement(token=tok)

        # Assignment, Compound Assignment, or Function Call Statement
        return self.parse_expr_or_assign_statement()

    def parse_local(self) -> Statement:
        local_tok = self.consume("KEYWORD", "local")

        # Local function: local function name(params) ... end
        if self.match("KEYWORD", "function"):
            self.advance()
            name_tok = self.consume("IDENT")
            params, is_vararg = self.parse_param_list()
            body = self.parse_block(end_keywords={"end"})
            self.consume("KEYWORD", "end")
            return LocalFunctionDef(
                name=name_tok.value,
                params=params,
                is_vararg=is_vararg,
                body=body,
                token=local_tok,
            )

        # Local variables: local a, b: type = 1, 2
        targets: List[Identifier] = []
        types: List[Optional[str]] = []

        while True:
            id_tok = self.consume("IDENT")
            targets.append(Identifier(name=id_tok.value, token=id_tok))

            # Optional Luau type annotation: : type
            type_ann = None
            if self.match("OP", ":"):
                self.advance()
                type_tokens = []
                while self.current().kind in ("IDENT", "KEYWORD", "OP") and self.current().value not in (",", "=", ";", "in", "do"):
                    type_tokens.append(self.advance().value)
                type_ann = " ".join(type_tokens)
            types.append(type_ann)

            if self.match("OP", ","):
                self.advance()
                continue
            break

        values: List[Expression] = []
        if self.match("OP", "="):
            self.advance()
            while True:
                values.append(self.parse_expression())
                if self.match("OP", ","):
                    self.advance()
                    continue
                break

        return LocalAssign(
            targets=targets,
            values=values,
            types=types,
            token=local_tok,
        )

    def parse_function_def(self) -> FunctionDef:
        fn_tok = self.consume("KEYWORD", "function")
        name_expr = self.parse_function_name()
        params, is_vararg = self.parse_param_list()
        body = self.parse_block(end_keywords={"end"})
        self.consume("KEYWORD", "end")
        return FunctionDef(
            name=name_expr,
            params=params,
            is_vararg=is_vararg,
            body=body,
            token=fn_tok,
        )

    def parse_function_name(self) -> Expression:
        first = self.consume("IDENT")
        expr: Expression = Identifier(name=first.value, token=first)

        while self.match("OP", "."):
            self.advance()
            member = self.consume("IDENT")
            expr = MemberExpr(table=expr, member=member.value, token=member)

        if self.match("OP", ":"):
            self.advance()
            method = self.consume("IDENT")
            expr = MemberExpr(table=expr, member=method.value, token=method)

        return expr

    def parse_param_list(self) -> Tuple[List[str], bool]:
        self.consume("OP", "(")
        params: List[str] = []
        is_vararg = False

        if not self.match("OP", ")"):
            while True:
                if self.match("OP", "..."):
                    self.advance()
                    is_vararg = True
                    # Optional Luau type on vararg
                    if self.match("OP", ":"):
                        self.advance()
                        while self.current().kind in ("IDENT", "KEYWORD", "OP") and self.current().value not in (",", ")"):
                            self.advance()
                    break

                param_tok = self.consume("IDENT")
                params.append(param_tok.value)

                # Optional Luau type annotation
                if self.match("OP", ":"):
                    self.advance()
                    while self.current().kind in ("IDENT", "KEYWORD", "OP") and self.current().value not in (",", ")"):
                        self.advance()

                if self.match("OP", ","):
                    self.advance()
                    continue
                break

        self.consume("OP", ")")
        return params, is_vararg

    def parse_if(self) -> IfStatement:
        if_tok = self.consume("KEYWORD", "if")
        branches: List[Tuple[Expression, Block]] = []

        cond = self.parse_expression()
        self.consume("KEYWORD", "then")
        body = self.parse_block(end_keywords={"elseif", "else", "end"})
        branches.append((cond, body))

        while self.match("KEYWORD", "elseif"):
            self.advance()
            elif_cond = self.parse_expression()
            self.consume("KEYWORD", "then")
            elif_body = self.parse_block(end_keywords={"elseif", "else", "end"})
            branches.append((elif_cond, elif_body))

        else_body = None
        if self.match("KEYWORD", "else"):
            self.advance()
            else_body = self.parse_block(end_keywords={"end"})

        self.consume("KEYWORD", "end")
        return IfStatement(branches=branches, else_body=else_body, token=if_tok)

    def parse_while(self) -> WhileStatement:
        while_tok = self.consume("KEYWORD", "while")
        cond = self.parse_expression()
        self.consume("KEYWORD", "do")
        body = self.parse_block(end_keywords={"end"})
        self.consume("KEYWORD", "end")
        return WhileStatement(condition=cond, body=body, token=while_tok)

    def parse_repeat(self) -> RepeatStatement:
        repeat_tok = self.consume("KEYWORD", "repeat")
        body = self.parse_block(end_keywords={"until"})
        self.consume("KEYWORD", "until")
        cond = self.parse_expression()
        return RepeatStatement(body=body, condition=cond, token=repeat_tok)

    def parse_for(self) -> Statement:
        for_tok = self.consume("KEYWORD", "for")
        first_id = self.consume("IDENT")

        # Numeric for: for i = start, stop, step do ... end
        if self.match("OP", "="):
            self.advance()
            start = self.parse_expression()
            self.consume("OP", ",")
            stop = self.parse_expression()
            step = None
            if self.match("OP", ","):
                self.advance()
                step = self.parse_expression()
            self.consume("KEYWORD", "do")
            body = self.parse_block(end_keywords={"end"})
            self.consume("KEYWORD", "end")
            return ForNumeric(
                var_name=first_id.value,
                start=start,
                stop=stop,
                step=step,
                body=body,
                token=for_tok,
            )

        # Generic for: for k, v in iter do ... end
        var_names = [first_id.value]
        while self.match("OP", ","):
            self.advance()
            var_names.append(self.consume("IDENT").value)

        self.consume("KEYWORD", "in")
        iterators: List[Expression] = []
        while True:
            iterators.append(self.parse_expression())
            if self.match("OP", ","):
                self.advance()
                continue
            break

        self.consume("KEYWORD", "do")
        body = self.parse_block(end_keywords={"end"})
        self.consume("KEYWORD", "end")
        return ForGeneric(
            var_names=var_names,
            iterators=iterators,
            body=body,
            token=for_tok,
        )

    def parse_do(self) -> DoBlock:
        do_tok = self.consume("KEYWORD", "do")
        body = self.parse_block(end_keywords={"end"})
        self.consume("KEYWORD", "end")
        return DoBlock(body=body, token=do_tok)

    def parse_return(self) -> ReturnStatement:
        ret_tok = self.consume("KEYWORD", "return")
        values: List[Expression] = []

        if self.current().kind != "EOF" and not (
            self.current().kind == "KEYWORD" and self.current().value in ("end", "else", "elseif", "until")
        ) and not (self.current().kind == "OP" and self.current().value == ";"):
            while True:
                values.append(self.parse_expression())
                if self.match("OP", ","):
                    self.advance()
                    continue
                break

        return ReturnStatement(values=values, token=ret_tok)

    def parse_expr_or_assign_statement(self) -> Statement:
        first_expr = self.parse_primary()

        # Check for compound assignment: a += 1, t[k] *= 2
        if self.current().kind == "OP" and self.current().value in COMPOUND_OPS:
            op_tok = self.advance()
            value = self.parse_expression()
            return CompoundAssign(target=first_expr, op=op_tok.value, value=value, token=op_tok)

        # Check for standard assignment: a, b = 1, 2
        if self.match("OP", ",") or self.match("OP", "="):
            targets = [first_expr]
            while self.match("OP", ","):
                self.advance()
                targets.append(self.parse_primary())

            assign_tok = self.consume("OP", "=")
            values: List[Expression] = []
            while True:
                values.append(self.parse_expression())
                if self.match("OP", ","):
                    self.advance()
                    continue
                break

            return Assign(targets=targets, values=values, token=assign_tok)

        # Call statement: f(x)
        if isinstance(first_expr, (CallExpr, MethodCallExpr)):
            return CallStatement(call=first_expr, token=first_expr.token)

        # Standalone expression statement
        return CallStatement(call=first_expr, token=first_expr.token)

    def recover_statement(self, end_keywords: set) -> Optional[Statement]:
        start = self.current()
        if start.kind == "EOF":
            return None

        tokens: List[Token] = []
        while self.current().kind != "EOF":
            tok = self.current()
            if tok.kind == "OP" and tok.value == ";":
                self.advance()
                break
            if tok.kind == "KEYWORD" and tok.value in end_keywords:
                break
            tokens.append(self.advance())

        if not tokens:
            return None
        return GenericStatement(raw_tokens=tokens, token=start)

    # -------------------------------------------------------------------------
    # Expressions (Pratt Precedence Climbing)
    # -------------------------------------------------------------------------

    def parse_expression(self, min_precedence: int = 0) -> Expression:
        # Check for Luau if-expression: if cond then expr else expr
        if self.match("KEYWORD", "if"):
            return self.parse_if_expression()

        left = self.parse_unary_expression()

        while True:
            tok = self.current()
            if tok.kind != "OP" and not (tok.kind == "KEYWORD" and tok.value in ("and", "or")):
                break

            op = tok.value
            if op not in BINARY_PRECEDENCE:
                break

            prec, is_right_assoc = BINARY_PRECEDENCE[op]
            if prec < min_precedence:
                break

            self.advance()
            next_min_prec = prec if is_right_assoc else prec + 1
            right = self.parse_expression(next_min_prec)

            left = BinaryExpr(op=op, left=left, right=right, token=tok)

        # Handle Luau typecast operator :: type
        if self.match("OP", "::"):
            self.advance()
            # Consume type expression
            while self.current().kind in ("IDENT", "KEYWORD", "OP") and self.current().value not in (",", ")", "}", "]", ";", "then", "do", "else", "elseif", "end", "until"):
                self.advance()

        return left

    def parse_unary_expression(self) -> Expression:
        tok = self.current()

        if (tok.kind == "OP" and tok.value in UNARY_OPERATORS) or (tok.kind == "KEYWORD" and tok.value == "not"):
            op_tok = self.advance()
            operand = self.parse_expression(UNARY_PRECEDENCE)
            return UnaryExpr(op=op_tok.value, operand=operand, token=op_tok)

        return self.parse_primary()

    def parse_primary(self) -> Expression:
        tok = self.current()

        # Numbers
        if tok.kind == "NUMBER":
            self.advance()
            raw = tok.value
            val: Union[int, float] = 0
            try:
                if raw.lower().startswith("0x"):
                    val = int(raw, 16)
                elif raw.lower().startswith("0b"):
                    val = int(raw, 2)
                elif "." in raw or "e" in raw.lower():
                    val = float(raw.replace("_", ""))
                else:
                    val = int(raw.replace("_", ""), 10)
            except ValueError:
                try:
                    val = float(raw.replace("_", ""))
                except ValueError:
                    val = 0
            return NumberLiteral(value=val, raw=raw, token=tok)

        # Strings
        if tok.kind in ("STRING", "INTERPOLATED_STRING"):
            self.advance()
            return StringLiteral(value=tok.value, raw=tok.raw or tok.value, token=tok)

        # Booleans and Nil
        if tok.kind == "KEYWORD":
            if tok.value == "true":
                self.advance()
                return BooleanLiteral(value=True, token=tok)
            if tok.value == "false":
                self.advance()
                return BooleanLiteral(value=False, token=tok)
            if tok.value == "nil":
                self.advance()
                return NilLiteral(token=tok)
            if tok.value == "function":
                return self.parse_function_expression()

        # Vararg
        if tok.kind == "OP" and tok.value == "...":
            self.advance()
            return VarargLiteral(token=tok)

        # Parenthesized expression: (expr)
        if tok.kind == "OP" and tok.value == "(":
            self.advance()
            expr = self.parse_expression()
            self.consume("OP", ")")
            expr = ParenthesizedExpr(expression=expr, token=tok)
            return self.finish_prefix_expression(expr)

        # Table constructor: { ... }
        if tok.kind == "OP" and tok.value == "{":
            table_expr = self.parse_table_constructor()
            return self.finish_prefix_expression(table_expr)

        # Identifier
        if tok.kind == "IDENT":
            self.advance()
            expr = Identifier(name=tok.value, token=tok)
            return self.finish_prefix_expression(expr)

        # Fallback unknown token
        self.advance()
        return Identifier(name=tok.value, token=tok)

    def finish_prefix_expression(self, expr: Expression) -> Expression:
        while True:
            # Table indexing: expr[index]
            if self.match("OP", "["):
                self.advance()
                index = self.parse_expression()
                self.consume("OP", "]")
                expr = IndexExpr(table=expr, index=index, token=expr.token)
                continue

            # Member access: expr.member
            if self.match("OP", "."):
                self.advance()
                member_tok = self.consume("IDENT")
                expr = MemberExpr(table=expr, member=member_tok.value, token=member_tok)
                continue

            # Method call: expr:method(args)
            if self.match("OP", ":"):
                self.advance()
                method_tok = self.consume("IDENT")
                args = self.parse_call_args()
                expr = MethodCallExpr(receiver=expr, method=method_tok.value, args=args, token=method_tok)
                continue

            # Function call: expr(args)
            if self.match("OP", "("):
                args = self.parse_call_args()
                expr = CallExpr(callee=expr, args=args, token=expr.token)
                continue

            # Table call sugar: expr { ... }
            if self.match("OP", "{"):
                table_arg = self.parse_table_constructor()
                expr = CallExpr(callee=expr, args=[table_arg], token=expr.token)
                continue

            # String call sugar: expr "string"
            if self.current().kind in ("STRING", "INTERPOLATED_STRING"):
                str_tok = self.advance()
                str_arg = StringLiteral(value=str_tok.value, raw=str_tok.raw or str_tok.value, token=str_tok)
                expr = CallExpr(callee=expr, args=[str_arg], token=expr.token)
                continue

            break

        return expr

    def parse_call_args(self) -> List[Expression]:
        self.consume("OP", "(")
        args: List[Expression] = []
        if not self.match("OP", ")"):
            while True:
                args.append(self.parse_expression())
                if self.match("OP", ","):
                    self.advance()
                    continue
                break
        self.consume("OP", ")")
        return args

    def parse_table_constructor(self) -> TableConstructor:
        open_tok = self.consume("OP", "{")
        fields: List[TableField] = []

        while not self.match("OP", "}") and self.current().kind != "EOF":
            # Explicit key: [expr] = expr
            if self.match("OP", "["):
                self.advance()
                key_expr = self.parse_expression()
                self.consume("OP", "]")
                self.consume("OP", "=")
                val_expr = self.parse_expression()
                fields.append(TableField(key=key_expr, value=val_expr, is_array_item=False, token=key_expr.token))

            # Named key: ident = expr
            elif self.current().kind == "IDENT" and self.peek().kind == "OP" and self.peek().value == "=":
                key_tok = self.advance()
                self.advance()  # Skip '='
                val_expr = self.parse_expression()
                fields.append(
                    TableField(
                        key=StringLiteral(value=key_tok.value, raw=f'"{key_tok.value}"', token=key_tok),
                        value=val_expr,
                        is_array_item=False,
                        token=key_tok,
                    )
                )

            # Array item: expr
            else:
                val_expr = self.parse_expression()
                fields.append(TableField(key=None, value=val_expr, is_array_item=True, token=val_expr.token))

            # Separator
            if self.match("OP", ",") or self.match("OP", ";"):
                self.advance()
                continue
            break

        self.consume("OP", "}")
        return TableConstructor(fields=fields, token=open_tok)

    def parse_function_expression(self) -> FunctionExpr:
        fn_tok = self.consume("KEYWORD", "function")
        params, is_vararg = self.parse_param_list()
        body = self.parse_block(end_keywords={"end"})
        self.consume("KEYWORD", "end")
        return FunctionExpr(params=params, is_vararg=is_vararg, body=body, token=fn_tok)

    def parse_if_expression(self) -> IfExpr:
        # Luau ternary if-expression: if cond then expr else expr
        if_tok = self.consume("KEYWORD", "if")
        branches: List[Tuple[Expression, Expression]] = []

        cond = self.parse_expression()
        self.consume("KEYWORD", "then")
        then_expr = self.parse_expression()
        branches.append((cond, then_expr))

        while self.match("KEYWORD", "elseif"):
            self.advance()
            elif_cond = self.parse_expression()
            self.consume("KEYWORD", "then")
            elif_expr = self.parse_expression()
            branches.append((elif_cond, elif_expr))

        self.consume("KEYWORD", "else")
        else_expr = self.parse_expression()
        return IfExpr(branches=branches, else_expr=else_expr, token=if_tok)


def parse(tokens: List[Token]) -> Program:
    return Parser(tokens).parse()


# -----------------------------------------------------------------------------
# Backwards-compatible Node dictionary export
# -----------------------------------------------------------------------------

def node_to_dict(node: Any) -> Dict[str, Any]:
    if node is None:
        return {}
    if hasattr(node, "__dict__"):
        res = {"type": type(node).__name__}
        for k, v in node.__dict__.items():
            if k in ("token",):
                continue
            if isinstance(v, list):
                res[k] = [node_to_dict(item) for item in v]
            elif hasattr(v, "__dict__"):
                res[k] = node_to_dict(v)
            else:
                res[k] = v
        return res
    return {"value": str(node)}


def program_to_dict(program: Program) -> Dict[str, Any]:
    return node_to_dict(program)