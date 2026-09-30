from __future__ import annotations

import json
from pathlib import Path
from typing import Any
from ast_nodes import Program
from structure import program_to_dict


def serialize_ast(program: Program, indent: int = 4) -> str:
    """Serialize an AST Program into formatted JSON string."""
    return json.dumps(program_to_dict(program), indent=indent, ensure_ascii=False)


def save_ast(program: Program, path: str | Path, indent: int = 4) -> None:
    """Save an AST Program into a JSON file."""
    file_path = Path(path)
    file_path.write_text(serialize_ast(program, indent), encoding="utf-8")
