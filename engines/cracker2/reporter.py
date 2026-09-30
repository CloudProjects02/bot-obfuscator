from __future__ import annotations

import json
from dataclasses import asdict
from pathlib import Path
from typing import Dict, Any, List, Optional
from strings import StringRecoveryResult
from anti_analysis import AntiAnalysisReport
from vm_detector import VMAnalysisReport
from lph import LPHContainer


class AnalysisReporter:
    def __init__(
        self,
        input_path: Path,
        source_size: int,
        token_count: int,
        statement_count: int,
        string_result: StringRecoveryResult,
        anti_report: AntiAnalysisReport,
        vm_report: VMAnalysisReport,
        containers: List[LPHContainer],
        devirtualization_status: str,
        unresolved_items: Optional[List[str]] = None,
    ):
        self.input_path = input_path
        self.source_size = source_size
        self.token_count = token_count
        self.statement_count = statement_count
        self.string_result = string_result
        self.anti_report = anti_report
        self.vm_report = vm_report
        self.containers = containers
        self.devirtualization_status = devirtualization_status
        self.unresolved_items = unresolved_items or []

    def format_text_report(self) -> str:
        lines = [
            "================================================================================",
            "                          CRACKER2 ANALYSIS REPORT                              ",
            "================================================================================",
            f"Input file: {self.input_path}",
            f"Source size: {self.source_size} bytes",
            f"Tokens: {self.token_count}",
            f"Top-level statements: {self.statement_count}",
            "",
            "--------------------------------------------------------------------------------",
            " [Deobfuscation Summary]",
            "--------------------------------------------------------------------------------",
            f"Total strings recovered: {len(self.string_result.all_strings)}",
            f"Meaningful / user strings: {len(self.string_result.meaningful_strings)}",
            f"Technical / internal strings: {len(self.string_result.technical_strings)}",
            f"LPH containers detected: {len(self.containers)}",
            f"VM dispatcher: {'detected' if self.vm_report.vm_detected else 'not detected'}",
            f"VM devirtualization: {self.devirtualization_status}",
            "",
        ]

        if self.containers:
            lines.extend([
                "--------------------------------------------------------------------------------",
                " [LPH Containers]",
                "--------------------------------------------------------------------------------",
            ])
            for c in self.containers:
                lines.append(f"{c.name} (line {c.line}, {c.size_bytes} bytes):")
                lines.append(f"  Status: {c.status}")
                lines.append(f"  Heuristics: {', '.join(c.heuristics)}")
                if c.extracted_strings:
                    lines.append(f"  Sample strings: {', '.join(c.extracted_strings[:8])}")
                lines.append("")

        lines.extend([
            "--------------------------------------------------------------------------------",
            f" {self.anti_report.format()}",
            "--------------------------------------------------------------------------------",
            "",
            "--------------------------------------------------------------------------------",
            f" {self.vm_report.format()}",
            "--------------------------------------------------------------------------------",
            "",
        ])

        if self.unresolved_items:
            lines.extend([
                "--------------------------------------------------------------------------------",
                " [Unresolved Constructs & Limitations]",
                "--------------------------------------------------------------------------------",
            ])
            for item in self.unresolved_items:
                lines.append(f" - {item}")
            lines.append("")

        return "\n".join(lines)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "input": str(self.input_path),
            "source_size": self.source_size,
            "token_count": self.token_count,
            "statement_count": self.statement_count,
            "strings": {
                "total_count": len(self.string_result.all_strings),
                "meaningful_count": len(self.string_result.meaningful_strings),
                "technical_count": len(self.string_result.technical_strings),
                "meaningful_strings": self.string_result.meaningful_strings,
                "all_strings": self.string_result.all_strings,
            },
            "anti_analysis": asdict(self.anti_report),
            "vm_analysis": asdict(self.vm_report),
            "containers": [
                {
                    "name": c.name,
                    "line": c.line,
                    "size_bytes": c.size_bytes,
                    "status": c.status,
                    "heuristics": c.heuristics,
                }
                for c in self.containers
            ],
            "devirtualization_status": self.devirtualization_status,
            "unresolved_items": self.unresolved_items,
        }

    def write_reports(self, output_dir: Path):
        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)

        (output_dir / "analysis.txt").write_text(self.format_text_report(), encoding="utf-8")
        (output_dir / "analysis.json").write_text(
            json.dumps(self.to_dict(), indent=4, ensure_ascii=False),
            encoding="utf-8",
        )
