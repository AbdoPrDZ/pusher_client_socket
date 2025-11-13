import 'package:flutter/material.dart';
import 'package:pusher_client_socket/pusher_client_socket.dart';

void main() {
  runApp(const MyApp());
}

// Replace these with your actual values
const String DEFAULT_TOKEN = "AUTH_TOKEN";
const String DEFAULT_KEY = "PUSHER_KEY";
const String DEFAULT_HOST = "localhost";
const int DEFAULT_PORT = 6001;
const String DEFAULT_AUTH_ENDPOINT = "http://localhost/api/broadcasting/auth";

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pusher Client Socket',
      theme: ThemeData(useMaterial3: true),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late PusherClient client;

  // Connection configuration
  final tokenController = TextEditingController(text: DEFAULT_TOKEN);
  final hostController = TextEditingController(text: DEFAULT_HOST);
  final portController = TextEditingController(text: DEFAULT_PORT.toString());
  final keyController = TextEditingController(text: DEFAULT_KEY);
  final authEndpointController = TextEditingController(
    text: DEFAULT_AUTH_ENDPOINT,
  );

  // Connection state
  bool connected = false;
  bool connecting = false;
  String? connectError;
  String? socketId;

  // Channel configuration
  final channelController = TextEditingController(text: "Chat.1");
  String selectedChannelType =
      "presence"; // presence, private, private-encrypted, public
  PrivateChannel? channel;
  bool subscribed = false;
  bool subscribing = false;
  String? subscribeError;

  // Messages
  final messageController = TextEditingController();
  final List<Map<String, dynamic>> messages = [];
  final ScrollController messageScrollController = ScrollController();

  // Configuration panel
  bool showConfig = true;

  @override
  void dispose() {
    tokenController.dispose();
    hostController.dispose();
    portController.dispose();
    keyController.dispose();
    authEndpointController.dispose();
    channelController.dispose();
    messageController.dispose();
    messageScrollController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() {
      connectError = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _addMessage(String sender, String message, {bool isSystem = false}) {
    setState(() {
      messages.add({
        'sender': sender,
        'message': message,
        'timestamp': DateTime.now(),
        'isSystem': isSystem,
      });
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (messageScrollController.hasClients) {
        messageScrollController.animateTo(
          messageScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void connect() {
    // Validation
    if (tokenController.text.trim().isEmpty) {
      _showError("Token cannot be empty");
      return;
    }
    if (keyController.text.trim().isEmpty) {
      _showError("Pusher key cannot be empty");
      return;
    }
    if (hostController.text.trim().isEmpty) {
      _showError("Host cannot be empty");
      return;
    }

    final port = int.tryParse(portController.text.trim());
    if (port == null || port <= 0 || port > 65535) {
      _showError("Port must be a valid number between 1 and 65535");
      return;
    }

    setState(() {
      connecting = true;
      connectError = null;
    });

    try {
      client = PusherClient(
        options: PusherOptions(
          host: hostController.text.trim(),
          wsPort: port,
          encrypted: false,
          authOptions: PusherAuthOptions(
            authEndpointController.text.trim(),
            headers: () async => {
              "Accept": "application/json",
              "Authorization": "Bearer ${tokenController.text.trim()}",
            },
          ),
          key: keyController.text.trim(),
          enableLogging: true,
          autoConnect: false,
        ),
      );

      // Setup event listeners
      client.onConnectionEstablished((data) {
        setState(() {
          connected = true;
          socketId = client.socketId;
          connecting = false;
          connectError = null;
        });
        _addMessage(
          "System",
          "Connected! Socket ID: ${client.socketId}",
          isSystem: true,
        );
      });

      client.onDisconnected((reason) {
        setState(() {
          connected = false;
          socketId = null;
          connecting = false;
          subscribed = false;
        });
        _addMessage("System", "Disconnected: $reason", isSystem: true);
      });

      client.onConnectionError((error) {
        setState(() {
          connectError = "Connection Error: $error";
          connecting = false;
        });
        _addMessage("System", "Connection Error: $error", isSystem: true);
      });

      client.onError((error) {
        setState(() {
          connectError = "Error: $error";
          connecting = false;
        });
        _addMessage("System", "Error: $error", isSystem: true);
      });

      client.connect();
    } catch (e) {
      setState(() {
        connectError = "Failed to initialize client: $e";
        connecting = false;
      });
      _showError("Failed to initialize client: $e");
    }
  }

  void disconnect() {
    setState(() {
      connecting = true;
    });

    client.disconnect();
  }

  void subscribe() {
    // Validation
    if (channelController.text.trim().isEmpty) {
      _showError("Channel name cannot be empty");
      return;
    }

    setState(() {
      subscribed = false;
      subscribing = true;
      subscribeError = null;
    });

    try {
      // Create channel based on selected type
      final channelName = channelController.text.trim();
      switch (selectedChannelType) {
        case "public":
          channel = client.channel(channelName) as PrivateChannel?;
          break;
        case "private":
          channel = client.private(
            channelName.startsWith('private-')
                ? channelName.substring(8)
                : channelName,
          );
          break;
        case "private-encrypted":
          channel = client.privateEncrypted(
            channelName.startsWith('private-encrypted-')
                ? channelName.substring(18)
                : channelName,
          );
          break;
        case "presence":
        default:
          channel = client.presence(
            channelName.startsWith('presence-')
                ? channelName.substring(9)
                : channelName,
          );
          break;
      }

      // Setup channel event listeners
      channel!.onSubscriptionSuccess((data) {
        setState(() {
          subscribed = true;
          subscribing = false;
          subscribeError = null;
        });
        _addMessage(
          "System",
          "Successfully subscribed to channel",
          isSystem: true,
        );
      });

      // Note: onSubscriptionError might not be available in all channel types
      // We'll handle errors in the general error handler

      // Bind to message events
      channel!.bind("client-whisper", (data) {
        final message = data["message"]?.toString() ?? "No message";
        final sender = data["sender"]?.toString() ?? "Unknown";
        _addMessage(sender, message);
      });

      channel!.bind("whisper", (data) {
        final message = data["message"]?.toString() ?? "No message";
        final sender = data["sender"]?.toString() ?? "Unknown";
        _addMessage(sender, message);
      });

      channel!.subscribe();
    } catch (e) {
      setState(() {
        subscribeError = "Failed to subscribe: $e";
        subscribing = false;
      });
      _showError("Failed to subscribe: $e");
    }
  }

  void unSubscribe() {
    channel!.unsubscribe();
    setState(() => subscribed = false);
  }

  void sendMessage() {
    if (messageController.text.trim().isEmpty) {
      _showError("Message cannot be empty");
      return;
    }

    if (channel == null || !subscribed) {
      _showError("Must be subscribed to a channel first");
      return;
    }

    try {
      final message = messageController.text.trim();
      channel!.trigger("whisper", {
        "message": message,
        "sender": "You",
        "timestamp": DateTime.now().toIso8601String(),
      });

      _addMessage("You", message);
      messageController.clear();
    } catch (e) {
      _showError("Failed to send message: $e");
    }
  }

  Widget _buildConfigPanel() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Configuration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(
                    showConfig ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () => setState(() => showConfig = !showConfig),
                ),
              ],
            ),
            if (showConfig) ...[
              const SizedBox(height: 16),
              TextField(
                controller: tokenController,
                decoration: const InputDecoration(
                  labelText: 'Authentication Token',
                  border: OutlineInputBorder(),
                  hintText: 'Bearer token for authentication',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: 'Pusher App Key',
                  border: OutlineInputBorder(),
                  hintText: 'Your Pusher application key',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: hostController,
                      decoration: const InputDecoration(
                        labelText: 'Host',
                        border: OutlineInputBorder(),
                        hintText: 'localhost or your server host',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: portController,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        border: OutlineInputBorder(),
                        hintText: '6001',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: authEndpointController,
                decoration: const InputDecoration(
                  labelText: 'Auth Endpoint',
                  border: OutlineInputBorder(),
                  hintText: 'http://localhost/api/broadcasting/auth',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionPanel() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (connecting)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: connected ? disconnect : connect,
                  icon: Icon(connected ? Icons.link_off : Icons.link),
                  label: Text(connected ? 'Disconnect' : 'Connect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: connected ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (connected && socketId != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Connected - Socket ID: $socketId',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (connectError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        connectError!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChannelPanel() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Channel Subscription',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedChannelType,
              decoration: const InputDecoration(
                labelText: 'Channel Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: "public",
                  child: Text("Public Channel"),
                ),
                DropdownMenuItem(
                  value: "private",
                  child: Text("Private Channel"),
                ),
                DropdownMenuItem(
                  value: "private-encrypted",
                  child: Text("Private Encrypted Channel"),
                ),
                DropdownMenuItem(
                  value: "presence",
                  child: Text("Presence Channel"),
                ),
              ],
              onChanged: subscribed
                  ? null
                  : (value) {
                      setState(() => selectedChannelType = value!);
                    },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: channelController,
              decoration: const InputDecoration(
                labelText: 'Channel Name',
                border: OutlineInputBorder(),
                hintText: 'Enter channel name (without prefix)',
              ),
              enabled: !subscribed,
            ),
            const SizedBox(height: 16),
            if (subscribing)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: !connected
                      ? null
                      : (subscribed ? unSubscribe : subscribe),
                  icon: Icon(
                    subscribed ? Icons.unsubscribe : Icons.subscriptions,
                  ),
                  label: Text(subscribed ? 'Unsubscribe' : 'Subscribe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: subscribed ? Colors.orange : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (subscribeError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subscribeError!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessagingPanel() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Messages',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages yet...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: messageScrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isSystem = message['isSystem'] ?? false;
                        final isYou = message['sender'] == 'You';

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 8,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSystem
                                      ? Colors.grey.shade200
                                      : isYou
                                      ? Colors.blue.shade100
                                      : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  message['sender'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isSystem
                                        ? Colors.grey.shade700
                                        : isYou
                                        ? Colors.blue.shade800
                                        : Colors.green.shade800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  message['message'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontStyle: isSystem
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                    color: isSystem
                                        ? Colors.grey.shade600
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    enabled: subscribed,
                    onSubmitted: subscribed ? (_) => sendMessage() : null,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: subscribed ? sendMessage : null,
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Pusher Client Socket Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear Messages',
            onPressed: () => setState(() => messages.clear()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildConfigPanel(),
            _buildConnectionPanel(),
            if (connected) _buildChannelPanel(),
            if (subscribed) _buildMessagingPanel(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
