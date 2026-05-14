import sys


def check(path):
    try:
        content = open(path, encoding="utf-8").read()
    except OSError as e:
        return f"FAIL: {path} could not be read: {e}"

    if not content.startswith("---\n"):
        return f"FAIL: {path} missing YAML frontmatter opening ---"

    parts = content.split("---")
    if len(parts) < 3:
        return f"FAIL: {path} frontmatter not closed with ---"

    front = parts[1]
    for field in ("name:", "description:", "model:"):
        if field not in front:
            return f"FAIL: {path} missing '{field}' in frontmatter"

    return f"OK: {path}"


if len(sys.argv) < 2:
    print("FAIL: expected at least one agent file path")
    sys.exit(1)

failed = False
for path in sys.argv[1:]:
    result = check(path)
    print(result)
    failed = failed or result.startswith("FAIL")

sys.exit(1 if failed else 0)
