import 'package:meta/meta.dart';

import '../src/events_listeners.collection.dart';
import '../pusher_client_socket.dart';

export 'private_channel.dart';
export 'private_encrypted_channel.dart';
export 'presence_channel.dart';

/// Represents a channel in Pusher.
class Channel {
  /// The pusher client.
  final PusherClient client;

  /// The name of the channel.
  final String name;

  Channel({required this.client, required this.name, bool subscribe = true}) {
    if (subscribe) this.subscribe();
  }

  /// The options of the client.
  PusherOptions get options => client.options;

  /// The authentication options of the client.
  PusherAuthOptions get authOptions => options.authOptions;

  bool _subscribed = false;

  /// Whether the channel is subscribed or not.
  bool get subscribed => _subscribed;

  /// Sets the value of the subscribed property.
  @protected
  set subscribed(bool value) {
    _subscribed = value;
  }

  /// Subscribes to the channel.
  void subscribe([bool force = false]) async {
    if (!client.connected || (subscribed && !force)) {
      return;
    }

    _subscribed = false;

    options.log("SUBSCRIBE", name);

    client.sendEvent("pusher:subscribe", {
      "channel": name,
    });

    _subscribed = true;
  }

  final _eventsListenersCollection = EventsListenersCollection();

  /// Binds a listener to an event.
  void bind(String event, Function listener) =>
      _eventsListenersCollection.bind(event, listener);

  /// Unbinds a listener from an event.
  void unbind(String event) => _eventsListenersCollection.unbindAll(event);

  /// Handles an event.
  void handleEvent(String event, dynamic data) {
    options.log("EVENT", name, "event: $event\n  data: $data");

    _eventsListenersCollection.handleEvent(event, data);
  }

  /// Unsubscribes from the channel.
  void unsubscribe() {
    client.sendEvent("pusher:unsubscribe", {"channel": name});
    _subscribed = false;
  }

  /// Binding for the subscription success event.
  void onSubscriptionSuccess(Function listener) =>
      bind("pusher:subscription_succeeded", listener);
}
