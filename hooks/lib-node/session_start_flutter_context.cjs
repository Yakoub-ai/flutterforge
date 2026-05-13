'use strict';
// session_start_flutter_context.cjs
// Triggered: SessionStart
// Outputs a concise Flutter project context block so Claude begins each session
// with project awareness, eliminating redundant discovery queries.
// No-ops silently when no pubspec.yaml is found within 6 parent levels.

const fs = require('fs');
const path = require('path');
const { findFlutterProjectRoot, runCmd } = require('./_common.cjs');

const root = findFlutterProjectRoot(process.cwd());
if (!root) process.exit(0);

let pubspec = '';
try {
  pubspec = fs.readFileSync(path.join(root, 'pubspec.yaml'), 'utf8');
} catch {
  process.exit(0);
}

// App name
const nameMatch = pubspec.match(/^name:\s*(.+)/m);
const appName = nameMatch ? nameMatch[1].trim() : 'unknown';

// State management
let stateMgmt = 'unknown';
if (/flutter_riverpod|riverpod_annotation/.test(pubspec)) stateMgmt = 'riverpod';
else if (/flutter_bloc|^\s*bloc:/.test(pubspec))          stateMgmt = 'bloc/cubit';
else if (/\bprovider:/.test(pubspec))                      stateMgmt = 'provider';
else if (/\bget:/.test(pubspec))                           stateMgmt = 'getx';

// Router
let router = 'unknown';
if (/go_router/.test(pubspec))   router = 'go_router';
else if (/auto_route/.test(pubspec)) router = 'auto_route';

// Flutter version — best-effort, 2 s timeout, no-op on miss
let flutterVersion = '(flutter not on PATH)';
const vr = runCmd('flutter', ['--version', '--machine'], root, 2000);
if (!vr.timedOut && vr.exitCode === 0 && vr.stdout) {
  try {
    const info = JSON.parse(vr.stdout);
    flutterVersion = info.frameworkVersion || info.version || '(unknown)';
  } catch { /* ignore parse errors */ }
}

// Planning docs and CI presence
const exists = (rel) => fs.existsSync(path.join(root, rel)) ? 'yes' : 'no';

process.stdout.write(
  `[FlutterForge — Session Context]\n` +
  `App: ${appName}\n` +
  `Flutter: ${flutterVersion}\n` +
  `State management: ${stateMgmt}\n` +
  `Router: ${router}\n` +
  `Architecture plan: ${exists('docs/architecture/technical_plan.md')}  (docs/architecture/technical_plan.md)\n` +
  `Product brief: ${exists('docs/product/app_brief.md')}  (docs/product/app_brief.md)\n` +
  `CI configured: ${exists('.github/workflows/flutter_ci.yml')}  (.github/workflows/flutter_ci.yml)\n` +
  `Project root: ${root}\n`
);
