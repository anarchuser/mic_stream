import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as Vector;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

import 'package:mic_stream/mic_stream.dart';

<<<<<<< HEAD

||||||| merged common ancestors
=======


>>>>>>> Destructor now cancels mic stream
void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Stream<List<int>> stream;
  StreamSubscription<List<int>> listener;

  Icon _icon = Icon(Icons.keyboard_voice);
  Color _iconColor = Colors.white;
  Color _bgColor = Colors.cyan;
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      initPlatformState();
    });

    print("==== Start Example ====");
  }

  void controlMicStream() async {

    if (!isRecording) {

      print("Start Streaming from the microphone...");
      stream = microphone(audioSource: AudioSource.DEFAULT, sampleRate: 16000, channelConfig: ChannelConfig.CHANNEL_IN_MONO, audioFormat: AudioFormat.ENCODING_PCM_16BIT);
      _updateButton();

      isRecording = true;

      print("Start Listening to the microphone");
      listener = stream.listen(print);
    }
    else {
      print("Stop Listening to the microphone");
      listener.cancel();

      isRecording = false;
      print('Stopped listening to the microphone');

      _updateButton();
    }
  }

  void _updateButton() {
    setState(() {
      _bgColor = (isRecording) ? Colors.cyan : Colors.red;
      _icon = (isRecording)  ? Icon(Icons.keyboard_voice) : Icon(Icons.stop);
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    setState(() {});
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
        floatingActionButton: FloatingActionButton(
          onPressed: (){controlMicStream();},
          child: _icon,
          foregroundColor: _iconColor,
          backgroundColor: _bgColor,
          tooltip: (isRecording) ? "Stop recording" : "Start recording",
        ),
      ),
    );
  }

  @override
  void dispose() {
    listener.cancel();
    super.dispose();
  }
}
