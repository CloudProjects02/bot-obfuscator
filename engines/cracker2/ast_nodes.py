from __future__ import annotations

from dataclasses import dataclass, field
from typing import List, Optional, Tuple, Any, Union
from lexer import Token


@dataclass
class ASTNode:
    token: Optional[Token] = None
    line: int = 1
    column: int = 1

    def __post_init__(self):
        if self.token is not None:
            self.line = self.token.line
            self.column = self.token.column


# -----------------------------------------------------------------------------
# Expressions
# -----------------------------------------------------------------------------

@dataclass
class Expression(ASTNode):
    pass


@dataclass
class NumberLiteral(Expression):
    value: Union[int, float] = 0
    raw: str = ""


@dataclass
class StringLiteral(Expression):
    value: str = ""
    raw: str = ""


@dataclass
class BooleanLiteral(Expression):
    value: bool = False


@dataclass
class NilLiteral(Expression):
    pass


@dataclass
class VarargLiteral(Expression):
    pass


@dataclass
class Identifier(Expression):
    name: str = ""


@dataclass
class BinaryExpr(Expression):
    op: str = ""
    left: Expression = field(default_factory=NilLiteral)
    right: Expression = field(default_factory=NilLiteral)


@dataclass
class UnaryExpr(Expression):
    op: str = ""
    operand: Expression = field(default_factory=NilLiteral)


@dataclass
class TableField(ASTNode):
    key: Optional[Expression] = None
    value: Expression = field(default_factory=NilLiteral)
    is_array_item: bool = True


@dataclass
class TableConstructor(Expression):
    fields: List[TableField] = field(default_factory=list)


@dataclass
class IndexExpr(Expression):
    table: Expression = field(default_factory=NilLiteral)
    index: Expression = field(default_factory=NilLiteral)


@dataclass
class MemberExpr(Expression):
    table: Expression = field(default_factory=NilLiteral)
    member: str = ""


@dataclass
class CallExpr(Expression):
    callee: Expression = field(default_factory=NilLiteral)
    args: List[Expression] = field(default_factory=list)


@dataclass
class MethodCallExpr(Expression):
    receiver: Expression = field(default_factory=NilLiteral)
    method: str = ""
    args: List[Expression] = field(default_factory=list)


@dataclass
class FunctionExpr(Expression):
    params: List[str] = field(default_factory=list)
    is_vararg: bool = False
    body: Block = field(default_factory=lambda: Block())


@dataclass
class ParenthesizedExpr(Expression):
    expression: Expression = field(default_factory=NilLiteral)


@dataclass
class IfExpr(Expression):
    branches: List[Tuple[Expression, Expression]] = field(default_factory=list)
    else_expr: Expression = field(default_factory=NilLiteral)


# -----------------------------------------------------------------------------
# Statements
# -----------------------------------------------------------------------------

@dataclass
class Statement(ASTNode):
    pass


@dataclass
class Block(ASTNode):
    statements: List[Statement] = field(default_factory=list)


@dataclass
class Program(ASTNode):
    body: Block = field(default_factory=Block)


@dataclass
class LocalAssign(Statement):
    targets: List[Identifier] = field(default_factory=list)
    values: List[Expression] = field(default_factory=list)
    types: Optional[List[Optional[str]]] = None


@dataclass
class Assign(Statement):
    targets: List[Expression] = field(default_factory=list)
    values: List[Expression] = field(default_factory=list)


@dataclass
class CompoundAssign(Statement):
    target: Expression = field(default_factory=NilLiteral)
    op: str = ""
    value: Expression = field(default_factory=NilLiteral)


@dataclass
class FunctionDef(Statement):
    name: Expression = field(default_factory=NilLiteral)
    params: List[str] = field(default_factory=list)
    is_vararg: bool = False
    body: Block = field(default_factory=Block)


@dataclass
class LocalFunctionDef(Statement):
    name: str = ""
    params: List[str] = field(default_factory=list)
    is_vararg: bool = False
    body: Block = field(default_factory=Block)


@dataclass
class IfStatement(Statement):
    branches: List[Tuple[Expression, Block]] = field(default_factory=list)
    else_body: Optional[Block] = None


@dataclass
class WhileStatement(Statement):
    condition: Expression = field(default_factory=NilLiteral)
    body: Block = field(default_factory=Block)


@dataclass
class RepeatStatement(Statement):
    body: Block = field(default_factory=Block)
    condition: Expression = field(default_factory=NilLiteral)


@dataclass
class ForNumeric(Statement):
    var_name: str = ""
    start: Expression = field(default_factory=NilLiteral)
    stop: Expression = field(default_factory=NilLiteral)
    step: Optional[Expression] = None
    body: Block = field(default_factory=Block)


@dataclass
class ForGeneric(Statement):
    var_names: List[str] = field(default_factory=list)
    iterators: List[Expression] = field(default_factory=list)
    body: Block = field(default_factory=Block)


@dataclass
class DoBlock(Statement):
    body: Block = field(default_factory=Block)


@dataclass
class ReturnStatement(Statement):
    values: List[Expression] = field(default_factory=list)


@dataclass
class BreakStatement(Statement):
    pass


@dataclass
class ContinueStatement(Statement):
    pass


@dataclass
class CallStatement(Statement):
    call: Expression = field(default_factory=NilLiteral)


@dataclass
class GenericStatement(Statement):
    raw_tokens: List[Token] = field(default_factory=list)
