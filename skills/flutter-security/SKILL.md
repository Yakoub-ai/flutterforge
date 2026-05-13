---
name: flutter-security
version: 1.0.0
description: >-
  Audit and harden security in Flutter apps. Use when the user wants a security
  review, secrets detection, token storage audit, permissions review, or OWASP
  Mobile Top 10 check.
  Trigger phrases: "security review Flutter", "check secrets Flutter", "Flutter security
  audit", "secure token storage", "app permissions Flutter", "harden Flutter app",
  "sensitive data Flutter", "OWASP Flutter", "API key Flutter", "secure storage Flutter",
  "certificate pinning Flutter", "obfuscate Flutter", "Flutter HTTPS".
---

# Flutter Security

Audit and harden Flutter app security. Coverage: OWASP Mobile Top 10, secrets detection, secure storage, network security, binary protection, and privacy controls.

---

## Workflow

1. **Run secrets detection scan** (Phase 1 — highest severity, must be clean before continuing).
2. **Audit token and data storage**.
3. **Review network security configuration**.
4. **Check permissions** (AndroidManifest + Info.plist).
5. **Verify authentication and authorization flows**.
6. **Review binary protection settings**.
7. **Write `docs/quality/security_review.md`** with findings by severity.

---

## Phase 1: Secrets Detection

Check `lib/` for hardcoded secrets. Any finding here is a blocker.

```bash
grep -rn "AIza"          lib/    # Google / Firebase API keys
grep -rn "sk-"           lib/    # OpenAI / Anthropic keys
grep -rn "sk-ant-"       lib/    # Anthropic specifically
grep -rn "AAAA"          lib/    # FCM legacy server keys
grep -rn "private_key"   lib/    # Firebase service account
grep -rn "password\s*="  lib/    # Hardcoded passwords
grep -rn "Bearer\s"      lib/    # Hardcoded auth headers
grep -rn "AKIA"          lib/    # AWS access keys
```

Also check: `assets/`, `android/`, `ios/` for accidentally committed JSON credentials.

---

## Security Checklist

### Secrets Management
- [ ] No hardcoded API keys, tokens, or passwords in any Dart file
- [ ] Using `const String.fromEnvironment('KEY')` with `--dart-define-from-file`
- [ ] `.env`, `google-services.json`, `GoogleService-Info.plist` in `.gitignore`
- [ ] `.env.example` with placeholder values for developer onboarding

### Token Storage
- [ ] Access and refresh tokens in `flutter_secure_storage` (AES-encrypted on Android, Keychain on iOS)
- [ ] No tokens in `SharedPreferences` (plaintext on Android)
- [ ] Token wipe on sign-out — verify `secureStorage.deleteAll()` is called

### Network Security
- [ ] All endpoints use HTTPS — no HTTP in production
- [ ] Certificate pinning implemented for high-security apps (`dio_pinning` or native)
- [ ] No custom `badCertificateCallback` returning `true` in production code
- [ ] API base URL in env config, not hardcoded
- [ ] DioException always caught — no unhandled network failures

### Android Specific
- [ ] `android:debuggable="false"` in release `AndroidManifest.xml` (or relying on build type)
- [ ] Network Security Config (`res/xml/network_security_config.xml`) restricts HTTP traffic
- [ ] Permissions use `maxSdkVersion` where applicable
- [ ] No unnecessary permissions declared

### iOS Specific
- [ ] `NSAllowsArbitraryLoads` is `false` in `Info.plist` (ATS enabled)
- [ ] Sensitive data not stored in `NSUserDefaults` (equivalent of SharedPreferences)
- [ ] Permission usage strings are honest — app rejection risk if vague
- [ ] Keychain sharing entitlement only if required

### Authentication / Authorization
- [ ] Backend enforces authorization — client-side checks are UX only
- [ ] Session expiry handled — 401 triggers token refresh, then re-auth if refresh fails
- [ ] Deep link validation — external URLs verified before navigation
- [ ] WebView content validated — no loading arbitrary user-supplied URLs

### Data Handling
- [ ] No PII logged via `debugPrint`, `print`, or analytics in production
- [ ] Clipboard not populated with sensitive data without user consent
- [ ] Screenshot prevention configured for screens with sensitive data (if required)

### Binary Protection
- [ ] Dart code obfuscation enabled for release: `flutter build appbundle --obfuscate --split-debug-info=.`
- [ ] Root/jailbreak detection implemented for high-security apps (`root_checker`, `flutter_jailbreak_detection`)
- [ ] Debug mode checks removed from release builds

---

## Required Security Behaviors

- **ALWAYS** warn before allowing any secret to be written to source code.
- **ALWAYS** recommend `flutter_secure_storage` for any credential storage.
- **NEVER** generate code that stores auth tokens in SharedPreferences.
- **NEVER** generate code that passes credentials in query string parameters.
- **ALWAYS** recommend backend-side enforcement for any sensitive authorization logic.

---

## Output Artifacts

- `docs/quality/security_review.md` — findings by severity (blocker / high / medium / low)

---

## Cross-references

- Agent: `mobile-security-reviewer`
- Secret detection hook: `hooks/lib-node/secret_detect.cjs` (runs automatically on every write)
