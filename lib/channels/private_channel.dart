import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/auth_data.dart';
import '../utils/member.dart';
import 'channel.dart';

/// Represents a private channel in Pusher.
class PrivateChannel extends Channel {
  PrivateChannel({
    required super.client,
    required super.name,
    super.subscribe,
  }) {
    onSubscriptionSuccess(_onSubscriptionSuccess);
    onSubscriptionCount(_onSubscriptionCount);
  }

  String? userId;

  /// The user member of the channel.
  Member? get member => userId != null ? Member(id: userId!) : null;

  AuthData? authData;

  /// Subscribes to the private channel.
  @override
  void subscribe([bool force = false]) async {
    if (!client.connected ||
        (subscribed && !force) ||
        client.socketId == null) {
      return;
    }

    subscribed = false;

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
      // try {
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
      // } catch (e) {
      //   handleEvent("pusher:error", e);
      // }
    } else {
      handleEvent(
        "pusher:error",
        "Unable to authenticate channel $name, status code: ${response.statusCode}",
      );
    }
  }

  void _onSubscriptionSuccess(data) {
    options.log("SUBSCRIPTION_SUCCESS", name, "data: $data");

    subscribed = true;
  }

  int _subscriptionCount = 0;

  /// The number of subscriptions to the channel.
  int get subscriptionCount => _subscriptionCount;

  void _onSubscriptionCount(data) {
    options.log("SUBSCRIPTION_COUNT", name, "data: $data");

    _subscriptionCount = data["subscription_count"];
  }

  /// Binding for the subscription count event.
  void onSubscriptionCount(Function listener) =>
      bind("pusher:subscription_count", listener);

  /// Send an event to the channel.
  void trigger(String event, [data]) {
    options.log("TRIGGER", name, "event: $event\n  data: $data");

    if (!event.startsWith("client-")) {
      event = "client-$event";
    }

    client.sendEvent(event, data, name);
  }
}
