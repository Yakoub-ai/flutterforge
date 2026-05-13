# State Management Snippets

Canonical Riverpod and Bloc/Cubit patterns for FlutterForge projects.
Skills and agents reference this instead of repeating code inline.

---

## Riverpod

### Setup

```yaml
dependencies:
  flutter_riverpod: ^2.x   # check pub-dev MCP for current version
  riverpod_annotation: ^2.x

dev_dependencies:
  riverpod_generator: ^2.x
  build_runner: ^2.x
```

Wrap `MaterialApp` with `ProviderScope` in `main.dart`.

### AsyncNotifierProvider (async data)

```dart
// controller
@riverpod
class ProductsController extends _$ProductsController {
  @override
  Future<List<Product>> build() async {
    return ref.read(productRepositoryProvider).getProducts().then(
          (either) => either.fold((f) => throw Exception(f.message), (v) => v),
        );
  }

  Future<void> refresh() => ref.refresh(productsControllerProvider.future);
}

// widget
class ProductsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productsControllerProvider);
    return state.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(productsControllerProvider.future)),
      data: (products) => products.isEmpty
          ? const EmptyStateView(message: 'No products yet')
          : ProductList(products: products),
    );
  }
}
```

### NotifierProvider (sync/simple state)

```dart
@riverpod
class CartController extends _$CartController {
  @override
  List<CartItem> build() => [];

  void add(Product product) => state = [...state, CartItem(product: product)];
  void remove(String id) => state = state.where((i) => i.product.id != id).toList();
}
```

### Anti-patterns to avoid

- Do NOT call `ref.read(provider)` inside `build()` — use `ref.watch()`.
- Do NOT `.watch()` a provider only to read it once — use `ref.read()` in callbacks.
- Do NOT expose mutable state directly — expose through typed state classes.
- Do NOT use `StateProvider` for complex state — use `Notifier` instead.

---

## Bloc / Cubit

### Setup

```yaml
dependencies:
  flutter_bloc: ^8.x   # check pub-dev MCP for current version
  bloc: ^8.x
  equatable: ^2.x
```

### Cubit (simpler — recommended for most cases)

```dart
// State
@immutable
sealed class ProductsState {}
class ProductsInitial extends ProductsState {}
class ProductsLoading extends ProductsState {}
class ProductsLoaded extends ProductsState {
  const ProductsLoaded(this.products);
  final List<Product> products;
}
class ProductsError extends ProductsState {
  const ProductsError(this.message);
  final String message;
}

// Cubit
class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit(this._repository) : super(ProductsInitial());
  final ProductRepository _repository;

  Future<void> load() async {
    emit(ProductsLoading());
    final result = await _repository.getProducts();
    result.fold(
      (failure) => emit(ProductsError(failure.message)),
      (products) => emit(ProductsLoaded(products)),
    );
  }
}

// Widget
class ProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, state) => switch (state) {
        ProductsLoading() => const LoadingIndicator(),
        ProductsError(:final message) => ErrorView(message: message,
            onRetry: () => context.read<ProductsCubit>().load()),
        ProductsLoaded(:final products) => ProductList(products: products),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
```

### Bloc (for complex event-driven flows)

Use Bloc (vs Cubit) when:
- You need an audit trail of events for debugging.
- Multiple events can produce the same state change (e.g., refresh, pull-to-refresh, filter).
- You want to transform event streams (debounce, switchMap).

### Anti-patterns to avoid

- Do NOT put business logic in `BlocBuilder` — keep it in the Cubit/Bloc.
- Do NOT call `context.read<Cubit>().method()` inside `build()` — use `BlocListener` for side effects.
- Do NOT extend `Equatable` on states with `List` fields without overriding `props` correctly.

---

## Simple Local State

When state is confined to one widget and doesn't need cross-screen sharing:

```dart
class CounterWidget extends StatefulWidget { ... }
class _CounterWidgetState extends State<CounterWidget> {
  int _count = 0;
  @override
  Widget build(BuildContext context) => Column(children: [
    Text('$_count'),
    ElevatedButton(onPressed: () => setState(() => _count++), child: const Text('+')),
  ]);
}
```

Or with `ValueNotifier` + `ValueListenableBuilder` for reactive updates without `setState`.
