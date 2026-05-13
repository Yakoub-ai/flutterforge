import json, os, sys

try:
    manifest = json.load(open(".claude-plugin/plugin.json", encoding="utf-8"))
except (OSError, json.JSONDecodeError) as e:
    print(f"FAIL: could not load plugin.json: {e}")
    sys.exit(1)

errors = []

for path in manifest.get("commands", []):
    normalised = path.lstrip("./")
    if not os.path.exists(normalised):
        errors.append(f"Missing command file: {path}")

for path in manifest.get("agents", []):
    normalised = path.lstrip("./")
    if not os.path.exists(normalised):
        errors.append(f"Missing agent file: {path}")

if errors:
    for e in errors:
        print(e)
    sys.exit(1)

print(f"All manifest files present ({len(manifest.get('commands', []))} commands, "
      f"{len(manifest.get('agents', []))} agents)")
