import 'package:flutter/material.dart';
import 'package:typed_data/typed_data.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:mic_stream/mic_stream.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {

    StreamController streamer = new Microphone();
    Microphone broadcaster = new Microphone.broadcast();
    streamer.stream;
    streamer.start();
    streamer.close();

    Stream<Uint8Buffer> stream = broadcaster.start();
    broadcaster.pause();
    broadcaster.resume();
    broadcaster.stop();

    String _platformVersion = await Microphone.platformVersion;

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }
}
