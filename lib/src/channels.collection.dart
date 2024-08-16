import '../pusher_client_socket.dart';
import '../utils/collection.dart';

/// Represents a collection of channels in Pusher.
class ChannelsCollection extends Collection<Channel> {
  /// The pusher client.
  final PusherClient client;

  ChannelsCollection(this.client);

  /// Gets a channel by its name (Create it if not exists).
  T channel<T extends Channel>(String channelName, {bool subscribe = false}) {
    if (!contains(channelName)) {
      if (channelName.startsWith("private-encrypted-")) {
        add(
          channelName,
          PrivateEncryptedChannel(
            client: client,
            name: channelName,
            subscribe: subscribe,
          ),
        );
      } else if (channelName.startsWith("private-")) {
        add(
          channelName,
          PrivateChannel(
            client: client,
            name: channelName,
            subscribe: subscribe,
          ),
        );
      } else if (channelName.startsWith("presence-")) {
        add(
          channelName,
          PresenceChannel(
            client: client,
            name: channelName,
            subscribe: subscribe,
          ),
        );
      } else {
        add(
          channelName,
          Channel(client: client, name: channelName, subscribe: subscribe),
        );
      }
    }

    return super.get(channelName)! as T;
  }

  /// Removes a channel by its name.
  @override
  void remove(String id) {
    get(id)?.unsubscribe();

    super.remove(id);
  }

  /// Unsubscribes from all channels.
  @override
  void clear() {
    forEach((channel) => channel.unsubscribe());

    super.clear();
  }
}
