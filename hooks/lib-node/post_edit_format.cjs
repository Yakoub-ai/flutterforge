'use strict';
// post_edit_format.cjs
// Triggered: PostToolUse on Write|Edit
// Runs dart format --fix on the edited file if it is a .dart file.
// Always exits 0 (non-blocking) — formatting is advisory.

const path = require('path');
const { readStdin, findFlutterProjectRoot, runCmd } = require('./_common.cjs');

const input = readStdin();
const filePath = (input.tool_input && input.tool_input.file_path) || '';

if (!filePath.endsWith('.dart')) process.exit(0);

const root = findFlutterProjectRoot(path.dirname(path.resolve(filePath)));
if (!root) process.exit(0);

const result = runCmd('dart', ['format', '--fix', filePath], root, 15000);
if (result.exitCode !== 0) {
  // Inform Claude but never block
  process.stdout.write(
    `FlutterForge [post_edit_format]: Warning — dart format failed for ${path.basename(filePath)}\n`
  );
}

process.exit(0);
