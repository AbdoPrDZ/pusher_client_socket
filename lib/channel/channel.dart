import 'package:meta/meta.dart';

import '../src/auth_options.dart';
import '../src/events_listeners.collection.dart';
import '../src/options.dart';
import '../pusher_client_socket.dart';

export 'private_channel.dart';
export 'private_encrypted_channel.dart';
export 'presence_channel.dart';

class Channel {
  final PusherClient client;
  final String name;

  Channel({
    required this.client,
    required this.name,
  });

  PusherOptions get options => client.options!;
  AuthOptions get authOptions => options.authOptions;

  bool _subscribed = false;
  bool get subscribed => _subscribed;

  @protected
  set subscribed(bool value) {
    _subscribed = value;
  }

  void subscribe() async {
    if (subscribed) {
      return;
    }

    options.log("SUBSCRIBE", name);

    client.sendEvent("pusher:subscribe", {
      "channel": name,
    });

    _subscribed = true;
  }

  final _eventsListenersCollection = EventsListenersCollection();

  void bind(String event, Function listener) {
    _eventsListenersCollection.bind(event, listener);
  }

  void unbind(String event) {
    _eventsListenersCollection.unbindAll(event);
  }

  void handleEvent(String event, dynamic data) {
    options.log("EVENT", name, "event: $event\n  data: $data");

    _eventsListenersCollection.handleEvent(event, data);
  }

  void unsubscribe() {
    client.sendEvent("pusher:unsubscribe", {"channel": name});
    _subscribed = false;
  }
}
