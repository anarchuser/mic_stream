import 'package:flutter/material.dart';
import 'package:typed_data/typed_data.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:mic_stream/mic_stream.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  Microphone microphone;
  Stream<Uint8List> stream;
  StreamSubscription<Uint8List> listener;
  Icon _icon = Icon(Icons.keyboard_voice);
  Color _iconColor = Colors.white;
  Color _bgColor = Colors.cyan;
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();

    print("==== Start Test ====");


    print("Initialize new microphone");
    microphone = new Microphone();

  }

  void controlMicStream() async {

    if (!microphone.isRecording) {

      print("Start Streaming from the microphone...");
      try {
        stream = await microphone.start();
        _updateButton();
      }
      catch(StateError) {
        print("Failed to start microphone!");
        return;
      }

      isRecording = true;

      print("Start Listening to the microphone");
      listener = stream.listen((samples) => print(samples));
    }
    else {
      print("Stop Listening to the microphone");
      listener.cancel();

      _updateButton();

      print("Stop Streaming from the microphone");
      microphone.stop();
      //microphone.close();   // Should be unnecessary
    }
  }

  void _updateButton() {
    setState(() {
      _bgColor = (microphone.isRecording) ? Colors.cyan : Colors.red;
      _icon = (microphone.isRecording)  ? Icon(Icons.keyboard_voice) : Icon(Icons.stop);
    });
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
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin: mic_stream :: Debug'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: (){controlMicStream();},
          child: _icon,
          foregroundColor: _iconColor,
          backgroundColor: _bgColor,
        ),
      ),
    );
  }
}
