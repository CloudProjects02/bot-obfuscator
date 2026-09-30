import sys, os, subprocess, json

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LUNE = os.path.join(ROOT, "lune.exe")
MAIN = os.path.join(ROOT, "main.luau")

def main():
    args = sys.argv[1:]
    if len(args) < 1 or args[0] != "decompile":
        print("usage: LuraphDeobfuscator.exe decompile <input> --output <output>")
        sys.exit(1)
    
    in_file = None
    out_file = None
    for i, a in enumerate(args):
        if a == "--output" and i + 1 < len(args):
            out_file = args[i + 1]
        elif a != "decompile" and not a.startswith("-"):
            in_file = a
    
    if not in_file or not out_file:
        print("Missing input or output")
        sys.exit(1)
    
    result = subprocess.run(
        [LUNE, "run", MAIN, in_file, f"out={out_file}", "discord=false"],
        capture_output=True, text=True, timeout=300
    )
    
    if os.path.exists(out_file) and os.path.getsize(out_file) > 0:
        sys.exit(0)
    else:
        print(result.stderr or "No output produced")
        sys.exit(1)

if __name__ == "__main__":
    main()
