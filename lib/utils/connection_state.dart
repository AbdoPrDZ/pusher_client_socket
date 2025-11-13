import 'package:web_socket_client/web_socket_client.dart';

extension ConnectionStateNames on ConnectionState {
  bool get isConnected => this is Connected || this is Reconnected;
  bool get isDisconnected => this is Disconnected;
  bool get isConnecting => this is Connecting;
  bool get isReconnecting => this is Reconnecting;
  bool get isReconnected => this is Reconnected;
  bool get isDisconnecting => this is Disconnecting;

  /// Returns a readable name for the connection state.
  String get name {
    // Provide a readable name and additional details for Disconnected
    if (this is Disconnected) {
      final state = this as Disconnected;
      final args = [
        if (state.code != null) "code: ${state.code}",
        if (state.reason != null && state.reason!.isNotEmpty)
          "reason: ${state.reason}",
        if (state.error != null) "error: ${state.error}",
      ].join(", ");
      return 'DISCONNECTED${args.isNotEmpty ? '($args)' : ''}';
    }

    if (this is Connecting) return 'CONNECTING';
    if (this is Connected) return 'CONNECTED';
    if (this is Reconnecting) return 'RECONNECTING';
    if (this is Reconnected) return 'RECONNECTED';
    if (this is Disconnecting) return 'DISCONNECTING';

    return runtimeType.toString().toUpperCase();
  }
}
