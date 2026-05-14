# Contributing to FlutterForge

FlutterForge is a Claude Code plugin. Contributions are welcome — skills, agents, commands, hook improvements, bug reports, and documentation.

## Repository Layout

```
flutterforge/
├── .claude-plugin/plugin.json   # Plugin manifest — update when adding command/agent paths or component dirs
├── skills.sh                    # Portable installer for skills/agents outside Claude Code
├── commands/                    # Slash commands (flat — one .md per command)
├── agents/                      # Specialized agents (flat — one .md per agent)
├── skills/                      # Reusable skills (one folder per skill)
├── hooks/                       # Quality hooks and lib scripts
├── templates/                   # Document templates for user projects
├── scripts/                     # Shell scripts called by commands
├── examples/                    # Markdown recipe walkthroughs
├── mcp-servers/                 # MCP integration docs
├── lsp/                         # LSP setup guidance
└── monitors/                    # Runtime monitoring docs (forward-looking)
```

## Adding a Skill

1. Create `skills/<your-skill-name>/SKILL.md`
2. Add YAML frontmatter:
   ```yaml
   ---
   name: your-skill-name
   description: >-
     Use this skill when the user wants to [action]. Trigger phrases:
     "do X", "help with Y", "improve Z in a Flutter project".
   version: 1.0.0
   ---
   ```
3. Write the skill body: workflow steps, rules, output format
4. Test by invoking the skill description phrase in a Flutter project context

No per-skill changes to `plugin.json` are needed — the manifest points at `./skills/`.
Run `bash skills.sh list` after adding a skill to confirm it is exportable for other CLIs.

## Adding an Agent

1. Create `agents/<agent-name>.md`
2. Add YAML frontmatter:
   ```yaml
   ---
   name: agent-name
   description: |
     Use this agent when [trigger]. Examples:
     <example>
     Context: [situation]
     user: "[typical user message]"
     assistant: "I'll use the agent-name agent to..."
     <commentary>Why this agent applies</commentary>
     </example>
   model: sonnet
   color: blue
   tools: ["Read", "Glob", "Grep", "Bash", "Write", "Edit", "Task"]
   ---
   ```
3. Write the agent system prompt
4. Add the agent path to `plugin.json` `agents[]` array
5. Run `bash skills.sh list` to confirm the agent is exportable for other CLIs

## Adding a Command

1. Create `commands/<command-name>.md`
2. Add YAML frontmatter:
   ```yaml
   ---
   description: One-line description shown in /help
   argument-hint: <required-arg> [optional-arg]
   allowed-tools: ["Read", "Glob", "Grep", "Bash", "Task", "Write", "Edit", "TodoWrite"]
   ---
   ```
3. Write the orchestration body using the phased subagent dispatch pattern:
   - Numbered phases
   - Each phase instructs Claude to dispatch N agents via the Task tool
   - Include inline agent briefing templates
4. Add the command path to `plugin.json` `commands[]` array

The command name becomes `/flutterforge:<command-name>` (no nested folders).

## Subagent Dispatch Pattern

FlutterForge commands orchestrate agents rather than doing work inline. Follow this pattern:

```markdown
## Phase N: [Goal]

Launch [N] agents in parallel using the Task tool in a single message:

**Agent 1 — [agent-name]:**
Prompt the agent with:
- Role: [what it does]
- Context: [what to tell it — paste inline, never reference a file]
- Scope: [boundaries]
- Output format: [what you need back]

After agents return, [what to do with results].
```

## Hook Scripts

Hook scripts must:
- Source `${CLAUDE_PLUGIN_ROOT}/hooks/lib/flutter_guard.sh` before any `flutter` or `dart` command
- Exit 0 silently when `pubspec.yaml` is not found (no-op in non-Flutter repos)
- Only block on confirmed quality failures, never on transient errors

## Commit Convention

```
feat: add flutter-localization skill
fix: flutter_guard.sh false-positive on monorepos
docs: expand flutter-architecture SKILL.md with Bloc examples
chore: bump version to 0.2.0
```

## Reporting Issues

Open an issue at https://github.com/Yakoub-ai/flutterforge/issues with:
- FlutterForge version
- The command or skill that misbehaved
- What you expected vs. what happened
- Flutter/Dart version if relevant
