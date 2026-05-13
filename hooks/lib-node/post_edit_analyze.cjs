'use strict';
// post_edit_analyze.cjs
// Triggered: PostToolUse on Write|Edit
// Runs flutter analyze after a Dart file edit and reports issues to Claude.
// Opt-in: only runs when FLUTTERFORGE_AUTO_ANALYZE=1.

const path = require('path');
const { readStdin, findFlutterProjectRoot, runCmd } = require('./_common.cjs');

// Guard: only run if explicitly enabled
if (process.env.FLUTTERFORGE_AUTO_ANALYZE !== '1') process.exit(0);

const input = readStdin();
const filePath = (input.tool_input && input.tool_input.file_path) || '';

if (!filePath.endsWith('.dart')) process.exit(0);

const root = findFlutterProjectRoot(path.dirname(path.resolve(filePath)));
if (!root) process.exit(0);

process.stdout.write('FlutterForge [post_edit_analyze]: Running flutter analyze...\n');

const result = runCmd('flutter', ['analyze', '--no-pub', '--no-fatal-infos'], root, 120000);

if (result.exitCode !== 0) {
  const issues = result.stdout
    .split('\n')
    .filter((l) => /^(error|warning|hint|  •)/.test(l))
    .slice(0, 20)
    .join('\n');
  process.stdout.write(
    `FlutterForge [post_edit_analyze]: Issues detected — fix before committing:\n${issues}\n`
  );
} else {
  process.stdout.write('FlutterForge [post_edit_analyze]: No issues found.\n');
}

// Always exit 0 for PostToolUse — tool already ran, we're informing Claude
process.exit(0);
