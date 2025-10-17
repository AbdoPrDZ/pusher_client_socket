## 0.0.5 - 2025-03-27

- Upgrade flutter sdk version.

## 0.0.4 - 2025-02-23

- merge commit [Close and reset web_socket connection](https://github.com/usmanabdulmajid/pusher_client_socket/commit/13d978fa2d11b4bbe82ea57bbb8a62415905bb3f)
- merge commit [Update connected to true when Connection state is Reconnected](https://github.com/usmanabdulmajid/pusher_client_socket/commit/df108910f1839642ab14e5fec0497507a65ea086)
- Upgrade flutter sdk version.

## 0.0.3+1 - 2025-01-02

- Upgrade flutter sdk version.

## 0.0.3 - 2024-11-04 20:25

- Add members getter variable in presence channel.

## 0.0.2+7 - 2024-11-04 18:16

- Fix channels subscribe & unsubscribe.
- Fix client reconnect error.

## 0.0.2+6 - 2024-11-01 20:17

- Fix Member add and member remove functions.

## 0.0.2+5 - 2024-11-01 19:52

- Fix Member fromMap function.

## 0.0.2+4 - 2024-11-01 14:52

- Upgrade flutter sdk version.

## 0.0.2+3 - 2024-10-26 17:24

- Upgrade sdk version.
- Upgrade packages versions.

## 0.0.2+2 - 2024-09-27 17:06

- Bug Fix: the remove function of the Collection class doesn't remove a channel from the collections because the condition to check if the channel id exist was wrong.

## 0.0.2+1 - 2024-09-03 20:34

- Upgrade flutter sdk.

## 0.0.2 - 2024-08-17 14:09

- Remove `protocol` parameter from `PusherOptions`.
- Add `wsPort` parameter to `PusherOptions`.
- Add `wssPort` parameter to `PusherOptions`.
- Add `encrypted` parameter to `PusherOptions`.
- Add `maxReconnectionAttempts` parameter to `PusherOptions`.
- Add `reconnectGap` parameter to `PusherOptions`.
- Improve websocket connection uri generator.

## 0.0.1+1 - 2024-08-16 21:04

- Handle `pusher_internal:` and `pusher:` events.
- Add `onSubscriptionSuccess` event for all channels.
- Upgrade `web_socket_client` to `^0.1.0`.

## 0.0.1 - 2024-08-16 19:43

- Connect to a Pusher server using WebSockets.
- Available for all platforms (Android, IOS, MacOS, WindowsOS, LinuxOS, Web).
- Subscribe to public, private, private encrypted, and presence channels.
- Bind event listeners to handle custom and Pusher-specific events.
- Automatic reconnection logic for handling connection interruptions.
- Activity check mechanism to ensure the connection remains active.
