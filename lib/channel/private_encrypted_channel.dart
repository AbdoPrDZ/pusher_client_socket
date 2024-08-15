import 'dart:convert';
import 'dart:typed_data';
import 'private_channel.dart';

class PrivateEncryptedChannel extends PrivateChannel {
  PrivateEncryptedChannel({required super.client, required super.name});

  Map<String, dynamic> decrypt(Map<String, dynamic> data) {
    if (sharedSecret == null) {
      throw Exception("SharedSecret is missing in the auth data");
    }

    return client.options!.decryptChannelData(sharedSecret!, data);
  }

  Uint8List? get sharedSecret => authData?.channelData != null
      ? base64Decode(authData!.sharedSecret!)
      : null;

  @override
  void handleEvent(String event, [data]) {
    options.log("EVENT", name, "event: $event\n  data: $data");

    Map<String, dynamic>? decryptedData;

    try {
      decryptedData = decrypt(data as Map<String, dynamic>);
    } catch (e) {
      options.log("ERROR", name, "Failed to decrypt event data: $e");
      return;
    }

    super.handleEvent(event, decryptedData);
  }

  @override
  void trigger(String event, [data]) {
    throw Exception("Cannot trigger events on an encrypted channel");
  }
}
