## 0.0.1 - 2024-08-16 19:43

- Connect to a Pusher server using WebSockets.
- Available for all platforms (Android, IOS, MacOS, WindowsOS, LinuxOS, Web).
- Subscribe to public, private, private encrypted, and presence channels.
- Bind event listeners to handle custom and Pusher-specific events.
- Automatic reconnection logic for handling connection interruptions.
- Activity check mechanism to ensure the connection remains active.

## 0.0.1+1 - 2024-08-16 21:04

- Handle `pusher_internal:` and `pusher:` events.
- Add `onSubscriptionSuccess` event for all channels.
- Upgrade `web_socket_client` to `^0.1.0`.

## 0.0.2 - 2024-08-17 14:09

- Remove `protocol` parameter from `PusherOptions`.
- Add `wsPort` parameter to `PusherOptions`.
- Add `wssPort` parameter to `PusherOptions`.
- Add `encrypted` parameter to `PusherOptions`.
- Add `maxReconnectionAttempts` parameter to `PusherOptions`.
- Add `reconnectGap` parameter to `PusherOptions`.
- Improve websocket connection uri generator.

## 0.0.2+1 - 2024-09-03 20:34

- Upgrade flutter sdk.

## 0.0.2+2 - 2024-09-27 17:06

- Bug Fix: the remove function of the Collection class doesn't remove a channel from the collections because the condition to check if the channel id exist was wrong.
