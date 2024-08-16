import '../utils/collection.dart';

/// Represents a collection of events listeners in Pusher.
class EventsListenersCollection extends Collection<List<Function>> {
  /// Binds a listener to an event.
  void bind(String event, Function listener) {
    add(event, []);
    final listeners = get(event)!;
    if (!listeners.contains(listener)) listeners.add(listener);
  }

  /// Unbinds a listener from an event.
  void unbind(String event, Function listener) {
    final listeners = get(event);
    if (listeners != null && listeners.contains(listener)) {
      listeners.remove(listener);
    }
  }

  /// Unbinds all listeners from an event.
  void unbindAll(String event) => remove(event);

  /// Handling an event.
  void handleEvent(String event, dynamic data, [String? channel]) {
    if (contains(event)) {
      for (final listener in get(event)!) {
        if (channel == null) {
          listener(data);
        } else {
          listener(data, channel);
        }
      }
    }

    if (contains("*")) {
      for (final listener in get("*")!) {
        listener({
          "event": event,
          "data": data,
          if (channel != null) "channel": channel,
        });
      }
    }
  }
}
