---
name: flutter-performance
version: 1.0.0
description: >-
  Use this skill when the user wants to identify, measure, or fix Flutter
  performance issues. Trigger phrases: "optimize Flutter", "fix jank",
  "improve Flutter performance", "Flutter slow", "too many rebuilds", "Flutter
  memory leak", "app size Flutter", "Flutter profiling", "RepaintBoundary",
  "ListView builder", "startup time Flutter", "reduce widget rebuilds",
  "Flutter frame drops", "DevTools performance".
---

# Flutter Performance

Identify, measure, and fix Flutter performance issues: frame jank, widget
rebuilds, list performance, image loading, startup time, app size, and memory.

**Protocol:** measure first → identify bottleneck → apply smallest targeted fix
→ measure again. Never optimize code that has not been profiled.

---

## Target Metrics

- Frame render time: < 16ms (60 fps) or < 8ms (120 fps)
- Startup to first frame: < 2s on mid-range Android
- Memory: no sustained heap growth (no leak)
- Release APK size: < 15 MB for most apps

---

## Step 1: Measure in Profile Mode

Always profile in **profile mode** — debug mode is 2–5x slower due to assertions and observatory overhead.

```bash
flutter run --profile
dart devtools   # or VS Code: Flutter: Open DevTools
```

**Key DevTools panels:**
- **Performance** — frame chart (red bars > 16ms). UI thread = Dart jank; Raster thread = GPU/shader jank.
- **CPU Profiler** — flame chart shows which Dart functions consumed the most time.
- **Memory** — healthy app has sawtooth GC pattern; sustained growth = leak.
- **Widget Rebuild Stats** — Performance > Track Widget Rebuilds. Any widget rebuilding > 1×/frame without data change is a problem.

---

## Step 2: Widget Rebuild Analysis

| Cause | Fix |
|---|---|
| Missing `const` constructors | Add `const` to widgets with compile-time constant values — Flutter skips diffing them. `flutter analyze` flags all missing `const`. |
| `setState` too high in tree | Move state to the lowest widget that actually needs it. |
| Watching too broadly in Riverpod | Use `ref.watch(provider.select((s) => s.field))` — rebuilds only when that field changes. |
| Missing `RepaintBoundary` | Wrap animated widgets (Lottie, video, maps, custom painters) so siblings don't repaint. |
| `setState` driving animations | Use `AnimatedBuilder` or `ValueListenableBuilder` — scope rebuild to the animation subtree only. |

Enable the repaint rainbow in debug mode: `debugRepaintRainbowEnabled = true` in `main()`.

---

## Step 3: List Performance

- Always use `ListView.builder` — `ListView(children: [...])` builds all items immediately.
- Provide stable `key: ValueKey(item.id)` on list items.
- Use `CustomScrollView` + slivers for mixed layouts (AppBar + list + grid).
- Increase `cacheExtent` for smoother scrolling when items are cheap to build.
- Use `AutomaticKeepAliveClientMixin` sparingly for expensive items (video, maps) — increases memory.

---

## Step 4: Image Performance

- Always specify `width` and `height` — without them, Flutter must decode before layout, causing shift.
- Use `cached_network_image` for network images (caching + placeholder + error widget).
- Use `BoxFit.cover` for thumbnails and profile images — fastest, no transparent bars.
- Resize server-side via CDN transform (Cloudinary, Imgix, Supabase transform) — never serve 4K for a 120px thumbnail.
- `flutter_svg` rasterizes on the main thread for complex paths — prefer icon fonts or pre-rasterized PNGs for icons.

---

## Step 5: Startup Performance

Defer non-critical initialization until after the first frame:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initAnalytics();
    _initCrashReporting();
  });
}
```

Profile startup:
```bash
flutter run --trace-startup --profile
# Output: build/start_up_info.json — open in chrome://tracing
```

Keep `main.dart` imports minimal — every top-level import is eagerly evaluated at startup.

---

## Step 6: App Size

```bash
flutter build appbundle --analyze-size   # Android (Play Store)
flutter build apk --split-per-abi        # Split APK reduces download 30–50%
flutter build ipa --analyze-size         # iOS
```

`--analyze-size` generates a JSON file — open in DevTools App Size panel.

Reduction checklist:
- Remove unused `pubspec.yaml` dependencies.
- Compress PNG/JPEG assets to under 200 KB.
- Use vector graphics (SVG, icon font) for icons.
- Remove unused localization strings.
- Never disable `--obfuscate` on Android — it reduces size and hardens the binary.

---

## Step 7: Memory

**Close streams and controllers in `dispose()`:**
```dart
@override
void dispose() {
  _subscription.cancel();
  _controller.close();
  super.dispose();
}
```

In Riverpod providers, use `ref.onDispose(subscription.cancel)`.

**Paginate large data** — never hold unbounded lists in state. Use cursor-based pagination; keep current page + one buffer.

**Limit image cache:** `PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20;` (50 MB cap).

**Detecting leaks:** DevTools Memory → navigate through app → force GC → take heap snapshot → check if classes from closed screens still appear.

Common leak sources: `AnimationController` not disposed, `Timer` not cancelled, global `Map` cache without eviction.

---

## Measurement Format

Document before/after for every fix in `docs/quality/performance_review.md`:

```
## [Date] — [Issue description]
### Before: P99 frame time: Xms, memory peak: XMB
### Fix: [what was changed]
### After: P99 frame time: Xms, memory peak: XMB
```

---

## Cross-references

- Agent: `performance-engineer`
- Measurement: Flutter DevTools (built-in with `dart devtools`)
