class AuthOptions {
  final String endpoint;
  final Map<String, String> headers;

  const AuthOptions(
    this.endpoint, {
    this.headers = const {},
  });

  @override
  String toString() {
    return 'AuthOptions(endpoint: $endpoint, headers: $headers)';
  }
}
