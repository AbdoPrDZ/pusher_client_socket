library pusher_client_socket;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pusher_client_socket/channels/channel.dart';
import 'package:pusher_client_socket/src/channels.collection.dart';
import 'package:pusher_client_socket/src/events_listeners.collection.dart';
import 'package:web_socket_client/web_socket_client.dart';

import 'src/options.dart';

export 'channels/channel.dart';
export 'src/options.dart';
export 'package:web_socket_client/src/connection_state.dart';

/// Represents a client for connecting to a Pusher server.
class PusherClient {
  /// The options of the client.
  final PusherOptions options;

  PusherClient({required this.options}) {
    onConnectionError(_onConnectionError);
    onConnectionEstablished(_onConnectionEstablished);
    bind("pusher:ping", _onPing);
    bind("pusher:pong", (data) {
      _stopActivityTimer();
      _resetActivityCheck();
    });

    if (options.autoConnect) connect();
  }

  WebSocket? __socket;

  String? _socketId;

  String? get socketId => _socketId;

  bool _connected = false;

  /// Returns a boolean value indicating whether the client is connected.
  bool get connected => _connected;

  ConnectionState _connectionState = const Disconnected();

  /// Returns the current connection state of the client.
  ConnectionState get connectionState => _connectionState;

  WebSocket get _socket {
    if (__socket != null) return __socket!;
    throw Exception("The channel does not initialized yet");
  }

  /// Connects the client to the server.
  void connect() {
    __socket = WebSocket(Uri.parse(options.url));

    _socket.connection.listen(_onConnectionStateChange);

    _socket.messages.listen(
      _onMessageReceived,
      onError: (err) => _onEvent('error', err),
    );
  }

  /// Disconnects the client from the server.
  void disconnect([int? code, String? reason]) {
    options.log("DISCONNECT", null, "code: $code\n  reason: $reason");

    _socket.close(code, reason);
  }

  void _onConnectionStateChange(ConnectionState state) {
    final states = {
      const Connecting(): 'CONNECTING',
      const Connected(): 'CONNECTED',
      const Reconnecting(): 'RECONNECTING',
      const Reconnected(): 'RECONNECTED',
      const Disconnecting(): 'DISCONNECTING',
      const Disconnected(): 'DISCONNECTED',
    };

    options.log(
      "CONNECTION_STATE_CHANGED",
      null,
      "the connection state changed from ${states[_connectionState]} to ${states[state]}",
    );
    _connectionState = state;
    _connected = state is Connected;

    _onEvent("connection_state_changed", state);

    switch (state) {
      case Connecting():
        _onEvent('connecting', null);
        break;
      case Connected():
        _onEvent('connected', null);
        _resetActivityCheck();
        break;
      case Reconnecting():
        _onEvent('reconnecting', null);
        break;
      case Reconnected():
        _onEvent('reconnected', null);
        _resetActivityCheck();
        break;
      case Disconnecting():
        _onEvent('disconnecting', null);
        break;
      case Disconnected():
        _onEvent('disconnected', state);
        if (state.error != null) {
          _onEvent("connection_error", state.error);
        }
        _stopActivityTimer();
        _connected = false;
        _socketId = null;
        __socket = null;
        break;
      default:
    }
  }

  void _onConnectionError(dynamic error) {
    options.log("CONNECTION_ERROR", null, "error: $error");

    disconnect(1006, error.message);

    if (error is WebSocketException) {
      connect();
    }
  }

  void _onConnectionEstablished(Map data) {
    options.log("CONNECTION_ESTABLISHED", null, "data: $data");
    _socketId = data['socket_id'];
    _connected = true;
    _reSubscribe();
  }

  void _onPing(data) {
    options.log("PINGING", null, "data: $data");
    sendEvent("pusher:pong", data);
  }

  Timer? _activityTimer;

  void _sendActivityCheck() {
    _stopActivityTimer();

    sendEvent("pusher:ping", null);

    _activityTimer = Timer.periodic(
      Duration(milliseconds: options.pongTimeout),
      (timer) {
        _onEvent("pusher:error", "Activity timeout");
        disconnect(null, "Activity timeout");
      },
    );
  }

  void _resetActivityCheck() {
    _stopActivityTimer();
    _activityTimer = Timer.periodic(
      Duration(milliseconds: options.activityTimeout),
      (timer) => _sendActivityCheck(),
    );
  }

