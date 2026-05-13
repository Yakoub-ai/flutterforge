# Dart Error Mapping Reference

Canonical AppException hierarchy and DioException → AppException mapping for FlutterForge projects.
Skills and agents reference this instead of repeating it inline.

---

## AppException Hierarchy

```dart
// core/errors/app_exception.dart
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection.']);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException() : super('Session expired. Please sign in again.');
}

class ServerException extends AppException {
  const ServerException(super.message, {required this.statusCode});
  final int statusCode;
}

class CacheException extends AppException {
  const CacheException([super.message = 'Local data unavailable.']);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}
```

---

## DioException → AppException Mapping

Place this helper in `core/network/exception_mapper.dart`. Call it at every datasource boundary so repositories and above never see raw `DioException`.

```dart
AppException mapDioException(DioException e) => switch (e.type) {
  DioExceptionType.connectionTimeout ||
  DioExceptionType.receiveTimeout ||
  DioExceptionType.sendTimeout =>
    NetworkException('Request timed out. Check your connection.'),
  DioExceptionType.connectionError =>
    NetworkException('Cannot connect to the server.'),
  DioExceptionType.badResponse => switch (e.response?.statusCode) {
    401 => const UnauthorizedException(),
    int code => ServerException(
        e.response?.data?['message']?.toString() ?? 'Server error ($code)',
        statusCode: code,
      ),
    null => NetworkException('Empty server response'),
  },
  _ => NetworkException(e.message ?? 'Unknown network error'),
};
```

---

## Usage in Datasource

```dart
@override
Future<List<ProductModel>> fetchProducts() async {
  try {
    final response = await _dio.get('/products');
    return (response.data as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw mapDioException(e);   // convert here, never above
  }
}
```

---

## Usage in Repository

```dart
@override
Future<Either<Failure, List<Product>>> getProducts() async {
  try {
    final dtos = await _remote.fetchProducts();
    return Right(dtos.map((d) => d.toEntity()).toList());
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on UnauthorizedException {
    return const Left(AuthFailure());
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  }
}
```

---

## Failure Classes (Domain Layer)

```dart
// domain/errors/failures.dart
sealed class Failure {
  const Failure([this.message = '']);
  final String message;
}
class NetworkFailure extends Failure { const NetworkFailure([super.message]); }
class ServerFailure extends Failure  { const ServerFailure([super.message]); }
class AuthFailure extends Failure    { const AuthFailure([super.message = 'Unauthorized']); }
class CacheFailure extends Failure   { const CacheFailure([super.message]); }
```

---

## Security Rules for API Keys

- Use `const String.fromEnvironment('KEY')` with `--dart-define` or `--dart-define-from-file`.
- Store runtime tokens in `flutter_secure_storage`, never `SharedPreferences`.
- Add `.env`, `google-services.json`, `GoogleService-Info.plist` to `.gitignore`.
- Provide `.env.example` with placeholder values for new developer onboarding.
