/// Minimal Result type so feature controllers can surface API failures to
/// the UI without throwing across layers. Kept tiny on purpose — this is
/// not meant to grow into a full functional-programming layer, just to
/// avoid sprinkling try/catch through every widget.
sealed class Result<T> {
  const Result();

  factory Result.ok(T value) = Ok<T>;
  factory Result.error(String message) = Err<T>;

  R when<R>({
    required R Function(T value) ok,
    required R Function(String message) error,
  }) {
    final self = this;
    if (self is Ok<T>) return ok(self.value);
    if (self is Err<T>) return error(self.message);
    throw StateError('unreachable');
  }
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

class Err<T> extends Result<T> {
  final String message;
  const Err(this.message);
}
