# LSP Integration in FlutterForge

FlutterForge uses the term "LSP-guided" in several commands and skills. This document
explains what that means, what it requires from your environment, and how to set up the
Dart Analysis Server for both VS Code and JetBrains IDEs.

---

## Plugin LSP Server

FlutterForge ships `.lsp.json` with a Dart language-server definition:

```bash
dart language-server --protocol=lsp
```

Claude Code can use this server when plugin LSP support is enabled. If the CLI cannot start
the server, FlutterForge still falls back to the grep/analyze workflow below.

---

## What "LSP-Guided" Means in FlutterForge

FlutterForge commands still treat LSP as an assistive signal, not the only source of truth.
Commands like `/flutterforge:refactor-flutter` instruct Claude to combine Dart LSP diagnostics
with the conservative fallback workflow an IDE rename or find-references operation would use:

1. **Grep/Glob for all call sites** — Claude searches `.dart` files for every reference
   to the symbol being changed: direct calls, type annotations, string literals in routes
   or reflection, dynamic imports, and test mocks.
2. **Produce an atomic change plan** — all affected files are listed before any edit
   is made, matching what an LSP batch-rename would guarantee.
3. **Apply changes in dependency order** — declarations first, then call sites, then
   tests — so the codebase is never left in a broken intermediate state.
4. **Re-run `flutter analyze`** — after edits, the analysis server is invoked in batch
   mode to confirm no residual type errors or unresolved references remain.

The fallback approach cannot match a live LSP's symbol index for very large monorepos, but it
covers the common cases (renaming a widget, extracting a method, moving a file) reliably.

---

## Dart Analysis Server

The Dart Analysis Server is the reference implementation of the Dart LSP. It ships with
the Dart SDK, which is bundled with Flutter — you already have it if Flutter is installed.

### Batch mode via `flutter analyze`

Running `flutter analyze` invokes the analysis server in batch mode and exits with a
non-zero code if there are any errors or warnings. FlutterForge's hooks use this as the
"LSP diagnostics" equivalent in CI:

```bash
# Equivalent to an LSP "get diagnostics for all files" call
flutter analyze --no-pub
```

The hook `hooks/lib-node/post_edit_analyze.cjs` runs this automatically after every file edit
when `FLUTTERFORGE_AUTO_ANALYZE=1` is set.
The script `scripts/flutter_analyze.sh` runs the same check standalone.

Output format: `severity • message • file_path:line:column`, which Claude parses to
locate and fix remaining errors without manual intervention.

---

## VS Code Setup

Install the **Dart** extension to get a full LSP integration:

- Extension ID: `dart-code.dart-code`
- Marketplace: https://marketplace.visualstudio.com/items?itemName=Dart-Code.dart-code

The extension starts a persistent Dart Analysis Server for your workspace and surfaces
diagnostics, completions, go-to-definition, find-references, and rename in the editor.
FlutterForge's simulate-and-verify approach and your IDE's live LSP work in parallel —
FlutterForge edits are validated by the IDE's analysis server in real time.

**Recommended VS Code settings** for Flutter projects:

```jsonc
// .vscode/settings.json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.lineLength": 120,
  "editor.formatOnSave": true,
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code"
  }
}
```

---

## JetBrains Setup (IntelliJ IDEA / Android Studio)

Install the **Dart** plugin:

- Plugin: `Dart` (bundled in Android Studio, available in IntelliJ IDEA via
  Settings → Plugins → Marketplace → search "Dart")
- The Flutter plugin (`io.flutter`) depends on it and installs it automatically.

The JetBrains Dart plugin also connects to the Dart Analysis Server via LSP. Rename
refactoring, find-usages, and diagnostics in the editor use the same underlying server
that `flutter analyze` does on the command line.

---

## Enabling the LSP for Custom Tooling

If you are building an editor integration or a custom tool that needs the Dart LSP
directly (not through VS Code or JetBrains), the Dart SDK ships an `analysis_server`
executable that speaks LSP over stdio:

```bash
dart language-server --protocol=lsp
```

Official documentation: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/tool/lsp_spec/README.md

This is the entry point used by both the VS Code Dart extension and the JetBrains Dart
plugin under the hood.

---

## Summary: How FlutterForge Uses LSP Semantics

| LSP capability       | FlutterForge equivalent                                         |
|----------------------|-----------------------------------------------------------------|
| Find references      | Grep over `.dart` files with symbol name and type context       |
| Rename symbol        | `/flutterforge:refactor-flutter` — grep, plan, atomic multi-file edit        |
| Get diagnostics      | `flutter analyze` output parsed by `post_edit_analyze.cjs`      |
| Go to definition     | Glob to locate the declaring file, then Read                    |
| Format document      | `dart format` via `post_edit_format.cjs` hook                   |

Full IDE-level LSP support requires the Dart Analysis Server running in your editor —
FlutterForge's simulation is a practical approximation for agent-driven workflows.
