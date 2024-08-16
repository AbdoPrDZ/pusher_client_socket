/// Represents the options for the authentication.
class PusherAuthOptions {
  /// The endpoint for the authentication.
  final String endpoint;

  /// The headers for the authentication (default: `{'Accept': 'application/json'}`).
  final Map<String, String> headers;

  const PusherAuthOptions(
    this.endpoint, {
    this.headers = const {
      'Accept': 'application/json',
    },
  });

  /// Returns a new [PusherAuthOptions] with the given endpoint.
  @override
  String toString() {
    return 'AuthOptions(endpoint: $endpoint, headers: $headers)';
  }
}
