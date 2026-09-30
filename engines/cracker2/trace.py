from __future__ import annotations

import time
from dataclasses import dataclass, field
from typing import List, Dict, Any


@dataclass
class StageTiming:
    stage_name: str
    elapsed_ms: float
    details: Dict[str, Any] = field(default_factory=dict)


class PipelineTracer:
    def __init__(self):
        self.timings: List[StageTiming] = []
        self._start_times: Dict[str, float] = {}

    def start_stage(self, name: str):
        self._start_times[name] = time.perf_counter()

    def end_stage(self, name: str, details: Dict[str, Any] | None = None):
        start = self._start_times.pop(name, time.perf_counter())
        elapsed = (time.perf_counter() - start) * 1000.0
        self.timings.append(StageTiming(stage_name=name, elapsed_ms=elapsed, details=details or {}))

    def format_summary(self) -> str:
        lines = ["[Execution Profile]"]
        total = sum(t.elapsed_ms for t in self.timings)
        for t in self.timings:
            pct = (t.elapsed_ms / total * 100) if total > 0 else 0
            lines.append(f" - {t.stage_name:<30}: {t.elapsed_ms:8.2f} ms ({pct:5.1f}%)")
        lines.append(f" Total time: {total:.2f} ms")
        return "\n".join(lines)
