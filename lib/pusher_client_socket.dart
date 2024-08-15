library pusher_client_socket;

import 'dart:convert';

import 'package:pusher_client_socket/channel/channel.dart';
import 'package:pusher_client_socket/src/channels.collection.dart';
import 'package:pusher_client_socket/src/events_listeners.collection.dart';
import 'package:web_socket_client/web_socket_client.dart';

import 'src/auth_options.dart';
import 'src/options.dart';

export 'channel/channel.dart';
export 'package:web_socket_client/src/connection_state.dart';

class PusherClient {
  PusherOptions? options;

  PusherClient({
    Protocol protocol = Protocol.ws,
    String? host,
    required String authEndpoint,
    required String key,
    String? cluster,
    int activityTimeout = 120000,
    int pongTimeout = 30000,
    Map<String, String> authHeaders = const {},
    Map<String, String> parameters = const {},
    bool enableLogging = false,
  }) {
    options = PusherOptions(
      protocol: protocol,
      host: host,
      key: key,
      cluster: cluster,
      activityTimeout: activityTimeout,
      pongTimeout: pongTimeout,
      parameters: {
        "protocol": "7",
        "client": "flutter",
        "version": "0.0.1",
        "flash": "false",
        ...parameters,
      },
      authOptions: AuthOptions(
        authEndpoint,
        headers: {
          // "Content-Type": "application/json",
          "Accept": "application/json",
          ...authHeaders,
        },
      ),
      enableLogging: enableLogging,
    );
    onConnectionEstablished(_onConnectionEstablished);
    onError(_onError);
    listen("pusher:ping", _onPing);
    // listen("pusher:pong", _onPong);
  }

  WebSocket? __socket;

  String? _socketId;

  String? get socketId => _socketId;

  bool _connected = false;

  bool get connected => _connected;

  ConnectionState _connectionState = const Disconnected();

  ConnectionState get connectionState => _connectionState;

  WebSocket get _socket {
    if (__socket != null) return __socket!;
    throw Exception("the channel does not initialized yet");
  }

  void connect() {
    __socket = WebSocket(Uri.parse(options!.url));

    _socket.connection.listen(_onConnectionStateChange);

    _socket.messages.listen(
      _onMessageReceived,
      onError: (err) => _onEvent('error', err),
    );
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

    options!.log(
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
        // _resetActivityCheck();
        break;
      case Reconnecting():
        _onEvent('reconnecting', null);
        break;
      case Reconnected():
        _onEvent('reconnected', null);
        break;
      case Disconnecting():
        _onEvent('disconnecting', null);
        break;
      case Disconnected():
        _onEvent('disconnected', state);
        if (state.error != null) _onError(state.error);

        _socketId = null;
        break;
      default:
    }
  }

  void _onMessageReceived(message) {
    options!.log("MESSAGE_RECEIVED", null, "$message");

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
        String eventName = event['event'];
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

  void _onConnectionEstablished(Map data) {
    options!.log("CONNECTION_ESTABLISHED", null, "data: $data");
    _socketId = data['socket_id'];
    _connected = true;
  }

  void _onError(error) {
    options!.log("ERROR", null, "error: $error");
  }

  void _onPing(data) {
    options!.log("PINGING", null, "data: $data");
    sendEvent("pusher:pong", data);
  }

  final _eventsListeners = EventsListenersCollection();
  final Map<String, Map<String, List<Function>>> _channelsEventsListeners = {};

  void listen(String event, Function listener, [String? channel]) {
    options!.log("EVENT_LISTENING", channel, "event: $event");

    if (channel != null) {
      if (!_channelsEventsListeners.containsKey(channel)) {
        _channelsEventsListeners[channel] = {};
      }

      if (!_channelsEventsListeners[channel]!.containsKey(event)) {
        _channelsEventsListeners[channel]![event] = [];
      }

      if (!_channelsEventsListeners[channel]![event]!.contains(listener)) {
        _channelsEventsListeners[channel]![event]!.add(listener);
      }
    } else {
      _eventsListeners.bind(event, listener);
    }
  }

  void sendEvent(String event, [dynamic data, String? channel]) {
    options!.log("SEND_EVENT", null, "event: $event\n  data: $data");
    _socket.send(jsonEncode({
      "event": event,
      "data": data,
      if (channel != null) "channel": channel,
    }));
  }

  void onConnectionStateChange(Function(ConnectionState) listener) =>
      listen("connection_state_changed", listener);

  void onConnecting(Function listener) => listen('connecting', listener);

  void onConnected(Function listener) => listen('connected', listener);

  void onConnectionEstablished(Function listener) =>
      listen("pusher:connection_established", listener);

  void onReconnecting(Function listener) => listen('reconnecting', listener);

  void onReconnected(Function listener) => listen('reconnected', listener);

  void onDisconnecting(Function listener) => listen('disconnecting', listener);

  void onDisconnected(Function listener) => listen('disconnected', listener);

  void onError(Function(dynamic error) listener) => listen('error', listener);

  void disconnect([int? code, String? reason]) {
    options!.log("DISCONNECT", null, "code: $code\n  reason: $reason");

    _socket.close(code, reason);
  }

  late final _channelsCollection = ChannelsCollection(this);

  T channel<T extends Channel>(String channelName) =>
      _channelsCollection.channel<T>(channelName);

  PrivateChannel private(String channelName) => channel(
        channelName.startsWith("private-")
            ? channelName
            : "private-$channelName",
      );

  PrivateChannel privateEncrypted(String channelName) => channel(
        channelName.startsWith("private-encrypted-")
            ? channelName
            : "private-encrypted-$channelName",
      );

  PresenceChannel presence(String channelName) => channel(
        channelName.startsWith("presence-")
            ? channelName
            : "presence-$channelName",
      );

  T subscribe<T extends Channel>(String channelName) {
    final channel = this.channel<T>(channelName);
    channel.subscribe();
    return channel;
  }

  void unsubscribe(String channelName) => channel(channelName).unsubscribe();

  // Timer? _activityTimer;

  // void _sendActivityCheck() {
  //   _stopActivityTimer();

  //   sendEvent("pusher:ping", null);

  //   _activityTimer = Timer.periodic(
  //     Duration(milliseconds: options!.pongTimeout),
  //     (timer) {
  //       _onError("Activity timeout");
  //       disconnect(408, "Activity timeout");
  //     },
  //   );
  // }

  // void _resetActivityCheck() {
  //   _stopActivityTimer();
  //   _activityTimer = Timer.periodic(
  //     Duration(milliseconds: options!.activityTimeout),
  //     (timer) {
  //       _sendActivityCheck();
  //     },
  //   );
  // }

  // void _stopActivityTimer() {
  //   _activityTimer?.cancel();
  // }

  // void _onPong() {
  //   _stopActivityTimer();
  //   _resetActivityCheck();
  // }
}
