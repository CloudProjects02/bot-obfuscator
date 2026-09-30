from __future__ import annotations

from pathlib import Path
from typing import Tuple
from lexer import tokenize, Token
from structure import parse
from ast_nodes import Program


def load_source(path: str | Path) -> Tuple[str, list[Token], Program]:
    """Load, tokenize, and parse a Lua/Luau source file."""
    file_path = Path(path)
    source = file_path.read_text(encoding="utf-8", errors="replace")
    tokens = tokenize(source)
    program = parse(tokens)
    return source, tokens, program
