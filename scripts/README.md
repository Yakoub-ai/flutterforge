# FlutterForge Scripts

Utility shell scripts for Flutter operations. All scripts require Bash (Git Bash or WSL on Windows).

---

## Cross-Platform Notes

- **macOS / Linux**: run directly — `bash scripts/flutter_analyze.sh`
- **Windows**: use Git Bash (`Git Bash Here`) or WSL (`wsl bash scripts/flutter_analyze.sh`)
- iOS build scripts (`flutter_build_ios.sh`) are no-ops on non-macOS — they exit 0 with an informational message

---

## Scripts Reference

### `flutter_doctor_check.sh`

Check Flutter installation and environment health.

```
bash scripts/flutter_doctor_check.sh [--help]
```

- Runs `flutter doctor -v` and summarises what is working and what needs attention
- **Exit 0** even if doctor shows warnings (warnings are not blocking)
- **Exit 1** only if Flutter is not installed

---

### `flutter_analyze.sh`

Run static analysis on a Flutter project.

```
bash scripts/flutter_analyze.sh [--fix] [--path <dir>] [--help]
```

| Flag | Description |
|------|-------------|
| `--fix` | Also run `dart fix --apply` before analysing |
| `--path <dir>` | Analyse a specific directory instead of `.` |

- Categorises output into errors / warnings / infos
- **Exit 1** if any errors are found, **exit 0** otherwise

---

### `flutter_test.sh`

Run Flutter unit, integration, or golden tests.

```
bash scripts/flutter_test.sh [--coverage] [--integration] [--golden] [--watch] [--path <file-or-dir>] [--help]
```

| Flag | Description |
|------|-------------|
| `--coverage` | Collect coverage and report percentage from `coverage/lcov.info` |
| `--integration` | Run tests in `integration_test/` |
| `--golden` | Pass `--update-goldens` to update golden files |
| `--watch` | Pass `--watch` for continuous test running |
| `--path <p>` | Target a specific test file or directory |

- **Exit 1** if any tests fail

---

### `flutter_format.sh`

Format all Dart files with `dart format`.

```
bash scripts/flutter_format.sh [--check] [--path <dir>] [--help]
```

| Flag | Description |
|------|-------------|
| `--check` | Check formatting without modifying files; exits 1 if unformatted files found |
| `--path <dir>` | Format/check a specific directory |

---

### `flutter_build_android.sh`

Build Android release artifacts.

```
bash scripts/flutter_build_android.sh [--apk] [--appbundle] [--flavor <name>] [--dart-define KEY=VALUE] [--help]
```

| Flag | Description |
|------|-------------|
| `--apk` | Build an APK instead of App Bundle |
| `--appbundle` | Build an App Bundle (default) |
| `--flavor <name>` | Specify a build flavor |
| `--dart-define KEY=VALUE` | Pass Dart defines; may be repeated |

- Prints build output location on success
- Prints diagnostic hints for common failures (Gradle, keystore, SDK)
- **Exit 1** on failure

---

### `flutter_build_ios.sh`

Build iOS release artifacts (requires macOS).

```
bash scripts/flutter_build_ios.sh [--simulator] [--export-plist <path>] [--help]
```

| Flag | Description |
|------|-------------|
| `--simulator` | Build for iOS Simulator instead of device |
| `--export-plist <path>` | Path to export options plist |

- **Non-macOS**: prints an informational message and exits 0 (not an error)
- Prints diagnostic hints for CocoaPods, Xcode version, and signing failures
- **Exit 1** on failure (macOS only)

---

### `verify_mcps.sh` / `verify_mcps.ps1`

Smoke-test all configured MCP servers (default and optional).

```
bash scripts/verify_mcps.sh [<plugin-root>]   # macOS / Linux
pwsh scripts/verify_mcps.ps1 [-PluginRoot <path>]  # Windows
```

- Sends an MCP `initialize` message to each configured server and checks for a valid response
- Skips optional servers when their required env var is not set (reports as `-` rather than `FAIL`)
- **Exit 0** if all active servers respond correctly; **Exit 1** if any server fails
- Run this after first install or when troubleshooting a server that is not responding

---

### `collect_flutter_logs.sh`

Collect Flutter project context for debugging.

```
bash scripts/collect_flutter_logs.sh [--help]
```

Collects and prints:
- Flutter and Dart versions
- `flutter doctor` summary
- `pubspec.yaml` (secrets redacted)
- `analysis_options.yaml` (if present)
- `lib/` directory structure
- Recent `flutter analyze` output
- Test file count
- iOS Podfile.lock Flutter version (macOS only)
- Android `local.properties` Flutter SDK path

**Always exits 0.** Collection failures are printed as warnings.

---

## Environment Variables

| Variable | Used by | Description |
|----------|---------|-------------|
| `FLUTTER_ROOT` | `flutter_doctor_check.sh` | Override Flutter SDK path for the doctor check |

---

## Adding New Scripts

1. Start with `#!/usr/bin/env bash` and `set -euo pipefail` (omit the latter for diagnostic/collection scripts)
2. Add a `--help` handler
3. Document the script in this README
