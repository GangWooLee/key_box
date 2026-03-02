/// A simple Result type for service operations.
/// Mirrors the Rails `Result = Struct.new(:success?, :data, :errors)` pattern.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;

  @override
  String toString() => 'Success($data)';
}

final class Failure<T> extends Result<T> {
  const Failure(this.message, {this.errors = const []});
  final String message;
  final List<String> errors;

  @override
  String toString() => 'Failure($message, errors: $errors)';
}
