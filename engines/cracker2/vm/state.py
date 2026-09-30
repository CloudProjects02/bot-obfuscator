from __future__ import annotations

from dataclasses import dataclass, field
from typing import List, Dict, Any


@dataclass
class VMState:
    pc: int = 0
    registers: List[Any] = field(default_factory=lambda: [None] * 256)
    stack: List[Any] = field(default_factory=list)
    globals_env: Dict[str, Any] = field(default_factory=dict)
