## 0.0.1 - 2024-08-16 19:43

* Connect to a Pusher server using WebSockets.
* Available for all platforms (Android, IOS, MacOS, WindowsOS, LinuxOS, Web).
* Subscribe to public, private, private encrypted, and presence channels.
* Bind event listeners to handle custom and Pusher-specific events.
* Automatic reconnection logic for handling connection interruptions.
* Activity check mechanism to ensure the connection remains active.

## 0.0.1+1 - 2024-08-16 21:04

* Handle `pusher_internal:` and `pusher:` events.
* Add `onSubscriptionSuccess` event for all channels.
* Upgrade `web_socket_client` to `^0.1.0`.
