# FlutterForge Monitors

Claude Code does not currently support persistent background monitor processes in
plugins. This directory is reserved for future monitor definitions. This document
explains what monitors would do, how FlutterForge's hooks cover the same quality gates
today, and how to run manual monitoring sessions.

---

## What Monitors Would Do (Forward-Looking)

A monitor is a long-running process that watches a stream of events and fires a callback
when a condition is met. Once Claude Code adds monitor support, FlutterForge would ship
three:

### `flutter_run_watcher` — Widget Rebuild Storm Detection

Watches `flutter run --verbose` output for excessive widget rebuilds that degrade
performance:

- Triggers when the same widget rebuilds more than N times per second outside an
  animation frame.
- Notifies Claude with the widget name and call stack so the performance engineer agent
  can suggest `const` constructors, `RepaintBoundary`, or state management fixes.

### `flutter_test_flakiness_watcher` — Flaky Test Detection

Watches `flutter test --reporter json` output across repeated runs:

- Records per-test pass/fail history.
- Flags tests that fail intermittently (e.g., fail 2 of 5 runs) as flaky.
- Triggers the test engineer agent to investigate timing dependencies, async leaks, or
  platform-specific assumptions.

### `flutter_build_size_watcher` — Build Size Regression Detection

Watches `flutter build apk --analyze-size` and `flutter build ipa --analyze-size`
output:

- Compares the current build's size breakdown to the previous recorded baseline.
- Triggers an alert when total size grows by more than a configured threshold (default
  5%) or when a specific package's contribution spikes unexpectedly.

---

## Current Alternative: Hooks

Until Claude Code supports monitors, FlutterForge hooks fire on specific tool-use events
and cover the most critical quality gates:

| Hook | Trigger | What it monitors |
|------|---------|-----------------|
| `post_edit_format.sh` | PostToolUse Write/Edit | Runs `dart format` — catches formatting regressions immediately after any file edit |
| `post_edit_analyze.sh` | PostToolUse Write/Edit | Runs `flutter analyze` — equivalent to LSP diagnostics; catches type errors, unused imports, and lint violations after every edit |
| `pubspec_sync.sh` | PostToolUse Write/Edit on `pubspec.yaml` | Runs `flutter pub get` automatically when dependencies change, preventing stale lockfiles |
| `secret_detect.sh` | PreToolUse Write/Edit | Scans file content for API keys, tokens, and credentials before the write is committed |
| `pre_commit_quality.sh` | PreToolUse Bash git commit | Runs the full analysis + test suite before allowing a commit, acting as a local CI gate |

These hooks do not run continuously — they fire on-demand when Claude uses the relevant
tool. For continuous monitoring, use the user-runnable approach below.

---

## User-Runnable Monitoring

### Capturing a `flutter run` session

To collect verbose logs from a running app for later analysis:

```bash
flutter run --verbose 2>&1 | tee flutter_run.log
```

Once the session ends, ask Claude to analyze the log:

> "Read `flutter_run.log` and identify any widget rebuild storms, dropped frames, or
> shader compilation jank."

### Using `collect_flutter_logs.sh`

The script at `scripts/collect_flutter_logs.sh` automates log collection with timestamps
and structured output. Run it in a separate terminal while `flutter run` is active:

```bash
bash scripts/collect_flutter_logs.sh --output logs/session_$(date +%Y%m%d_%H%M%S).log
```

The script prefixes each line with a timestamp and separates stdout from stderr, making
it easier for Claude to correlate log events with rebuild counts or frame timings.

### Watching test flakiness manually

Run the test suite multiple times and capture output:

```bash
for i in {1..5}; do
  flutter test --reporter json >> logs/test_runs.jsonl 2>&1
done
```

Then ask Claude to parse `logs/test_runs.jsonl` and report which tests had inconsistent
results across the five runs.

---

## Speculative Monitor Definition Format

When Claude Code adds monitor support, a `monitors/flutter_run_watcher.json` definition
would look like this:

```json
{
  "name": "flutter_run_watcher",
  "description": "Watches flutter run output for widget rebuild storms and frame drops",
  "command": "flutter run --verbose",
  "triggers": [
    {
      "name": "rebuild_storm",
      "pattern": "\\brebuild\\b.*\\b(\\d+)\\b",
      "condition": "match_count > 20 within 1000ms",
      "action": {
        "type": "notify_claude",
        "message": "Widget rebuild storm detected: {{match}}. Investigate with the mobile-performance-engineer agent.",
        "agent": "mobile-performance-engineer"
      }
    },
    {
      "name": "dropped_frame",
      "pattern": "Skipped (\\d+) frame",
      "condition": "capture_1 > 5",
      "action": {
        "type": "notify_claude",
        "message": "{{capture_1}} frames dropped. Check for synchronous work on the UI thread."
      }
    }
  ],
  "timeout_seconds": 3600
}
```

This format is speculative — it is documented here so that when the Claude Code platform
adds monitor support, FlutterForge can ship working definitions without redesigning the
concept from scratch.

---

## See Also

- `scripts/collect_flutter_logs.sh` — structured log collection
- `scripts/flutter_analyze.sh` — standalone static analysis
- `scripts/flutter_test.sh` — test runner with coverage reporting
- `hooks/hooks.json` — event-driven quality gate configuration
