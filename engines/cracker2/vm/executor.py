from __future__ import annotations

from typing import List, Any
from vm.state import VMState
from vm.dispatch import VMDispatcher


class VMExecutor:
    def __init__(self, dispatcher: VMDispatcher):
        self.dispatcher = dispatcher
        self.state = VMState()
