import 'dart:convert';

class ChannelData {
  /// The user id of the channel data.
  final String userId;

  /// The user info of the channel data.
  final dynamic userInfo;

  const ChannelData({required this.userId, this.userInfo = false});

  /// Creates a new instance from a json map.
  factory ChannelData.fromJson(Map json) => ChannelData(
        userId: json["user_id"] ?? '',
        userInfo: json["user_info"],
      );

  /// Creates a new instance from a json string.
  static ChannelData? fromJsonString(String jsonString) {
    dynamic json;
    try {
      json = jsonDecode(jsonString);
    } catch (e) {
      throw Exception(
        'Invalid channel_data json string "$jsonString", cannot decode json',
      );
    }

    if (json == null) return null;

    if (json is! Map) {
      throw Exception(
        "Invalid channel_data response data [$json], excepted Map got ${json.runtimeType}",
      );
    }

    return ChannelData.fromJson(json);
  }

  /// Converts the instance to a json map.
  Map<String, dynamic> toJson() => {
        "user_id": userId,
        "user_info": userInfo,
      };

  /// Converts the instance to a json string.
  String toJsonString() => jsonEncode(toJson());
}
