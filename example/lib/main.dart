import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pusher_client_socket/pusher_client_socket.dart';

void main() {
  runApp(const MyApp());
}

const String TOKEN = "AUTH_TOKEN";
const String KEY = "PUSHER_KEY";

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pusher Client Socket',
      theme: ThemeData(
        useMaterial3: true,
      ),
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

  final tokenController = TextEditingController(text: TOKEN);

  bool connected = false;
  bool connecting = false;
  String? connectError;
  String? socketId;

  final channelController = TextEditingController(text: "Chat.1");
  PrivateChannel? channel;
  bool subscribed = false;
  bool subscribing = false;

  final messageController = TextEditingController();

  String messages = '';

  void connect() {
    if (tokenController.text.isEmpty) {
      return;
    }

    setState(() {
      connecting = true;
    });
    client = PusherClient(
      options: PusherOptions(
        host: "localhost",
        wsPort: 6001,
        encrypted: false,
        authOptions: PusherAuthOptions(
          "http://localhost/api/broadcasting/auth",
          headers:
              () async => {
                "Accept": "application/json",
                // "Content-Type": "application/json",
                "Authorization": "Bearer ${tokenController.text}",
              },
        ),
        key: KEY,
        enableLogging: true,
        autoConnect: false,
      ),
    );
    // client.onConnected((data) => setState(() {
    //       connected = true;
    //       loading = false;
    //     }));

    client.onConnectionEstablished((data) => setState(() {
          connected = true;
          socketId = client.socketId;
          connecting = false;
          client
              .subscribe(
                "private-encrypted-User.1",
              )
              .bind(
                "UserUpdatedEvent",
                (data) => print("UserUpdatedEvent - $data"),
              );
        }));

    client.onDisconnected((reason) => setState(() {
          connected = false;
          socketId = client.socketId;
          connecting = false;
        }));

    client.onConnectionError((error) => setState(() {
          connectError = "$error";
          connecting = false;
        }));

    client.onError((error) => setState(() {
          connectError = "$error";
          connecting = false;
        }));

    client.connect();
  }

  void disconnect() {
    setState(() {
      connecting = true;
    });

    client.disconnect();
  }

  void subscribe() {
    setState(() {
      subscribed = false;
      subscribing = true;
    });

    channel = client.presence(channelController.text);
    channel!.onSubscriptionSuccess(
      (data) => setState(() {
        print("Subscribe success $data");

        subscribed = true;
        subscribing = false;
      }),
    );
    channel!.bind("client-whisper", (data) {
      print("test event - $data");
      setState(() {
        messages += "client: ${data["message"]}\n";
      });
    });
    channel!.subscribe();
  }

  void unSubscribe() {
    channel!.unsubscribe();
    setState(() => subscribed = false);
  }

  void sendMessage() {
    channel!.trigger("whisper", {"message": messageController.text});
    setState(() {
      messages += "you: ${messageController.text}\n";
    });
    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Pusher Client Socket'),
      ),
      body: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (connecting)
                const CircularProgressIndicator()
              else ...[
                if (!connected)
                  TextField(
                    controller: tokenController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Token',
                    ),
                  ),
                ElevatedButton(
                  onPressed: connected ? disconnect : connect,
                  child: Text(
                    connected ? 'Disconnect' : 'Connect',
                    style: TextStyle(
                      color: connected ? Colors.red : Colors.green,
                    ),
                  ),
                ),
                if (connectError != null)
                  Text(
                    connectError!.substring(
                      0,
                      min(400, connectError!.length),
                    ),
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 20,
                    ),
                  ),
              ],
              if (connected) ...[
                Text(
                  'Socket-ID: $socketId',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Divider(),
                if (!subscribed)
                  Row(
                    children: [
                      const Text(
                        "Channel: ",
                        style: TextStyle(fontSize: 18),
                      ),
                      Flexible(
                        child: TextField(
                          controller: channelController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (subscribing)
                  const CircularProgressIndicator()
                else ...[
                  ElevatedButton(
                    onPressed: subscribed ? unSubscribe : subscribe,
                    child: Text(
                      subscribed ? 'unsubscribe' : 'subscribe',
                      style: TextStyle(
                        color: subscribed ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                  if (subscribed) ...[
                    const Divider(),
                    Row(
                      children: [
                        Flexible(
                          child: TextField(
                            controller: messageController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: sendMessage,
                          child: const Text('Send'),
                        ),
                        SizedBox(
                          height: 200,
                          child: SingleChildScrollView(
                            child: Text(messages),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
