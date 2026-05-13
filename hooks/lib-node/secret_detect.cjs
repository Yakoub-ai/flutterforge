'use strict';
// secret_detect.cjs
// Triggered: PreToolUse on Write|Edit|Bash
// Scans file content (Write/Edit) or bash command (Bash) for high-confidence secrets.
// Blocks the tool call if a secret pattern is detected.
//
// Env vars:
//   FLUTTERFORGE_SKIP_SECRET_CHECK=1  bypass all checks

const path = require('path');
const { readStdin, block, allow, shouldSkip } = require('./_common.cjs');

if (shouldSkip('FLUTTERFORGE_SKIP_SECRET_CHECK')) allow();

// Secret patterns: regex must match within a single line
const PATTERNS = [
  { name: 'Google API key',          re: /AIza[0-9A-Za-z\-_]{35}/ },
  { name: 'Google OAuth token',      re: /ya29\.[0-9A-Za-z\-_]+/ },
  { name: 'FCM server key',          re: /AAAA[A-Za-z0-9_-]{7}:[A-Za-z0-9_-]{140}/ },
  { name: 'OpenAI API key',          re: /sk-[a-zA-Z0-9]{48}/ },
  { name: 'Anthropic API key',       re: /sk-ant-[a-zA-Z0-9_-]{60,120}/ },
  { name: 'Secret assignment',       re: /[sS][eE][cC][rR][eE][tT]\s*[=:]\s*['"][^'"]{8,}['"]/ },
  { name: 'Hardcoded password',      re: /password\s*[=:]\s*['"][^'"]{4,}['"]/ },
  { name: 'Firebase service account',re: /"type"\s*:\s*"service_account"/ },
];

// Lines containing these strings are considered safe (placeholders / examples)
const ALLOWLIST = /test_key|example_token|FAKE_|YOUR_|<YOUR_|xxx|dummy|placeholder/i;

function scanLines(content, source) {
  if (!content) return;
  const lines = content.split('\n');

  for (const { name, re } of PATTERNS) {
    for (const line of lines) {
      if (re.test(line) && !ALLOWLIST.test(line)) {
        block(
          `FlutterForge: Possible secret detected in ${source}.\n` +
          `Pattern matched: ${name}\n` +
          `Secrets must not be committed. Store them in the platform keychain or a local .env file.\n` +
          `To bypass this check: set FLUTTERFORGE_SKIP_SECRET_CHECK=1`
        );
      }
    }
  }

  // Private key: flag only when BOTH the identifier and a PEM header are present
  if (/private_key/i.test(content) && content.includes('-----BEGIN')) {
    const matchLine = lines.find((l) => /private_key/i.test(l)) || '';
    if (!ALLOWLIST.test(matchLine)) {
      block(
        `FlutterForge: Possible private key detected in ${source}.\n` +
        `Found 'private_key' alongside a PEM header.\n` +
        `To bypass: set FLUTTERFORGE_SKIP_SECRET_CHECK=1`
      );
    }
  }
}

const input = readStdin();
const toolName = input.tool_name || '';
const ti = input.tool_input || {};

if (toolName === 'Write') {
  const filePath = ti.file_path || '';
  // Block writes to bare .env files (not templates like .env.example)
  if (path.basename(filePath) === '.env') {
    block(
      `FlutterForge: Refusing to write a bare .env file.\n` +
      `Committed .env files leak secrets. Use .env.example for templates.\n` +
      `To bypass: set FLUTTERFORGE_SKIP_SECRET_CHECK=1`
    );
  }
  scanLines(ti.content || '', path.basename(filePath) || 'file');

} else if (toolName === 'Edit') {
  scanLines(ti.new_string || '', path.basename(ti.file_path || 'file'));

} else if (toolName === 'MultiEdit') {
  const fileName = path.basename(ti.file_path || 'file');
  for (const edit of ti.edits || []) {
    scanLines(edit.new_string || '', fileName);
  }

} else if (toolName === 'Bash') {
  // Scan the shell command for embedded secrets (export KEY=..., heredoc, curl -H, etc.)
  scanLines(ti.command || '', 'bash command');
}

allow();
