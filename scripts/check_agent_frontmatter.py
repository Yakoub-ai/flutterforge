import sys

path = sys.argv[1]
try:
    content = open(path, encoding="utf-8").read()
except OSError as e:
    print(f"FAIL: {path} could not be read: {e}")
    sys.exit(1)

if not content.startswith("---\n"):
    print(f"FAIL: {path} missing YAML frontmatter opening ---")
    sys.exit(1)

parts = content.split("---")
if len(parts) < 3:
    print(f"FAIL: {path} frontmatter not closed with ---")
    sys.exit(1)

front = parts[1]
for field in ("name:", "description:", "model:"):
    if field not in front:
        print(f"FAIL: {path} missing '{field}' in frontmatter")
        sys.exit(1)

print(f"OK: {path}")
