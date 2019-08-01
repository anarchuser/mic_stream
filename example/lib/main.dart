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


void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Stream<List<int>> stream;
  StreamSubscription<List<int>> listener;
  List<int> currentSamples;

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
      listener = stream.listen((samples) {
        setState(() {
          currentSamples = samples;
        });
      });
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
        body: CustomPaint(
          painter: WavePainter(currentSamples, _bgColor)
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

class WavePainter extends CustomPainter {
  List<int> samples;
  Color color;

  WavePainter(this.samples, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Debug
    print("Paint: " + samples.toString());

    Paint paint = new Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

    Path path = new Path();
    path.addPolygon(toPoints(samples, size), false);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldPainting) => true;

  // Maps a list of ints and their indices to a list of points on a cartesian grid
  List<Offset> toPoints (List<int> samples, Size size) {
    List<Offset> points = [];
    int absMax = 0;
    if (samples == null) samples = List<int>.filled(size.width.toInt(), 0);
    else samples.forEach((sample) => absMax = max(absMax, sample.abs()));
    for (num i = 0; i < min(size.width, samples.length); i++) {
      points.add(new Offset(i, fit(samples[i], size.height)));
    }
    return points;
  }

  // Returns an integer fitting into the respective height
  num fit(num value, num height) => value < 0 ? max(0.5 * value, height) : min(0.5 * value, height);
}