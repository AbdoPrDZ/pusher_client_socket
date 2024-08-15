import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pusher_client_socket/channel/channel.dart';
import 'package:pusher_client_socket/pusher_client_socket.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
  PusherClient client = PusherClient(
    // pusher
    // appId: "1321495",
    // key: "037c47e0cbdc81fb7144",
    // secret: "2372e4edb46db25b52d1",
    // reverb
    host: "localhost:6001",
    authEndpoint: "http://localhost/broadcasting/auth",
    key: "taefodv8dmh4w452l5e0",
    authHeaders: {
      "Authorization":
          "Bearer 3|UZR2iWoWysRwWKe01ZV8hrDgi5XRs6GSJgAur8kB293a4628",
    },
    enableLogging: true,
  );

  bool connected = false;
  bool connecting = false;
  String? connectError;
  String? socketId;

  final channelController = TextEditingController(text: "Chat.1");
  PrivateChannel? channel;
  bool subscribed = false;
  bool subscribing = false;
  String? subscribeError;

  final messageController = TextEditingController();

  String messages = '';

  @override
  void initState() {
    super.initState();

    // client.onConnected((data) => setState(() {
    //       connected = true;
    //       loading = false;
    //     }));

    client.onConnectionEstablished((data) => setState(() {
          connected = true;
          socketId = client.socketId;
          connecting = false;
        }));

    client.onDisconnected((reason) => setState(() {
          connected = false;
          socketId = client.socketId;
          connecting = false;
        }));

    client.onError((error) => setState(() {
          connectError = error;
          connecting = false;
        }));
  }

  void connect() {
    setState(() {
      connecting = true;
    });

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
    channel!.onSubscriptionError((error) => setState(() {
          print("Subscribe error $error");
          subscribeError = "$error";
          subscribing = false;
        }));
    channel!.onUnsubscribed((data) => setState(() => subscribed = false));
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
                  if (subscribeError != null)
                    Text(
                      subscribeError!.substring(
                        0,
                        min(400, subscribeError!.length),
                      ),
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 20,
                      ),
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
