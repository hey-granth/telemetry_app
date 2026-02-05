/// Result type for error handling.
///
/// Provides a functional approach to error handling without exceptions.
/// Inspired by Rust's Result type.
sealed class Result<T, E> {
  const Result();

  /// Check if result is success
  bool get isSuccess => this is Success<T, E>;

  /// Check if result is failure
  bool get isFailure => this is Failure<T, E>;

  /// Get value if success, null otherwise
  T? get valueOrNull => switch (this) {
        Success(value: final v) => v,
        Failure() => null,
      };

  /// Get error if failure, null otherwise
  E? get errorOrNull => switch (this) {
        Success() => null,
        Failure(error: final e) => e,
      };

  /// Map success value to a new type
  Result<U, E> map<U>(U Function(T value) transform) => switch (this) {
        Success(value: final v) => Success(transform(v)),
        Failure(error: final e) => Failure(e),
      };

  /// Map error to a new type
  Result<T, F> mapError<F>(F Function(E error) transform) => switch (this) {
        Success(value: final v) => Success(v),
        Failure(error: final e) => Failure(transform(e)),
      };

  /// Chain operations that may fail
  Result<U, E> flatMap<U>(Result<U, E> Function(T value) transform) =>
      switch (this) {
        Success(value: final v) => transform(v),
        Failure(error: final e) => Failure(e),
      };

  /// Get value or provide default
  T getOrElse(T Function() defaultValue) => switch (this) {
        Success(value: final v) => v,
        Failure() => defaultValue(),
      };

  /// Get value or throw error
  T getOrThrow() => switch (this) {
        Success(value: final v) => v,
        Failure(error: final e) => throw e as Object,
      };

  /// Pattern match on result
  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  }) =>
      switch (this) {
        Success(value: final v) => success(v),
        Failure(error: final e) => failure(e),
      };
}

/// Success case of Result
class Success<T, E> extends Result<T, E> {
  const Success(this.value);
  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Success<T, E> && other.value == value);

  @override
  int get hashCode => value.hashCode;
}

/// Failure case of Result
class Failure<T, E> extends Result<T, E> {
  const Failure(this.error);
  final E error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Failure<T, E> && other.error == error);

  @override
  int get hashCode => error.hashCode;
}
