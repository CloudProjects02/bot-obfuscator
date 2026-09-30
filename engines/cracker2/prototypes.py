from __future__ import annotations

from dataclasses import dataclass, field
from typing import List, Optional, Any
from ast_nodes import Block


@dataclass
class LuaPrototype:
    id: int
    name: str
    num_params: int
    is_vararg: bool
    upvalues: List[str] = field(default_factory=list)
    constants: List[Any] = field(default_factory=list)
    body: Optional[Block] = None
