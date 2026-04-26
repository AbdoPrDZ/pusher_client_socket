import 'channel_data.dart';

class AuthData {
  /// The authentication token.
  final String auth;

  /// The channel data (parsed).
  final ChannelData? channelData;

  /// The raw channel_data string exactly as returned by the auth endpoint.
  /// Must be sent verbatim in the pusher:subscribe event so the HMAC
  /// signature stays valid (PHP escapes "/" as "\/" but Dart does not).
  final String? rawChannelData;

  /// The shared secret for encrypted channels.
  final String? sharedSecret;

  const AuthData({
    required this.auth,
    required this.channelData,
    this.rawChannelData,
    this.sharedSecret,
  });

  /// Creates a new instance from a json map.
  factory AuthData.fromJson(Map json) => AuthData(
        auth: json["auth"] ?? '',
        channelData: json["channel_data"] != null
            ? ChannelData.fromJsonString(json["channel_data"])
            : null,
        rawChannelData: json["channel_data"],
        sharedSecret: json["shared_secret"],
      );
}
