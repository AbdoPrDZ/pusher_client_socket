# Pusher Client Socket

A Dart library for connecting to a Pusher server using WebSockets. This library provides an easy-to-use API for subscribing to channels, binding event listeners, and sending events to the server.

## Features

- Connect to a Pusher server using WebSockets.
- Available for all platforms (Android, IOS, MacOS, WindowsOS, LinuxOS, Web).
- Subscribe to public, private, private encrypted, and presence channels.
- Bind event listeners to handle custom and Pusher-specific events.
- Automatic reconnection logic for handling connection interruptions.
- Activity check mechanism to ensure the connection remains active.

## Installation

Add the following dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  pusher_client_socket: ^0.0.1
```

Then run:

```shell
flutter pub get
```

or using `pub add`:

```shell
flutter pub add pusher_client_socket
```

## Usage

### 2. Import

```dart
/// Import the pusher client
import 'package:pusher_client_socket/pusher_client_socket.dart';

/// Importing the channels
import 'package:pusher_client_socket/channels/channel.dart';
import 'package:pusher_client_socket/channels/private_channel.dart';
import 'package:pusher_client_socket/channels/private_encrypted_channel.dart';
import 'package:pusher_client_socket/channels/presence_channel.dart';
```

### 2. Initialize the connection options

1. Pusher default server:

    ```dart
    final options = PusherOptions(
      key: 'PUSHER-KEY',
      cluster: 'mt1',
      authOptions: PusherAuthOptions(
        endpoint: 'http://localhost/broadcasting/auth',
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer AUTH-TOKEN'
        }
      ),
      autoConnect: false,
    );
    ```

2. Specify server (e.g: Laravel/Reverb):

    ```dart
    final options = PusherOptions(
      protocol: Protocol.ws, // REVERB_SCHEME
      host: 'localhost:6001', // '$REVERB_HOST:REVERB_PORT'
      key: 'REVERB_APP_KEY',
      authOptions: PusherAuthOptions(
        endpoint: 'http://localhost/broadcasting/auth',
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer AUTH-TOKEN'
        }
      ),
      autoConnect: false,
    );
    ```

### 3. Initialize the client and connect

```dart
final pusherClient = PusherClient(options);
pusherClient.onConnectionEstablished((data) {
  print("Connection established - socket-id: ${pusherClient.socketId}");
});
pusherClient.onConnectionError((error) {
  print("Connection error - $error");
});
pusherClient.onError((error) {
  print("Error - $error");
});
pusherClient.onDisconnected((data) {
  print("Disconnected - $data");
});
pusherClient.connect();
```

### 4. Subscribe to channels

```dart
/// Subscribe to public channel
final publicChannel = pusherClient.channel('channel-1');

/// Subscribe to private channel
final privateChannel = pusherClient.channel('private-channel-2');
// or
final privateChannel = pusherClient.private('channel-2');

/// Subscribe to private encrypted channel
final privateEncryptedChannel = pusherClient.channel('private-encrypted-channel-3');
// or
final privateEncryptedChannel = pusherClient.privateEncrypted('channel-3');

/// Subscribe to presence channel
final presenceChannel = pusherClient.channel("presence-channel-4");
// or
final presenceChannel = pusherClient.presence("channel-4");
```

### 5. Listening to event

```dart
channel.bind('EventName', (data) {
  print('event received - EventName - $data');
});
```

### 6. Send trigger (in private or presence channel)

```dart
privateChannel.trigger('client-EventName', data);
// or
privateChannel.trigger('EventName', data);
// or
presenceChannel.trigger('client-EventName', data);
// or
presenceChannel.trigger('EventName', data);
```


### 7. Unsubscribing from channel

```dart
channel.unsubscribe();
```


## Pusher Client Options

| Option              | Type                  | Description |
| ------------------- | --------------------- | ----------- |
| `protocol`          | `Protocol`            | The protocol to use for the connection, Default is `ws`. |
| `host`              | `String?`             | The custom host for the connection. If not provided, it defaults to the Pusher WebSocket host based on the cluster. |
| `key`               | `String`              | The Pusher app key used to authenticate the connection. This is a required parameter. |
| `cluster`           | `String?`             | The cluster of the Pusher server. If provided, it is used to construct the default WebSocket host. |
| `activityTimeout`   | `int`                 | The activity timeout in milliseconds. This is the duration after which a ping is sent if no activity is detected. Default is 120000 (2 minutes). |
| `pongTimeout`       | `int`                 | The timeout in milliseconds for waiting for a pong response after a ping is sent. Default is 30000 (30 seconds). |
| `parameters`        | `Map<String, String>` | Additional parameters to be appended to the WebSocket URL query string. |
| `authOptions`       | `PusherAuthOptions`   | The options for authentication, such as headers or credentials. This is required for authenticating private and presence channels. |
| `enableLogging`     | `bool`                | A flag indicating whether to enable logging for the Pusher client. Default is `false`. |
| `autoConnect`       | `bool`                | A flag indicating whether to automatically connect to the Pusher server upon initialization. Default is `true`. |
| `channelDecryption` | `Map<String, dynamic> Function(Uint8List sharedSecret, Map<String, dynamic> data)?` | A custom handler for decrypting data on encrypted channels. If not provided, the default decryption handler is used. |

## Pusher Auth Options


| Option     | Type                  | Description |
| ---------- | --------------------- | ----------- |
| `endpoint` | `String`              | The endpoint for the authentication. |
| `headers`  | `Map<String, String>` | The headers for the authentication (default: `{'Accept': 'application/json'}`). |


## Contributing

Contributions are welcome! Please open an issue or submit a pull request on GitHub.

## License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/AbdoPrDZ/pusher_client_socket/blob/main/LICENSE) file for details.