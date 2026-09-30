import secrets, string
from pathlib import Path

alphabet = string.ascii_uppercase + string.digits
keys = []
seen = set()

while len(keys) < 1000:
    a = ''.join(secrets.choice(alphabet) for _ in range(6))
    b = ''.join(secrets.choice(alphabet) for _ in range(6))
    key = f"Luarurape-Serial-{a}-{b}"
    if key not in seen:
        seen.add(key)
        keys.append(key)

path = Path(r"C:/Users/Bitra/Documents/skibidi/moonveilvro-main/moonveilvro-main/luraph-v17-obf/license_keys.txt")
path.write_text("\n".join(keys) + "\n", encoding="utf-8")

print(f"Generated {len(keys)} unique license keys.")
print(path)
