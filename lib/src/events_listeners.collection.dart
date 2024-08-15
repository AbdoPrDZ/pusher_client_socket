import '../utils/collection.dart';

class EventsListenersCollection extends Collection<List<Function>> {
  void bind(String event, Function listener) {
    add(event, []);
    final listeners = get(event)!;
    if (!listeners.contains(listener)) listeners.add(listener);
  }

  void unbind(String event, Function listener) {
    final listeners = get(event);
    if (listeners != null && listeners.contains(listener)) {
      listeners.remove(listener);
    }
  }

  void unbindAll(String event) => remove(event);

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
