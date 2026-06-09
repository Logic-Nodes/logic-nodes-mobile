sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
