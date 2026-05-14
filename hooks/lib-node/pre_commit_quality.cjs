'use strict';
// pre_commit_quality.cjs
// Triggered: PreToolUse on Bash (filtered to git commit commands inside the script)
// Runs: dart format --set-exit-if-changed → flutter analyze → flutter test
// Blocks the commit if any step fails.
//
// Env vars:
//   FLUTTERFORGE_SKIP_PRECOMMIT=1  bypass all checks

const fs = require('fs');
const path = require('path');
const { readStdin, findFlutterProjectRoot, block, allow, shouldSkip, runCmd } = require('./_common.cjs');

if (shouldSkip('FLUTTERFORGE_SKIP_PRECOMMIT')) allow();

const input = readStdin();
const toolName = input.tool_name || '';
const command = (input.tool_input && input.tool_input.command) || '';

// This hook is wired to all Bash calls; gate here on git commit
if (toolName !== 'Bash' || !/\bgit\s+commit\b/.test(command)) allow();

const root = findFlutterProjectRoot(input.cwd || process.cwd());
if (!root) allow();

const failures = [];
const details = [];

// ── Step 1: dart format ───────────────────────────────────────────────────────
process.stderr.write('FlutterForge [pre_commit_quality]: Checking dart format...\n');
const fmt = runCmd('dart', ['format', '--set-exit-if-changed', '.'], root, 60000);
if (fmt.exitCode !== 0) {
  failures.push('dart format');
  details.push('  • dart format: unformatted Dart files detected. Run: dart format .');
}

// ── Step 2: flutter analyze ───────────────────────────────────────────────────
process.stderr.write('FlutterForge [pre_commit_quality]: Running flutter analyze...\n');
const analyze = runCmd('flutter', ['analyze', '--no-fatal-infos'], root, 120000);
if (analyze.exitCode !== 0) {
  failures.push('flutter analyze');
  const errors = analyze.stdout
    .split('\n')
    .filter((l) => /^(error|warning|  •)/.test(l))
    .slice(0, 15)
    .join('\n');
  details.push(`  • flutter analyze errors:\n${errors}`);
}

// ── Step 3: flutter test (only if test/ directory exists) ─────────────────────
if (fs.existsSync(path.join(root, 'test'))) {
  process.stderr.write('FlutterForge [pre_commit_quality]: Running flutter test...\n');
  const test = runCmd('flutter', ['test'], root, 180000);
  if (test.exitCode !== 0) {
    failures.push('flutter test');
    const tail = test.stdout.split('\n').slice(-10).join('\n');
    details.push(`  • flutter test failures:\n${tail}`);
  }
} else {
  process.stderr.write('FlutterForge [pre_commit_quality]: No test/ directory — skipping flutter test.\n');
}

// ── Result ────────────────────────────────────────────────────────────────────
if (failures.length > 0) {
  block(
    `FlutterForge: Commit blocked. Failed checks: ${failures.join(', ')}.\n\n` +
    `${details.join('\n\n')}\n\n` +
    `Fix the issues above, re-stage your files, then commit again.\n` +
    `To skip all checks: FLUTTERFORGE_SKIP_PRECOMMIT=1`
  );
}

process.stdout.write('FlutterForge [pre_commit_quality]: All quality checks passed.\n');
allow();
