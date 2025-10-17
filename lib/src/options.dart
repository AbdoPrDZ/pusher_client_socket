import 'dart:convert';
import 'dart:developer' as dev;

import 'package:pinenacl/api.dart';
import 'package:pinenacl/x25519.dart' show SecretBox;

import 'auth_options.dart';

export 'auth_options.dart';

/// Represents the options of the Pusher client.
class PusherOptions {
  /// The key of the connection.
  final String key;

  //// The host of the connection.
  final String? host;

  /// The ws port of the connection (default: 80).
  final int wsPort;

  /// The wss port of the connection (default: 443).
  final int wssPort;

  /// Enable encryption for the connection.
  final bool encrypted;

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

  /// The maximum reconnection attempts.
  final int maxReconnectionAttempts;

  /// The reconnection duration.
  final Duration reconnectGap;

  /// The channel decryption handler.
  final Map<String, dynamic> Function(Uint8List sharedSecret, Map<String, dynamic> data)? channelDecryption;

  const PusherOptions({
    required this.key,
    this.cluster,
    this.host,
    this.wsPort = 80,
    this.wssPort = 443,
    this.encrypted = true,
    this.activityTimeout = 120000,
    this.pongTimeout = 30000,
    this.parameters = const {
      'client': 'pusher-client-socket-dart',
      'protocol': '7',
      'version': '0.0.2',
      "flash": "false",
    },
    required this.authOptions,
    this.enableLogging = false,
    this.autoConnect = true,
    this.maxReconnectionAttempts = 6,
    this.reconnectGap = const Duration(seconds: 2),
    this.channelDecryption,
  });

  Uri get uri {
    Uri? hostUri;
    try {
      hostUri = Uri.parse(host!);
      if (hostUri.scheme.isEmpty) {
        hostUri = Uri.parse('${encrypted ? 'wss' : 'ws'}://$host');
      }
    } catch (e) {
      dev.log("Invalid host: $host", error: e);
      // fallback nếu muốn
      hostUri = Uri(
        scheme: encrypted ? 'wss' : 'ws',
        host: cluster != null ? 'ws-$cluster.pusher.com' : 'ws.pusher.com',
        port: encrypted ? wssPort : wsPort,
      );
    }

    Uri finalUri = Uri(
      scheme: hostUri.scheme,
      host: hostUri.host,
      port: hostUri.hasPort ? hostUri.port : (encrypted ? wssPort : wsPort),
      queryParameters: {...parameters, if (hostUri.hasQuery) ...hostUri.queryParameters},
      path: '/app/$key',
    );
    return finalUri;
  }

  log(String level, [String? channel, String? message]) {
    if (enableLogging) {
      dev.log(
        [
          "[PUSHER_",
          if (channel != null) "CHANNEL_",
          "$level]",
          if (channel != null) "\n  channel: $channel",
          if (message != null) "\n  $message",
        ].join(""),
      );
    }
  }

  ByteList _decodeCipherText(String cipherText) {
    Uint8List uint8list = base64Decode(cipherText);
    ByteData byteData = ByteData.sublistView(uint8list);
    List<int> data = List<int>.generate(byteData.lengthInBytes, (index) => byteData.getUint8(index));
    return ByteList(data);
  }

  Map<String, dynamic> decryptChannelData(Uint8List sharedSecret, Map<String, dynamic> data) =>
      (channelDecryption ?? defaultChannelDecryptionHandler)(sharedSecret, data);

  Map<String, dynamic> defaultChannelDecryptionHandler(Uint8List sharedSecret, Map<String, dynamic> data) {
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
