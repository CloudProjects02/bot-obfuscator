from __future__ import annotations

from dataclasses import dataclass, field
from typing import List, Dict, Set, Optional, Tuple, Any
from ast_nodes import (
    ASTNode,
    Program,
    Block,
    Statement,
    Expression,
    LocalAssign,
    Assign,
    FunctionDef,
    LocalFunctionDef,
    FunctionExpr,
    Identifier,
)


@dataclass
class Scope:
    id: int
    parent: Optional[Scope] = None
    locals: Set[str] = field(default_factory=set)
    upvalues: Set[str] = field(default_factory=set)
    children: List[Scope] = field(default_factory=list)


class ScopeAnalyzer:
    def __init__(self):
        self.scope_counter = 0
        self.root_scope = Scope(id=0)
        self.current_scope = self.root_scope

    def enter_scope(self) -> Scope:
        self.scope_counter += 1
        new_scope = Scope(id=self.scope_counter, parent=self.current_scope)
        self.current_scope.children.append(new_scope)
        self.current_scope = new_scope
        return new_scope

    def exit_scope(self):
        if self.current_scope.parent is not None:
            self.current_scope = self.current_scope.parent

    def declare_local(self, name: str):
        self.current_scope.locals.add(name)

    def reference_variable(self, name: str):
        # Check if variable is in current local scope
        scope = self.current_scope
        if name in scope.locals:
            return

        # Check if variable is declared in an ancestor scope (making it an upvalue)
        ancestor = scope.parent
        is_upvalue = False
        while ancestor is not None:
            if name in ancestor.locals:
                is_upvalue = True
                break
            ancestor = ancestor.parent

        if is_upvalue:
            # Mark upvalue along scope chain
            curr = scope
            while curr != ancestor and curr is not None:
                curr.upvalues.add(name)
                curr = curr.parent

    def analyze(self, program: Program) -> Scope:
        self.walk_ast(program.body)
        return self.root_scope

    def walk_ast(self, node: ASTNode):
        if node is None:
            return

        if isinstance(node, LocalAssign):
            for target in node.targets:
                self.declare_local(target.name)
            for val in node.values:
                self.walk_ast(val)
            return

        if isinstance(node, LocalFunctionDef):
            self.declare_local(node.name)
            self.enter_scope()
            for p in node.params:
                self.declare_local(p)
            self.walk_ast(node.body)
            self.exit_scope()
            return

        if isinstance(node, FunctionDef):
            self.walk_ast(node.name)
            self.enter_scope()
            for p in node.params:
                self.declare_local(p)
            self.walk_ast(node.body)
            self.exit_scope()
            return

        if isinstance(node, FunctionExpr):
            self.enter_scope()
            for p in node.params:
                self.declare_local(p)
            self.walk_ast(node.body)
            self.exit_scope()
            return

        if isinstance(node, Identifier):
            self.reference_variable(node.name)
            return

        # Recurse
        if hasattr(node, "__dict__"):
            for k, v in node.__dict__.items():
                if isinstance(v, list):
                    for item in v:
                        if isinstance(item, ASTNode):
                            self.walk_ast(item)
                elif isinstance(v, ASTNode):
                    self.walk_ast(v)


def analyze_scopes(program: Program) -> Scope:
    return ScopeAnalyzer().analyze(program)
