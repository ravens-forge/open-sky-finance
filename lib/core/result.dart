/// Outcome of an operation that can fail in an expected way.
///
/// [E] is an error code (an enum or a sealed class declared by the service), never
/// user-facing text: the UI maps it to an ARB message.
///
/// ```dart
/// switch (result) {
///   case Ok(:final value): ...
///   case Err(:final error): ...
/// }
/// ```
sealed class Result<T, E extends Object> {
  const Result();
}

final class Ok<T, E extends Object> extends Result<T, E> {
  const Ok(this.value);

  final T value;
}

final class Err<T, E extends Object> extends Result<T, E> {
  const Err(this.error);

  final E error;
}

/// Failures any screen can show; services declare their own codes for the rest.
enum AppError { loadFailed, saveFailed, invalidAmount }
