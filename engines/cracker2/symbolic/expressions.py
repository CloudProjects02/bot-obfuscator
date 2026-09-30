from __future__ import annotations

from dataclasses import dataclass
from typing import List, Any
from symbolic.values import SymbolicValue


@dataclass
class SymbolicExpr:
    op: str
    operands: List[Any]
