---
name: flutter-testing
version: 1.0.0
description: >-
  Use this skill when the user wants to write, generate, or improve Flutter
  tests at any level. Trigger phrases: "write Flutter tests", "generate tests",
  "widget test Flutter", "unit test Dart", "integration test Flutter", "golden
  test", "test coverage Flutter", "bloc_test", "ProviderContainer test",
  "mock repository", "test a screen", "add tests for this feature".
---

# Flutter Testing

Write and maintain Flutter tests at the right level: unit tests for business
logic, widget tests for screens and components, integration tests for critical
flows, and golden tests for visual regression.

---

## Test Pyramid

```
        [Integration Tests]  — critical end-to-end flows; device/emulator required; CI on merge only
          [Widget Tests]  — screens, components, interactions; run every commit
            [Unit Tests]  — business logic, providers, cubits, utilities; run every commit
```

Target distribution: 70%+ unit | 20–25% widget | 5–10% integration.

---

## Setup

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
  bloc_test: ^9.1.0
  network_image_mock: ^2.1.0
```

---

## Unit Tests

**What to test:** use cases, repository impls, Riverpod notifiers, Cubit/Bloc, validators, parsers, mappers, utilities.

**Do NOT test:** `*.g.dart` / `*.freezed.dart`, simple value objects with no logic, framework widgets (Text, Container), layout-only build methods.

Structure:
```dart
void main() {
  late MockProductRepository mockRepository;
  late GetProducts useCase;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = GetProducts(mockRepository);
  });

  group('GetProducts', () {
    test('returns list on success', () async {
      when(() => mockRepository.getProducts()).thenAnswer((_) async => fakeProducts);
      expect(await useCase.execute(), equals(fakeProducts));
    });
    test('propagates exception', () {
      when(() => mockRepository.getProducts()).thenThrow(const NetworkException('No connection'));
      expect(useCase.execute(), throwsA(isA<NetworkException>()));
    });
  });
}
```

**Riverpod notifier tests:** use `ProviderContainer` with `overrideWithValue`. Always call `addTearDown(container.dispose)`.

**Bloc/Cubit tests:** use `bloc_test` `blocTest<Cubit, State>()` with `build`, `act`, `expect`, and optional `verify`.

See `@references/state-management-snippets.md` for full Riverpod and `bloc_test` examples.

---

## Widget Tests

**Minimum per screen:** test all four states — loading, success, error, empty.

Also test: user interactions (tap, scroll, form input), navigation triggers, complex reusable components.

**Riverpod widget test:**
```dart
testWidgets('shows product list on success', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [productsNotifierProvider.overrideWith(() => FakeProductsNotifier())],
      child: const MaterialApp(home: ProductsScreen()),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text(fakeProducts.first.name), findsOneWidget);
});
```

For loading state: use `tester.pump()` (one frame), NOT `pumpAndSettle` — the latter waits until animation completes and may wait forever.

**Bloc widget test:** wrap with `BlocProvider<Cubit>.value(value: mockCubit)` and use `whenListen` from `bloc_test`.

**Finder priority** (most to least stable):
1. `find.byKey(const Key('widget-id'))` — survives text changes
2. `find.byType(MyWidget)` — stable for design system components
3. `find.text('Submit')` — fragile if copy changes

Always add `Key` to dynamically generated list items:
```dart
ListView.builder(
  itemBuilder: (context, i) => ProductTile(key: ValueKey(products[i].id), product: products[i]),
)
```

---

## Integration Tests

```dart
// integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('sign in and navigate to home', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('email-field')), 'test@example.com');
    await tester.tap(find.byKey(const Key('sign-in-button')));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
```

Rules:
- Use a dedicated test environment (staging Firebase / mock backend).
- Keep count small — integration tests are 10–100x slower than widget tests.
- Test only critical paths that widget tests cannot cover.
- Run in CI on merge to main only.

---

## Golden Tests

Catch unintended visual regressions in design system components and critical screens.

```dart
testWidgets('PrimaryButton matches golden — default', (tester) async {
  await tester.pumpWidget(/* MaterialApp > Scaffold > Center > PrimaryButton */);
  await expectLater(find.byType(PrimaryButton), matchesGoldenFile('goldens/primary_button_default.png'));
});
```

Update after intentional design changes: `flutter test --update-goldens`

Test at multiple device sizes by setting `tester.view.physicalSize` before pumping. Cover: all design system components, critical screens at phone/tablet breakpoints, dark vs. light mode.

---

## CI Commands

```bash
flutter test                            # unit + widget
flutter test --coverage                 # with coverage
genhtml coverage/lcov.info -o coverage/html
flutter test integration_test/ -d <device>
flutter test --update-goldens
flutter test --name "pattern"           # filter by test name
```

**Coverage targets:**
- Domain (use cases, entities): 90%+
- Data (repositories, datasources): 80%+
- Presentation (notifiers, cubits): 80%+
- UI widgets: covered by widget tests, not line coverage

---

## Cross-references

- Code examples: `@references/state-management-snippets.md` (Riverpod + Bloc test patterns)
- Agent: `flutter-test-engineer`
- Error types: `@references/dart-error-mapping.md`
