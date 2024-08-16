/// Represents the protocol of a URL.
enum Protocol {
  /// The HTTP protocol.
  http,

  /// The HTTPS protocol.
  https,

  /// The WebSocket protocol.
  ws,

  /// The WebSocket Secure protocol.
  wss;

  /// Returns the string representation of the protocol.
  @override
  String toString() => {
        http: "http",
        https: "https",
        ws: "ws",
        wss: "wss",
      }[this]!;
}
