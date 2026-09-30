from __future__ import annotations

from typing import Dict, Any
from symbolic.values import SymbolicValue


class SymbolicExecutor:
    def __init__(self):
        self.state: Dict[str, SymbolicValue] = {}

    def set_var(self, name: str, val: Any):
        self.state[name] = SymbolicValue(name=name, concrete_val=val)

    def get_var(self, name: str) -> SymbolicValue:
        if name not in self.state:
            self.state[name] = SymbolicValue(name=name)
        return self.state[name]
