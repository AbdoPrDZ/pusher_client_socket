import 'channel_data.dart';

class AuthData {
  /// The authentication token.
  final String auth;

  /// The channel data.
  final ChannelData? channelData;

  /// The shared secret for encrypted channels.
  final String? sharedSecret;

  const AuthData({
    required this.auth,
    required this.channelData,
    this.sharedSecret,
  });

  /// Creates a new instance from a json map.
  factory AuthData.fromJson(Map json) => AuthData(
        auth: json["auth"] ?? '',
        channelData: json["channel_data"] != null
            ? ChannelData.fromJsonString(json["channel_data"])
            : null,
        sharedSecret: json["shared_secret"],
      );
}
