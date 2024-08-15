import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:pinenacl/tweetnacl.dart';

import 'auth_options.dart';

class PusherOptions {
  final Protocol protocol;
  final String? host;
  final String key;
  final String? cluster;
  final int activityTimeout;
  final int pongTimeout;
  final Map<String, String> parameters;
  final AuthOptions authOptions;
  final bool enableLogging;
  final Map<String, dynamic> Function(
    Uint8List sharedSecret,
    Map<String, dynamic> data,
  )? channelDecryption;

  const PusherOptions({
    this.protocol = Protocol.ws,
    this.host,
    required this.key,
    this.cluster,
    this.activityTimeout = 120000,
    this.pongTimeout = 30000,
    required this.parameters,
    required this.authOptions,
    required this.enableLogging,
    this.channelDecryption,
  });

  String get url => "$protocol://$wsHost/app/$key?${[
        for (String key in parameters.keys) "$key=${parameters[key]}"
      ].join("&")}";

  String get wsHost => host != null
      ? host!
      : cluster != null
          ? 'ws-$cluster.pusher.com'
          : 'ws.pusher.com';

  log(String level, [String? channel, String? message]) {
    if (enableLogging) {
      dev.log([
        "[PUSHER_",
        if (channel != null) "CHANNEL_",
        "$level]",
        if (channel != null) "\n  channel: $channel",
        if (message != null) "\n  $message"
      ].join(""));
    }
  }

  Map<String, dynamic> decryptChannelData(
    Uint8List sharedSecret,
    Map<String, dynamic> data,
  ) =>
      (channelDecryption ?? _defaultChannelDecryptionHandler)(
        sharedSecret,
        data,
      );

  Map<String, dynamic> _defaultChannelDecryptionHandler(
    Uint8List sharedSecret,
    Map<String, dynamic> data,
  ) {
    if (!data.containsKey("ciphertext") || !data.containsKey("nonce")) {
      throw Exception(
        "Unexpected format for encrypted event, expected object with `ciphertext` and `nonce` fields, got: $data",
      );
    }

    // Decode the ciphertext and nonce
    final Uint8List cipherText = base64Decode(data["ciphertext"]);
    if (cipherText.length < TweetNaCl.overheadLength) {
      throw Exception("Empty or invalid ciphertext length");
    }

    final Uint8List nonce = base64Decode(data["nonce"]);
    if (nonce.length < TweetNaCl.nonceLength) {
      throw Exception("Invalid nonce length");
    }

    // Create an output buffer for the decrypted message
    final Uint8List decryptedData = Uint8List(
      (cipherText.length - TweetNaCl.overheadLength).toInt(),
    );

    // Decrypt the message using the shared secret
    final result = TweetNaCl.crypto_secretbox_open(
      decryptedData,
      cipherText,
      cipherText.length,
      nonce,
      sharedSecret,
    );

    // Convert the decrypted data to a String and parse it as JSON
    return jsonDecode(utf8.decode(result)) as Map<String, dynamic>;
  }
}

enum Protocol {
  http,
  https,
  ws,
  wss;

  @override
  String toString() => {
        http: "http",
        https: "https",
        ws: "ws",
        wss: "wss",
      }[this]!;
}
