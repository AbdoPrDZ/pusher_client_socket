import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/member.dart';
import 'channel.dart';

class PrivateChannel extends Channel {
  PrivateChannel({required super.client, required super.name}) {
    onSubscriptionSuccess((data) => subscribed = true);
  }

  String? userId;

  Member? get me => userId != null ? Member(id: userId!) : null;

  AuthData? authData;

  @override
  void subscribe() async {
    if (subscribed) return;

    options.log("SUBSCRIBE", name);

    final payload = {
      "channel_name": name,
      "socket_id": client.socketId,
    };

    final response = await http.post(
      Uri.parse(authOptions.endpoint),
      body: payload,
      headers: authOptions.headers,
    );

    options.log(
      "AUTH_RESPONSE",
      name,
      "options: $authOptions\n  payload: $payload\n  response: ${response.body}",
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);

        if (data is! Map) {
          throw Exception(
            "Invalid auth response data [$data], excepted Map got ${data.runtimeType}",
          );
        } else if (!data.containsKey("auth")) {
          throw Exception(
            "Invalid auth response data [$data], auth key is missing",
          );
        }
        authData = AuthData.fromJson(data);
        userId = authData!.channelData?.userId;
        client.sendEvent("pusher:subscribe", {
          "channel": name,
          "auth": authData!.auth,
          "channel_data": authData!.channelData?.toJsonString(),
        });
      } catch (e) {
        handleEvent("pusher_internal:subscription_error", e);
      }
    } else {
      handleEvent(
        "pusher:subscription_error",
        {
          "body": response.body,
          "status": response.statusCode,
        },
      );
    }
  }

  void onSubscriptionSuccess(Function listener) =>
      bind("pusher_internal:subscription_succeeded", listener);

  void onSubscriptionError(Function listener) =>
      bind("pusher_internal:subscription_error", listener);

  void onUnsubscribed(Function listener) =>
      bind("pusher_internal:unsubscribed", listener);

  void trigger(String event, [data]) {
    options.log("TRIGGER", name, "event: $event\n  data: $data");

    if (!event.startsWith("client-")) {
      event = "client-$event";
    }

    client.sendEvent(event, data, name);
  }
}

class AuthData {
  final String auth;
  final ChannelData? channelData;
  final String? sharedSecret;

  AuthData({required this.auth, required this.channelData, this.sharedSecret});

  factory AuthData.fromJson(Map json) {
    return AuthData(
      auth: json["auth"],
      channelData: ChannelData.fromJsonString(json["channel_data"] ?? ''),
      sharedSecret: json["shared_secret"],
    );
  }
}

class ChannelData {
  final String userId;
  final bool userInfo;

  ChannelData({required this.userId, this.userInfo = false});

  factory ChannelData.fromJson(Map json) {
    return ChannelData(
      userId: json["user_id"],
      userInfo: json["user_info"] == true,
    );
  }

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

  Map<String, dynamic> toJson() => {
        "user_id": userId,
        "user_info": userInfo,
      };

  String toJsonString() => jsonEncode(toJson());
}
