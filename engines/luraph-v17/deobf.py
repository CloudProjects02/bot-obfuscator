#!/usr/bin/env python3
import re
import sys
from pathlib import Path

def decode_payload(text: str) -> str:
    names = [
        "_0xEBFED7ADEA5A23",
        "_0x9EC7C77C4F84C5",
        "_0xAECC2C14B177D1",
        "_0x06EB2BA32BD4D6",
    ]

    parts = []
    for name in names:
        m = re.search(
            rf'local\s+{re.escape(name)}\s*=\s*"([0-9a-fA-F]+)"',
            text
        )
        if not m:
            raise ValueError(f"Could not find {name}")
        raw = bytes.fromhex(m.group(1))
        parts.append(raw.decode("utf-8", errors="replace"))

    # The VM's LOAD_CONST instructions select these source fragments.
    # Also decode the VM instruction stream when present.
    vm_match = re.search(
        r'local\s+_0x1FFC59FC106910\s*=\s*"([0-9a-fA-F]+)"',
        text
    )
    vm_hex = vm_match.group(1) if vm_match else ""

    out = []
    out.append("-- Decoded static payload fragments")
    out.append("-- Fragment 0")
    out.append(parts[0])
    out.append("\n-- Fragment 1")
    out.append(parts[1])
    out.append("\n-- Fragment 2")
    out.append(parts[2])
    out.append("\n-- Fragment 3")
    out.append(parts[3])

    if vm_hex:
        out.append("\n-- VM instruction bytes (hex-decoded)")
        out.append(bytes.fromhex(vm_hex).hex(" "))

    return "\n".join(out)

def main():
    if len(sys.argv) != 2:
        print(f"Usage: {Path(sys.argv[0]).name} input.lua")
        raise SystemExit(2)

    src = Path(sys.argv[1])
    text = src.read_text(encoding="utf-8", errors="replace")

    decoded = decode_payload(text)
    out = src.with_name(src.stem + "_decoded.lua")
    out.write_text(decoded, encoding="utf-8")

    print(f"Decoded payload written to: {out}")

if __name__ == "__main__":
    main()

