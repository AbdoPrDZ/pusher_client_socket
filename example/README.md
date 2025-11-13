# Pusher Client Socket Example

This example demonstrates how to use the `pusher_client_socket` package in a Flutter application. It provides a comprehensive demo of connecting to a Pusher server, subscribing to different types of channels, and sending/receiving messages.

## Features Demonstrated

- **Connection Management**: Connect and disconnect from Pusher server with proper error handling
- **Configuration Panel**: Easily configure connection parameters (host, port, key, authentication)
- **Multiple Channel Types**: Support for public, private, private encrypted, and presence channels
- **Real-time Messaging**: Send and receive messages with live updates
- **Error Handling**: Comprehensive error handling and user feedback
- **Input Validation**: Validation for all user inputs
- **Modern UI**: Clean, Material Design 3 interface with proper loading states

## Setup Instructions

### 1. Prerequisites

Before running this example, you need:

- A Pusher account or a compatible WebSocket server (like Laravel Reverb)
- An authentication endpoint that returns channel authorization

### 2. Configuration

Update the constants at the top of `lib/main.dart` with your actual values:

```dart
const String DEFAULT_TOKEN = "YOUR_AUTH_TOKEN";
const String DEFAULT_KEY = "YOUR_PUSHER_APP_KEY";
const String DEFAULT_HOST = "your-server-host"; // e.g., "localhost" or "your-domain.com"
const int DEFAULT_PORT = 6001; // Your WebSocket port
const String DEFAULT_AUTH_ENDPOINT = "https://your-domain.com/api/broadcasting/auth";
```

### 3. Authentication Endpoint

Your authentication endpoint should:

- Accept POST requests
- Validate the Bearer token in the Authorization header
- Return channel authorization data for private/presence channels

Example Laravel endpoint response:
```json
{
  "auth": "app_key:signature",
  "channel_data": "{\"user_id\":1,\"user_info\":{\"name\":\"John Doe\"}}"
}
```

### 4. Running the Example

```bash
cd example
flutter pub get
flutter run
```

## How to Use

### 1. Configure Connection

- Open the Configuration panel (expanded by default)
- Enter your authentication token, Pusher app key, host, port, and auth endpoint
- The token should be a valid Bearer token that your server accepts

### 2. Connect to Pusher

- Click the "Connect" button
- If successful, you'll see a green status with your Socket ID
- Any connection errors will be displayed in red

### 3. Subscribe to a Channel

- Select the channel type (public, private, private encrypted, or presence)
- Enter the channel name (without the type prefix - it will be added automatically)
- Click "Subscribe"
- Successful subscription will show a confirmation message

### 4. Send Messages

- Once subscribed to a channel, the messaging panel will appear
- Type your message and click "Send" or press Enter
- Messages from other clients will appear automatically
- System messages (connection status, errors) are displayed in gray

## Channel Types

### Public Channels
- No authentication required
- Anyone can subscribe
- Use for public broadcasts

### Private Channels
- Require authentication
- Server validates subscription request
- Use for user-specific or restricted content

### Private Encrypted Channels
- Same as private channels but with end-to-end encryption
- Messages are encrypted/decrypted automatically
- Use for sensitive data

### Presence Channels
- Include user presence information
- See who's online in the channel
- Receive join/leave notifications
- Use for chat rooms, collaborative features

## Troubleshooting

### Connection Issues

1. **Authentication Errors**: 
   - Verify your token is valid and not expired
   - Check your authentication endpoint is working
   - Ensure proper CORS headers if connecting from web

2. **Connection Timeouts**:
   - Verify host and port are correct
   - Check if the server is running and accessible
   - Try with different network connection

3. **Subscription Errors**:
   - Ensure channel name format is correct
   - For private/presence channels, verify authentication endpoint
   - Check server logs for authorization errors

### Common Error Messages

- **"Token cannot be empty"**: Enter a valid authentication token
- **"Connection Error: WebSocket connection failed"**: Check host/port configuration
- **"Subscription Error: 401"**: Authentication failed, check token and auth endpoint
- **"Failed to send message"**: Ensure you're subscribed to a channel that supports client events

## Development Notes

### Code Structure

The example is organized into several UI panels:

- **Configuration Panel**: Connection settings (collapsible)
- **Connection Panel**: Connect/disconnect with status
- **Channel Panel**: Channel subscription management
- **Messaging Panel**: Real-time messaging interface

### Key Features

- **Automatic Scrolling**: Messages panel automatically scrolls to newest messages
- **Input Validation**: All inputs are validated before processing
- **Error Recovery**: Clear error states when retrying operations
- **Loading States**: Visual feedback during async operations
- **Memory Management**: Proper disposal of controllers and listeners

### Extending the Example

You can extend this example by:

- Adding more event types and handlers
- Implementing file/image message support
- Adding user typing indicators
- Implementing message history
- Adding push notification support
- Creating custom channel authentication

## API Reference

For detailed API documentation, see the main package [README](../README.md).
