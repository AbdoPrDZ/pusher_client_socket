import 'dart:convert';
import 'dart:developer' as dev;

import 'package:pinenacl/api.dart';
import 'package:pinenacl/x25519.dart' show SecretBox;

import '../utils/protocol.dart';
import 'auth_options.dart';

export 'auth_options.dart';
export '../utils/protocol.dart';

/// Represents the options of the Pusher client.
class PusherOptions {
  /// The protocol to use for the connection.
  final Protocol protocol;

  //// The host of the connection.
  final String? host;

  /// The key of the connection.
  final String key;

  /// The cluster of the connection.
  final String? cluster;

  /// The activity timeout of the connection (default: 120000).
  final int activityTimeout;

  /// The pong timeout of the connection (default: 30000).
  final int pongTimeout;

  /// The parameters of the connection.
  final Map<String, String> parameters;

  /// The authentication options of the connection.
  final PusherAuthOptions authOptions;

  /// Whether to enable logging or not.
  final bool enableLogging;

  /// Whether to auto connect or not.
  final bool autoConnect;

  /// The channel decryption handler.
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
    this.parameters = const {},
    required this.authOptions,
    this.enableLogging = false,
    this.autoConnect = true,
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

  ByteList _decodeCipherText(String cipherText) {
    Uint8List uint8list = base64Decode(cipherText);
    ByteData byteData = ByteData.sublistView(uint8list);
    List<int> data = List<int>.generate(
        byteData.lengthInBytes, (index) => byteData.getUint8(index));
    return ByteList(data);
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

    final ByteList cipherText = _decodeCipherText(data["ciphertext"]);

    final Uint8List nonce = base64Decode(data["nonce"]);

    final SecretBox secretBox = SecretBox(sharedSecret);
    final Uint8List decryptedData = secretBox.decrypt(cipherText, nonce: nonce);

    return jsonDecode(utf8.decode(decryptedData)) as Map<String, dynamic>;
  }
}
