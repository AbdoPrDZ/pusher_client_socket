import '../pusher_client_socket.dart';
import '../utils/collection.dart';

class ChannelsCollection extends Collection<Channel> {
  final PusherClient client;

  ChannelsCollection(this.client);

  T channel<T extends Channel>(String channelName) {
    if (!contains(channelName)) {
      if (channelName.startsWith("private-encrypted-")) {
        channelName = channelName.replaceFirst("private-encrypted-", "");
        add(
          channelName,
          PrivateEncryptedChannel(client: client, name: channelName),
        );
      } else if (channelName.startsWith("private-")) {
        channelName = channelName.replaceFirst("private-", "");
        add(
          channelName,
          PrivateChannel(client: client, name: channelName),
        );
      } else if (channelName.startsWith("presence-")) {
        // channelName = channelName.replaceFirst("presence-", "");
        add(
          channelName,
          PresenceChannel(client: client, name: channelName),
        );
      } else {
        add(
          channelName,
          Channel(client: client, name: channelName),
        );
      }
    }

    return super.get(channelName)! as T;
  }

  @override
  void remove(String id) {
    get(id)?.unsubscribe();

    super.remove(id);
  }

  @override
  void clear() {
    all().forEach((channel) => channel.unsubscribe());

    super.clear();
  }
}
