class AuthRevokedException implements Exception {
  const AuthRevokedException();

  @override
  String toString() => 'AuthRevokedException: session revoked mid-flight';
}
