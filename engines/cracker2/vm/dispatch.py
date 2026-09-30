from __future__ import annotations

from typing import Dict, Callable, Any
from vm.state import VMState


class VMDispatcher:
    def __init__(self):
        self.handlers: Dict[int, Callable[[VMState, Any], None]] = {}

    def register_handler(self, opcode: int, handler: Callable[[VMState, Any], None]):
        self.handlers[opcode] = handler
