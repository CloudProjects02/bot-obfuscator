from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Optional


@dataclass
class SymbolicValue:
    name: str
    inferred_type: str = "any"
    concrete_val: Optional[Any] = None

    def is_concrete(self) -> bool:
        return self.concrete_val is not None
