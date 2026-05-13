'use strict';
// _common.cjs — Shared helpers for FlutterForge Node.js hooks.
// All hooks require() this file. No external dependencies.

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

/** Read and parse hook input JSON from stdin. Returns {} on error or empty input. */
function readStdin() {
  try {
    const raw = fs.readFileSync(0, 'utf8');
    return raw.trim() ? JSON.parse(raw) : {};
  } catch {
    return {};
  }
}

/**
 * Walk up the directory tree from startDir looking for pubspec.yaml.
 * Returns the containing directory path, or null if not found within 6 levels.
 */
function findFlutterProjectRoot(startDir) {
  let dir = path.resolve(startDir || process.cwd());
  for (let i = 0; i < 6; i++) {
    if (fs.existsSync(path.join(dir, 'pubspec.yaml'))) return dir;
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  return null;
}

/**
 * Write a PreToolUse block response. Claude Code only processes JSON output
 * on exit 0, so blocking hooks must not return a generic non-zero status.
 */
function block(reason) {
  process.stdout.write(JSON.stringify({ decision: 'block', reason }) + '\n');
  process.exit(0);
}

/** Exit 0, allowing the tool call to proceed (PreToolUse). */
function allow() {
  process.exit(0);
}

/** Returns true if the given env var is set to "1". */
function shouldSkip(envVar) {
  return process.env[envVar] === '1';
}

/**
 * Run a command synchronously and return { exitCode, stdout, stderr, timedOut }.
 * Always uses shell:true so flutter/dart resolve on Windows (flutter.bat) and Unix alike.
 */
function runCmd(cmd, args, cwd, timeoutMs) {
  const result = spawnSync(cmd, args, {
    cwd: cwd || process.cwd(),
    timeout: timeoutMs || 30000,
    encoding: 'utf8',
    shell: true,
    maxBuffer: 10 * 1024 * 1024,
  });
  return {
    exitCode: result.status != null ? result.status : 1,
    stdout: (result.stdout || '').trim(),
    stderr: (result.stderr || '').trim(),
    timedOut: result.error != null && result.error.code === 'ETIMEDOUT',
  };
}

module.exports = { readStdin, findFlutterProjectRoot, block, allow, shouldSkip, runCmd };
