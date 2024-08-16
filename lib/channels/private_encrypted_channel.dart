import 'dart:convert';
import 'dart:typed_data';
import 'private_channel.dart';

/// Represents a private encrypted channel.
class PrivateEncryptedChannel extends PrivateChannel {
  PrivateEncryptedChannel({
    required super.client,
    required super.name,
    super.subscribe,
  });

  Map<String, dynamic> _decrypt(Map<String, dynamic> data) {
    if (sharedSecret == null) {
      throw Exception("SharedSecret is missing in the auth data");
    }

    return client.options.decryptChannelData(sharedSecret!, data);
  }

  /// The shared secret for the encrypted channel.
  Uint8List? get sharedSecret => authData?.sharedSecret != null
      ? base64Decode(authData!.sharedSecret!)
      : null;

  /// Handles the event by decrypting the data before passing it to the event
  @override
  void handleEvent(String event, [data]) {
    if (data is Map && !event.startsWith("pusher:")) {
      try {
        data = _decrypt(data as Map<String, dynamic>);
      } catch (e) {
        options.log("ERROR", name, "Failed to decrypt event data: $e");
        return;
      }
    }

    super.handleEvent(event, data);
  }

  /// Triggers an event on the channel (Disabled for encrypted channels)
  @override
  void trigger(String event, [data]) {
    throw Exception("Cannot trigger events on an encrypted channel");
  }
}
