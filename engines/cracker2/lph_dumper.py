from __future__ import annotations

import json
from pathlib import Path
from lph import LPHDetector, dump_lph_containers


def dump_lph(source: str, output_dir: Path) -> dict:
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    containers = LPHDetector.find_containers(source)
    payload_dir = output_dir / "lph_payloads"
    payload_dir.mkdir(parents=True, exist_ok=True)

    candidate_json = []

    for index, c in enumerate(containers):
        payload_name = f"{index:04d}"
        payload_bin = payload_dir / f"{payload_name}.bin"
        payload_txt = payload_dir / f"{payload_name}.txt"

        payload_bin.write_bytes(c.raw_payload.encode("utf-8", errors="surrogatepass"))
        payload_txt.write_text(c.raw_payload, encoding="utf-8", errors="replace")

        candidate_json.append(
            {
                "index": c.index,
                "name": c.name,
                "position": c.start_pos,
                "line": c.line,
                "column": c.column,
                "size_bytes": c.size_bytes,
                "status": c.status,
                "reasons": c.heuristics,
                "file": f"lph_payloads/{payload_name}.bin",
                "preview": c.raw_payload[:200],
            }
        )

    (output_dir / "lph_candidates.json").write_text(
        json.dumps(
            {
                "count": len(candidate_json),
                "candidates": candidate_json,
            },
            indent=4,
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )

    with (output_dir / "lph_candidates.txt").open("w", encoding="utf-8") as handle:
        for item in candidate_json:
            handle.write(
                f"[{item['name']}] position={item['position']} line={item['line']} size={item['size_bytes']} status={item['status']}\n"
            )
            handle.write(f"Heuristics: {', '.join(item['reasons'])}\n")
            handle.write(item["preview"])
            handle.write("\n\n")

    return {
        "lph_candidates": candidate_json,
        "long_strings": [item for item in candidate_json if item["size_bytes"] >= 256],
    }