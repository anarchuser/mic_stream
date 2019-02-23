import 'package:flutter/material.dart';
import 'package:typed_data/typed_data.dart';
import 'dart:async';
import 'dart:typed_data';

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

    print("==== Start Test ====");
    testMicStream();
  }

  Future<void> testMicStream() async {
    print("Initialize new microphone");
    Microphone microphone = new Microphone();

    print("Start Streaming from the microphone:");
    Stream<Uint8List> stream = await microphone.start();

    print("Start Listening to the microphone:");
    StreamSubscription<Uint8List> listener = stream.listen((samples) => print(samples.toString));

    print("Stop Streaming from the microphone:");
    microphone.stop();
    microphone.close();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    _platformVersion = await Microphone.platformVersion;
    setState(() {});

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
