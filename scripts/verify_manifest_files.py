import json, os, sys

try:
    manifest = json.load(open(".claude-plugin/plugin.json", encoding="utf-8"))
except (OSError, json.JSONDecodeError) as e:
    print(f"FAIL: could not load plugin.json: {e}")
    sys.exit(1)

errors = []

def normalise_path(path):
    return path[2:] if path.startswith("./") else path

for path in manifest.get("commands", []):
    normalised = normalise_path(path)
    if not os.path.exists(normalised):
        errors.append(f"Missing command file: {path}")

for path in manifest.get("agents", []):
    normalised = normalise_path(path)
    if not os.path.exists(normalised):
        errors.append(f"Missing agent file: {path}")

component_paths = {
    "skills": manifest.get("skills"),
    "hooks": manifest.get("hooks"),
    "mcpServers": manifest.get("mcpServers"),
    "lspServers": manifest.get("lspServers"),
}

for field, value in component_paths.items():
    if not value:
        continue
    values = value if isinstance(value, list) else [value]
    for path in values:
        if not isinstance(path, str):
            continue
        normalised = normalise_path(path)
        if not os.path.exists(normalised):
            errors.append(f"Missing {field} path: {path}")

if errors:
    for e in errors:
        print(e)
    sys.exit(1)

print(f"All manifest files present ({len(manifest.get('commands', []))} commands, "
      f"{len(manifest.get('agents', []))} agents)")
