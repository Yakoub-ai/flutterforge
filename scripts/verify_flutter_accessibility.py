import json, sys

manifest = json.load(open(".claude-plugin/plugin.json", encoding="utf-8"))
commands = manifest.get("commands", [])
if not any("flutter-accessibility" in c for c in commands):
    print("FAIL: commands/flutter-accessibility.md not registered in plugin.json")
    sys.exit(1)
print("OK: flutter-accessibility command is registered")
