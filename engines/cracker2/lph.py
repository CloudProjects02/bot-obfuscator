from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple


@dataclass
class LPHContainer:
    index: int
    name: str
    start_pos: int
    end_pos: int
    line: int
    column: int
    raw_payload: str
    size_bytes: int
    status: str  # 'DECODED', 'PARTIALLY_RECOVERABLE', 'NOT_STATICALLY_RECOVERABLE'
    heuristics: List[str]
    extracted_strings: List[str] = field(default_factory=list)
    extracted_constants: List[Any] = field(default_factory=list)
    details: Dict[str, Any] = field(default_factory=dict)


class LPHDetector:
    @classmethod
    def find_containers(cls, source: str) -> List[LPHContainer]:
        containers: List[LPHContainer] = []
        container_counter = 1

        # Scan for explicit LPH markers
        for match in re.finditer(r'(["\'])(LPH[\$:][^"\']+)\1', source):
            payload = match.group(2)
            start = match.start(2)
            end = match.end(2)

            line = source.count("\n", 0, start) + 1
            col = start - source.rfind("\n", 0, start)

            heuristics = ["Explicit LPH string marker"]
            status = "NOT_STATICALLY_RECOVERABLE (Encrypted/Virtualized Chunk)"
            extracted_strings: List[str] = []

            if len(payload) > 1024:
                heuristics.append(f"High-density bytecode buffer ({len(payload)} bytes)")
                status = "NOT_STATICALLY_RECOVERABLE (Virtualized Luraph Bytecode)"
            else:
                status = "DECODED_METADATA_HEADER"

            container = LPHContainer(
                index=container_counter,
                name=f"LPH container #{container_counter}",
                start_pos=start,
                end_pos=end,
                line=line,
                column=col,
                raw_payload=payload,
                size_bytes=len(payload),
                status=status,
                heuristics=heuristics,
                extracted_strings=extracted_strings,
                details={
                    "marker": "LPH$",
                    "is_virtualized_bytecode": len(payload) > 1024,
                },
            )
            containers.append(container)
            container_counter += 1

        # Also detect large long-string containers (e.g. [[...]])
        for match in re.finditer(r'\[(=*)\[(.*?)\]\1\]', source, re.DOTALL):
            payload = match.group(2)
            if len(payload) > 5000:
                start = match.start(2)
                end = match.end(2)
                line = source.count("\n", 0, start) + 1
                col = start - source.rfind("\n", 0, start)

                heuristics = [f"Large long-string payload container ({len(payload)} bytes)"]
                if "LPH" in payload:
                    heuristics.append("Contains internal LPH signature")

                container = LPHContainer(
                    index=container_counter,
                    name=f"LPH container #{container_counter}",
                    start_pos=start,
                    end_pos=end,
                    line=line,
                    column=col,
                    raw_payload=payload,
                    size_bytes=len(payload),
                    status="NOT_STATICALLY_RECOVERABLE (Encrypted/Virtualized Chunk)",
                    heuristics=heuristics,
                    extracted_strings=[],
                    details={"is_long_string": True, "size": len(payload)},
                )
                containers.append(container)
                container_counter += 1

        return containers


def dump_lph_containers(source: str, output_dir: str | Path) -> List[LPHContainer]:
    out_path = Path(output_dir)
    out_path.mkdir(parents=True, exist_ok=True)

    containers = LPHDetector.find_containers(source)
    summary_data = []

    for c in containers:
        c_dir = out_path / f"container_{c.index:04d}"
        c_dir.mkdir(parents=True, exist_ok=True)

        (c_dir / f"{c.index - 1:04d}.bin").write_bytes(c.raw_payload.encode("latin1", errors="replace"))
        (c_dir / f"{c.index - 1:04d}.txt").write_text(c.raw_payload, encoding="utf-8", errors="replace")

        info = {
            "index": c.index,
            "name": c.name,
            "size_bytes": c.size_bytes,
            "line": c.line,
            "column": c.column,
            "status": c.status,
            "heuristics": c.heuristics,
        }
        (c_dir / "info.json").write_text(json.dumps(info, indent=4), encoding="utf-8")
        summary_data.append(info)

    (out_path / "lph_summary.json").write_text(json.dumps(summary_data, indent=4), encoding="utf-8")
    return containers
