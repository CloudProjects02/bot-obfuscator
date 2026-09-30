from __future__ import annotations

from ast_nodes import Program
from codegen import generate_lua, LuaCodeGenerator


def emit_lua(program: Program) -> str:
    return generate_lua(program)
