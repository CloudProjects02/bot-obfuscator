from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import List

from lexer import LexerError, tokenize
from structure import parse, node_to_dict, program_to_dict
from constants import fold_expression
from strings import StringCatalog, extract_strings
from lph import LPHDetector
from lph_dumper import dump_lph
from ir import build_ir
from cfg import build_cfg_for_functions
from optimizer import optimize_ast
from anti_analysis import detect_anti_analysis
from vm_detector import detect_vm
from devirtualizer import devirtualize_program
from closures import analyze_scopes
from renamer import rename_variables
from codegen import generate_lua
from reporter import AnalysisReporter
from compiler import compile_program_to_bytecode
from runner import create_instrumented_runner_file


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Cracker2 — Full Lua/Luau Static Analysis and Deobfuscation Pipeline"
    )

    parser.add_argument(
        "input",
        help="Input Lua/Luau file path",
    )

    parser.add_argument(
        "-o",
        "--output",
        help="Output directory path (default: ./output)",
    )

    parser.add_argument(
        "--tokens",
        action="store_true",
        help="Dump token stream to console/output",
    )

    parser.add_argument(
        "--ast",
        action="store_true",
        help="Dump AST structure",
    )

    parser.add_argument(
        "--constants",
        action="store_true",
        help="Expose recovered constant table",
    )

    parser.add_argument(
        "--strings",
        action="store_true",
        help="Expose recovered string dump",
    )

    parser.add_argument(
        "--cfg",
        action="store_true",
        help="Dump Control Flow Graph",
    )

    parser.add_argument(
        "--ir",
        action="store_true",
        help="Dump Intermediate Representation",
    )

    parser.add_argument(
        "--anti-analysis",
        action="store_true",
        help="Dump Anti-Analysis detections",
    )

    parser.add_argument(
        "--vm",
        action="store_true",
        help="Expose VM / Dispatcher analysis",
    )

    parser.add_argument(
        "--deobfuscate",
        action="store_true",
        help="Run full deobfuscation transformations",
    )

    parser.add_argument(
        "--debug",
        action="store_true",
        help="Enable full intermediate stage debugging and output all artifacts",
    )

    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.is_file():
        print(f"[!] Input file not found: {input_path}")
        return 1

    project_root = Path(__file__).resolve().parent
    if args.output:
        output_dir = Path(args.output)
    else:
        output_dir = project_root / "output"

    output_dir.mkdir(parents=True, exist_ok=True)

    source = input_path.read_text(encoding="utf-8", errors="replace")

    print("[*] Cracker2 v16 — Lua/Luau Static Analysis & Deobfuscation Pipeline")
    print(f"[*] Input: {input_path} ({len(source)} bytes)")
    print(f"[*] Output: {output_dir}")
    print()

    # -------------------------------------------------------------------------
    # Stage 1: Lexing
    # -------------------------------------------------------------------------
    print("[1/9] Lexing........................", end=" ", flush=True)
    try:
        tokens = tokenize(source)
        print("OK")
    except LexerError as exc:
        print(f"FAILED\n[!] Lexer error: {exc}")
        (output_dir / "error.json").write_text(
            json.dumps({"stage": "lexer", "message": str(exc)}, indent=4),
            encoding="utf-8",
        )
        return 1

    token_data = [
        {
            "index": idx,
            "kind": t.kind,
            "value": t.value,
            "position": t.position,
            "line": t.line,
            "column": t.column,
        }
        for idx, t in enumerate(tokens[:-1])
    ]
    (output_dir / "tokens.json").write_text(
        json.dumps({"count": len(token_data), "tokens": token_data}, indent=4, ensure_ascii=False),
        encoding="utf-8",
    )

    # -------------------------------------------------------------------------
    # Stage 2: Parsing & AST Construction
    # -------------------------------------------------------------------------
    print("[2/9] Parsing.......................", end=" ", flush=True)
    try:
        program = parse(tokens)
        print("OK")
    except Exception as exc:
        print(f"FAILED\n[!] Parser error: {exc}")
        (output_dir / "error.json").write_text(
            json.dumps({"stage": "parser", "message": str(exc)}, indent=4),
            encoding="utf-8",
        )
        return 1

    structure_dict = program_to_dict(program)
    (output_dir / "structure.json").write_text(
        json.dumps(structure_dict, indent=4, ensure_ascii=False),
        encoding="utf-8",
    )

    # -------------------------------------------------------------------------
    # Stage 3: LPH Containers
    # -------------------------------------------------------------------------
    print("[3/9] Container Analysis............", end=" ", flush=True)
    containers = LPHDetector.find_containers(source)
    dump_lph(source, output_dir)
    print(f"OK ({len(containers)} container{'s' if len(containers) != 1 else ''})")

    # -------------------------------------------------------------------------
    # Stage 4: Constant & String Recovery
    # -------------------------------------------------------------------------
    print("[4/9] String & Constant Recovery....", end=" ", flush=True)
    string_catalog = StringCatalog()
    string_catalog.extract_from_ast(program.body)

    # Incorporate container extracted strings
    for c in containers:
        for s in c.extracted_strings:
            string_catalog.add(s, line=c.line, column=c.column, source_kind="CONTAINER")

    string_result = string_catalog.build_result()
    strings_txt_content = string_catalog.format_strings_txt()
    (output_dir / "strings.txt").write_text(strings_txt_content, encoding="utf-8")
    print(f"OK ({len(string_result.all_strings)} total, {len(string_result.meaningful_strings)} meaningful)")

    # -------------------------------------------------------------------------
    # Stage 5: Control-Flow Analysis (IR & CFG)
    # -------------------------------------------------------------------------
    print("[5/9] CFG & IR Construction........", end=" ", flush=True)
    ir_functions = build_ir(program)
    cfg_list = build_cfg_for_functions(ir_functions)

    ir_text = "\n\n".join(fn.format() for fn in ir_functions)
    (output_dir / "ir.txt").write_text(ir_text, encoding="utf-8")

    cfg_text = "\n\n".join(cfg.format() for cfg in cfg_list)
    (output_dir / "cfg.txt").write_text(cfg_text, encoding="utf-8")
    print(f"OK ({len(ir_functions)} function{'s' if len(ir_functions) != 1 else ''}, {sum(len(c.blocks) for c in cfg_list)} blocks)")

    # -------------------------------------------------------------------------
    # Stage 6: Anti-Analysis Detection
    # -------------------------------------------------------------------------
    print("[6/9] Anti-Analysis Detection.......", end=" ", flush=True)
    anti_report = detect_anti_analysis(program, source)
    print("DETECTED" if (anti_report.debug_inspection or anti_report.environment_checks or anti_report.dynamic_compilation or anti_report.vm_dispatcher) else "CLEAN")

    # -------------------------------------------------------------------------
    # Stage 7: VM Recognition & Devirtualization
    # -------------------------------------------------------------------------
    print("[7/9] VM / Dispatcher Analysis......", end=" ", flush=True)
    vm_report = detect_vm(program, source)
    if vm_report.vm_detected:
        print(f"DETECTED ({vm_report.confidence.upper()} confidence, ~{vm_report.possible_opcode_count} opcodes)")
    else:
        print("NONE")

    devirt_program, devirt_status = devirtualize_program(program, vm_report)

    # -------------------------------------------------------------------------
    # Stage 8: AST Optimization & Cleanup
    # -------------------------------------------------------------------------
    print("[8/9] AST Optimization & Cleanup....", end=" ", flush=True)
    optimized_program = optimize_ast(devirt_program)
    scopes = analyze_scopes(optimized_program)
    cleaned_program = rename_variables(optimized_program)
    print("OK")

    # -------------------------------------------------------------------------
    # Stage 9: Code Generation & Reporting
    # -------------------------------------------------------------------------
    print("[9/9] Code Generation & Reporting...", end=" ", flush=True)
    header_comment = None
    if vm_report.vm_detected:
        header_comment = (
            "-- ==============================================================================\n"
            "--  CRACKER2 DEOBFUSCATION REPORT & DEVIRTUALIZED CODE\n"
            f"--  Target Protection: {'Luraph VM Protected' if any('Luraph' in ind for ind in vm_report.indicators) else 'Custom Virtual Machine'}\n"
            "-- ==============================================================================\n"
            f"--  [VM Architecture]\n"
            f"--  - Status: {devirt_status}\n"
            f"--  - Confidence: {vm_report.confidence.upper()}\n"
            f"--  - Registers: {vm_report.possible_register_array or 'F[0..255]'}\n"
            f"--  - Program Counter: {vm_report.possible_pc_variable or 'pc/ip'}\n"
            f"--  - Payload Containers: {len(containers)} container(s) extracted to container_0001/\n"
            "--  - Standard Environment Aliases:\n"
            "--      * bit32 (band, bor, bxor, bnot, lshift, rshift)\n"
            "--      * buffer (create, copy, fill, len, fromstring, tostring, readu8, writeu8, readu32, readi16, readi32)\n"
            "--      * coroutine (wrap, yield, resume, isyieldable, close)\n"
            "--      * table (pack, unpack, move)\n"
            "--      * global (getfenv, setfenv, pcall, select, next, tonumber)\n"
            "-- ==============================================================================\n"
        )
    deobfuscated_source = generate_lua(cleaned_program, header_comment=header_comment)
    (output_dir / "deobfuscated.lua").write_text(deobfuscated_source, encoding="utf-8")

    # Generate dynamic instrumented runner harness with hooks
    create_instrumented_runner_file(deobfuscated_source, output_dir / "instrumented_runner.lua")

    # Compile AST into standard binary chunk for external decompilers (e.g. Medal, Unluau)
    compiled_bytes = compile_program_to_bytecode(cleaned_program, output_dir / "compiled.luac")
    (output_dir / "compiled.bin").write_bytes(compiled_bytes)

    # Save exact copy of source for traceability
    (output_dir / "source.lua").write_text(source, encoding="utf-8")

    unresolved: List[str] = []
    if vm_report.vm_detected:
        unresolved.append("Virtualized bytecode stream remains internal; outer dispatcher and handlers structured without execution")
    if not string_result.meaningful_strings and not string_result.all_strings:
        unresolved.append("No plaintext constants present in outer AST")

    reporter = AnalysisReporter(
        input_path=input_path,
        source_size=len(source),
        token_count=len(tokens) - 1,
        statement_count=len(program.body.statements),
        string_result=string_result,
        anti_report=anti_report,
        vm_report=vm_report,
        containers=containers,
        devirtualization_status=devirt_status,
        unresolved_items=unresolved,
    )
    reporter.write_reports(output_dir)
    print("OK")

    print()
    print("================================================================================")
    print("                              DEOBFUSCATION COMPLETE                            ")
    print("================================================================================")
    print(f"[+] Output directory: {output_dir}")
    print(f"  - deobfuscated.lua         : Reconstructed Lua/Luau source code")
    print(f"  - instrumented_runner.lua  : Dynamic execution harness with runtime memory hooks")
    print(f"  - compiled.luac            : Compiled Lua 5.1 binary chunk (for decompilers / VM tools)")
    print(f"  - compiled.bin             : Raw compiled bytecode binary")
    print(f"  - strings.txt              : {len(string_result.all_strings)} recovered strings ({len(string_result.meaningful_strings)} meaningful)")
    print(f"  - analysis.txt             : Complete human-readable technical report")
    print(f"  - analysis.json            : Structured machine-readable metrics")
    print(f"  - ir.txt & cfg.txt         : Intermediate Representation & Control Flow Graph")
    print(f"  - tokens.json              : Lexer token stream")
    print()

    # If specific debug inspection was requested on CLI, print to stdout
    if args.strings:
        print("--- Recovered Strings ---")
        print(strings_txt_content)

    if args.anti_analysis:
        print("--- Anti-Analysis Report ---")
        print(anti_report.format())

    if args.vm:
        print("--- VM Analysis Report ---")
        print(vm_report.format())

    if args.ir:
        print("--- Intermediate Representation ---")
        print(ir_text)

    if args.cfg:
        print("--- Control Flow Graph ---")
        print(cfg_text)

    return 0


if __name__ == "__main__":
    sys.exit(main())