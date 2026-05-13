# Feature Layer Template

Reference for the canonical data → domain → presentation layer structure used by FlutterForge.
Skills and agents point here instead of repeating this inline.

---

## Folder Structure

```
lib/features/<feature>/
├── data/
│   ├── datasources/
│   │   ├── <feature>_remote_datasource.dart        # abstract interface
│   │   └── <feature>_remote_datasource_impl.dart   # Dio/Firebase/Supabase impl
│   ├── models/
│   │   └── <entity>_model.dart                     # freezed + json_serializable DTO
│   └── repositories/
│       └── <feature>_repository_impl.dart          # implements domain interface
├── domain/
│   ├── entities/
│   │   └── <entity>.dart                           # pure Dart, no Flutter, no JSON
│   ├── repositories/
│   │   └── <feature>_repository.dart               # abstract interface
│   └── usecases/
│       └── <verb>_<entity>.dart                    # one class per use case
└── presentation/
    ├── controllers/
    │   └── <feature>_controller.dart               # Riverpod Notifier or Bloc/Cubit
    ├── pages/
    │   └── <feature>_page.dart                     # ConsumerWidget / BlocBuilder
    └── widgets/
        └── <feature>_<widget_name>.dart            # extracted sub-widgets

test/features/<feature>/
├── data/repositories/<feature>_repository_impl_test.dart
├── domain/usecases/<verb>_<entity>_test.dart
└── presentation/pages/<feature>_page_test.dart
```

---

## Data Layer Patterns

**DTO (freezed + json_serializable):**
```dart
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    @JsonKey(name: 'display_name') required String displayName,
  }) = _UserModel;
  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}
extension UserModelX on UserModel {
  User toEntity() => User(id: id, email: email, displayName: displayName);
}
```

**Repository Implementation (Either pattern):**
```dart
class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<Either<Failure, User>> signIn({required String email, required String password}) async {
    try {
      final model = await _remote.signIn(email: email, password: password);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return Left(const NetworkFailure());
    }
  }
}
```

---

## Domain Layer Patterns

**Entity (pure Dart):**
```dart
@freezed
class User with _$User {
  const factory User({required String id, required String email, required String displayName}) = _User;
}
```

**Use Case (single responsibility):**
```dart
class SignIn {
  SignIn({required this.repository});
  final AuthRepository repository;
  Future<Either<Failure, User>> call({required String email, required String password}) =>
      repository.signIn(email: email, password: password);
}
```

---

## Presentation Layer Patterns

**Riverpod Controller:**
```dart
@riverpod
class AuthController extends _$AuthController {
  @override
  AuthState build() => const AuthState.initial();
  Future<void> signIn({required String email, required String password}) async {
    state = const AuthState.loading();
    final result = await ref.read(signInProvider).call(email: email, password: password);
    state = result.fold(
      (failure) => AuthState.error(failure.message),
      (user) => AuthState.authenticated(user),
    );
  }
}
```

**Page (no business logic):**
```dart
class LoginPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    ref.listen<AuthState>(authControllerProvider, (_, next) {
      next.whenOrNull(
        authenticated: (_) => context.go(AppRoutes.home),
        error: (msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))),
      );
    });
    return Scaffold(body: state.maybeWhen(
      loading: () => const LoadingIndicator(),
      orElse: () => LoginForm(onSubmit: (e, p) => ref.read(authControllerProvider.notifier).signIn(email: e, password: p)),
    ));
  }
}
```

---

## File Naming Conventions

- DTOs: `*_model.dart` or `*_dto.dart`
- Entities: plain noun, `user.dart`, `product.dart`
- Use cases: verb + noun, `sign_in.dart`, `fetch_products.dart`
- Controllers: `*_controller.dart` (Riverpod) or `*_cubit.dart` (Bloc)
- Pages: `*_page.dart`
- Sub-widgets: `*_card.dart`, `*_form.dart`, `*_list_item.dart`
