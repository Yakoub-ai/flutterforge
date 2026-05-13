# FlutterForge Example Recipes

Practical, step-by-step walkthroughs showing how to use FlutterForge commands to build real Flutter apps from idea to release. Each recipe shows exact command syntax, what the agents return, and what decisions you make along the way.

## Recipes

| Recipe | Topic | Complexity |
|--------|-------|------------|
| [todo_app.md](./todo_app.md) | Simple CRUD to-do app with local storage (Hive/Isar) | Beginner |
| [firebase_auth_app.md](./firebase_auth_app.md) | Authentication with Firebase (email/password + Google Sign-In) and Riverpod | Intermediate |
| [ecommerce_app.md](./ecommerce_app.md) | Product catalog, cart, Stripe payments, and REST API integration | Advanced |
| [maps_upload_app.md](./maps_upload_app.md) | Google Maps, location services, and photo upload to Firebase Storage | Intermediate |

## How to Read These Recipes

Each recipe follows the same structure:

1. **What we're building** — a short description of the finished app
2. **Prerequisites** — what you need installed before starting
3. **Step-by-step workflow** — exact FlutterForge commands with expected outputs and decision points
4. **Tips** — gotchas and best practices for that app type

Commands are shown in backtick blocks exactly as you would type them into your terminal or Claude Code session. Agent outputs are described in prose — treat them as representative, not verbatim. Your agents may phrase things differently based on current model behavior.

## General Prerequisites

All recipes assume:
- Flutter SDK 3.19+ installed and on `PATH`
- Dart SDK on `PATH` (bundled with Flutter)
- FlutterForge plugin installed in Claude Code
- A code editor (VS Code with Flutter extension or Android Studio)
- Android emulator or iOS simulator available (or a physical device)
