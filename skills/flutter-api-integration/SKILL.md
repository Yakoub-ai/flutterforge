---
name: flutter-api-integration
version: 1.0.0
description: >-
  Implement API, backend, and data layer integrations in Flutter. Use when the
  user wants to connect a REST API, Firebase, or Supabase; design a repository
  layer; add JSON serialization; implement token refresh; or set up offline-first
  behavior. Trigger phrases: "integrate API Flutter", "connect Firebase",
  "add Supabase", "REST API Flutter", "HTTP client", "repository pattern Flutter",
  "JSON serialization Flutter", "Dio interceptor", "token refresh Flutter",
  "offline-first Flutter", "Firestore Flutter", "remote datasource".
---

# Flutter API Integration

Full data layer: REST APIs, Firebase, Supabase, JSON serialization, authentication, offline caching, and the repository pattern that keeps all of it testable.

**Guiding principle:** The UI layer never talks to a network. UI → providers → repositories → datasources → network.

---

## Workflow

1. **Inspect the backend before writing code** — query MCP tools first:
   - Firebase project: use `firebase` MCP (`firestore/listCollections`, `auth/listProviders`, `storage/listBuckets`, `functions/list`)
   - Supabase project: use `supabase` MCP (`list_tables`, `execute_sql` to validate queries)
   - If no live backend yet: document all schema assumptions in the feature spec before starting.
2. **Check current package versions** — query `context7` for current Dio, Firebase, or Supabase SDK docs before writing integration code (APIs change across major versions).
3. **Design the folder structure** — see `@references/feature-layer-template.md` for the canonical layout.
4. **Implement in order**: models/DTOs → datasource interface → datasource impl → repository interface → repository impl → provider/cubit.
5. **Map exceptions at the datasource boundary** — datasources throw `AppException`; repositories return `Either<Failure, T>`. See `@references/dart-error-mapping.md`.
6. **Add tests**: mock the datasource interface, never mock concrete `Dio` or `http.Client`.
7. **Validate**: `dart format .` + `flutter analyze` + `flutter test`.

---

## Integration Decision Rules

| Backend | Use when |
|---|---|
| REST + Dio | Custom backend, third-party APIs, full control over headers/interceptors |
| Firebase Auth + Firestore | Real-time data, Google ecosystem, fast MVP |
| Supabase | PostgreSQL-backed apps, open-source Firebase alternative |
| GraphQL | Complex relational data, bandwidth-critical apps |

**Token storage:** Always `flutter_secure_storage` for access/refresh tokens. Never `SharedPreferences` (unencrypted on Android).

**Offline-first cache policy:**
- `cache-then-network` — return cache immediately, update in background (best UX)
- `network-only` — always fresh, use for mutations
- `cache-only` — for offline mode toggle

---

## Dio Setup Checklist

- `BaseOptions` with `baseUrl`, `connectTimeout` (10 s), `receiveTimeout` (30 s)
- `AuthInterceptor` that attaches Bearer token and handles 401 → token refresh → retry
- `PrettyDioLogger` in debug mode only
- All `DioException` caught at datasource boundary, converted with `mapDioException()`

---

## JSON Serialization Rules

- Use `json_serializable` + `freezed` for all DTOs — never write `fromJson`/`toJson` manually.
- Add `toDomain()` extension on each DTO to convert to the domain entity (keeps domain layer free of serialization).
- Run codegen: `dart run build_runner build --delete-conflicting-outputs`.
- DTO fields: use `@JsonKey(name: 'snake_case')` when backend uses snake_case.

---

## Mocking Strategy for Tests

- Define datasources as abstract interfaces (`abstract interface class`).
- Use `mocktail` for mocks of the interface; never mock `Dio` directly.
- Use `FakeDatasource` implementations for complex scenarios.
- Define all mocks in `test/helpers/mocks.dart`.

---

## Security Rules

- Never hardcode API keys, base URLs, or secrets in Dart source.
- Use `const String.fromEnvironment('KEY')` passed via `--dart-define-from-file`.
- Add `.env`, `google-services.json`, `GoogleService-Info.plist` to `.gitignore`.
- Provide `.env.example` with placeholder values for onboarding.

---

## Output Artifacts

- `lib/core/network/dio_client.dart` — Dio factory with interceptors
- `lib/core/network/exception_mapper.dart` — DioException → AppException
- `lib/core/errors/failures.dart` — Failure sealed class hierarchy
- `lib/features/<feature>/data/models/` — DTOs
- `lib/features/<feature>/data/datasources/` — remote + local datasource interfaces and impls
- `lib/features/<feature>/data/repositories/` — repository implementations
- `test/features/<feature>/` — datasource and repository unit tests

---

## Cross-references

- Agent: `api-integration-engineer`
- See `@references/dart-error-mapping.md` for AppException hierarchy and DioException mapping
- See `@references/feature-layer-template.md` for full folder structure
- MCP tools: `firebase`, `supabase`, `context7`