  void _stopActivityTimer() {
    _activityTimer?.cancel();
  }

  final _eventsListeners = EventsListenersCollection();

  void _onMessageReceived(message) {
    options.log("MESSAGE_RECEIVED", null, "$message");

    dynamic event;

    try {
      event = jsonDecode(message);
    } catch (e) {
      throw Exception(
        'Invalid message "$message", cannot decode message json',
      );
    }

    if (event is Map) {
      if (event.containsKey('event')) {
        String eventName = event['event'].replaceAll(
          'pusher_internal:',
          'pusher:',
        );
        dynamic data = event['data'];

        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (e) {}
        }

        _onEvent(eventName, data, event["channel"]);
      } else {
        throw Exception(
          'Invalid event "$event", messing event name',
        );
      }
    } else {
      throw Exception(
        'Invalid event "$event", the event must be map but ${event.runtimeType} given',
      );
    }
  }

  void _onEvent(String event, data, [String? channel]) {
    _eventsListeners.handleEvent(event, data, channel);

    if (channel != null) {
      _channelsCollection.get(channel)?.handleEvent(event, data);
    }
  }

  /// Binds a listener to an event.
  void bind(String event, Function listener) {
    options.log("EVENT_BINDING", "event: $event");

    _eventsListeners.bind(event, listener);
  }

  /// Send an event to the server.
  void sendEvent(String event, [dynamic data, String? channel]) {
    options.log("SEND_EVENT", null, "event: $event\n  data: $data");
    _socket.send(jsonEncode({
      "event": event,
      "data": data,
      if (channel != null) "channel": channel,
    }));
  }

  /// Binding to the connection state change event.
  void onConnectionStateChange(Function(ConnectionState) listener) =>
      bind("connection_state_changed", listener);

  /// Binding to the connection state change event.
  void onConnecting(Function listener) => bind('connecting', listener);

  /// Binding to the connection state change event.
  void onConnected(Function listener) => bind('connected', listener);

  /// Binding to the connection state change event.
  void onConnectionEstablished(Function listener) =>
      bind("pusher:connection_established", listener);

  /// Binding to the connection state change event.
  void onReconnecting(Function listener) => bind('reconnecting', listener);

  /// Binding to the connection state change event.
  void onReconnected(Function listener) => bind('reconnected', listener);

  /// Binding to the connection state change event.
  void onDisconnecting(Function listener) => bind('disconnecting', listener);

  /// Binding to the connection state change event.
  void onDisconnected(Function listener) => bind('disconnected', listener);

  /// Binding to the connection state change event.
  void onConnectionError(Function(dynamic error) listener) =>
      bind('connection_error', listener);

  /// Binding to the connection state change event.
  void onError(Function(dynamic error) listener) =>
      bind('pusher:error', listener);

  late final _channelsCollection = ChannelsCollection(this);

  /// Returns a channel by name.
  T channel<T extends Channel>(String channelName, {bool subscribe = false}) =>
      _channelsCollection.channel<T>(channelName, subscribe: subscribe);

  /// Returns a private channel by name.
  PrivateChannel private(String channelName, {bool subscribe = false}) =>
      channel(
        channelName.startsWith("private-")
            ? channelName
            : "private-$channelName",
        subscribe: subscribe,
      );

  /// Returns a private encrypted channel by name.
  PrivateChannel privateEncrypted(String channelName,
          {bool subscribe = false}) =>
      channel(
        channelName.startsWith("private-encrypted-")
            ? channelName
            : "private-encrypted-$channelName",
        subscribe: subscribe,
      );

  /// Returns a presence channel by name.
  PresenceChannel presence(String channelName, {bool subscribe = false}) =>
      channel(
        channelName.startsWith("presence-")
            ? channelName
            : "presence-$channelName",
        subscribe: subscribe,
      );

  /// Subscribes to a channel by name.
  T subscribe<T extends Channel>(String channelName) =>
      channel<T>(channelName, subscribe: true);

  /// Unsubscribes from a channel by name.
  void unsubscribe(String channelName) => channel(channelName).unsubscribe();

  void _reSubscribe() {
    _channelsCollection.forEach((channel) {
      if (channel.subscribed) {
        channel.subscribe(true);
      }
    });
  }
}
