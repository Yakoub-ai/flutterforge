'use strict';
// pubspec_sync.cjs
// Triggered: PostToolUse on Write|Edit
// Runs flutter pub get when pubspec.yaml is edited.
// Always exits 0 (non-blocking) — pub get may fail on incomplete files.

const path = require('path');
const { readStdin, findFlutterProjectRoot, runCmd } = require('./_common.cjs');

const input = readStdin();
const filePath = (input.tool_input && input.tool_input.file_path) || '';

// Only act on pubspec.yaml edits
if (!filePath.endsWith('pubspec.yaml')) process.exit(0);

const root = findFlutterProjectRoot(path.dirname(path.resolve(filePath)));
if (!root) process.exit(0);

process.stdout.write('FlutterForge [pubspec_sync]: Running flutter pub get...\n');

const result = runCmd('flutter', ['pub', 'get', '--directory', root], root, 60000);

if (result.exitCode !== 0) {
  process.stdout.write(
    `FlutterForge [pubspec_sync]: Warning — flutter pub get failed.\n` +
    `  This may be expected if pubspec.yaml is not yet complete.\n` +
    `  Run 'flutter pub get' manually when ready.\n`
  );
} else {
  process.stdout.write('FlutterForge [pubspec_sync]: Dependencies updated.\n');
}

process.exit(0);
