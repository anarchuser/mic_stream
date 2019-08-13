import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:mic_stream/mic_stream.dart';

enum Cmd {
  start,
  stop,
  change,
}

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Stream<List<int>> stream;
  StreamSubscription<List<int>> listener;
  List<int> currentSamples;

  // Refreshes the Widget for every possible tick to force a rebuild of the sound wave
  AnimationController controller;

  Color _iconColor = Colors.white;
  bool isRecording = false;
  bool memRecordingState = false;
  bool isActive;

  @override
  void initState() {
    print("Init application");
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setState(() {
      initPlatformState();
    });
  }

  // Responsible for switching between recording / idle state
  void _controlMicStream({Cmd cmd: Cmd.change}) async {
    switch(cmd) {
      case Cmd.change:
        _changeListening();
        break;
      case Cmd.start:
        _startListening();
        break;
      case Cmd.stop:
        _stopListening();
        break;
    }
  }

  bool _changeListening() => !isRecording ? _startListening() : _stopListening();

  bool _startListening() {
    if (isRecording) return false;
    stream = microphone(audioSource: AudioSource.DEFAULT, sampleRate: 16000, channelConfig: ChannelConfig.CHANNEL_IN_MONO, audioFormat: AudioFormat.ENCODING_PCM_16BIT);

    setState(() => isRecording = true);

    print("Start Listening to the microphone");
    listener = stream.listen((samples) => currentSamples = samples);
    return true;
  }

  bool _stopListening() {
    if (!isRecording) return false;
    print("Stop Listening to the microphone");
    listener.cancel();

    setState(() {
      isRecording = false;
      currentSamples = null;
    });
    return true;
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    if (!mounted) return;
    isActive = true;

    controller = AnimationController(duration: Duration(seconds: 1), vsync: this)
      ..addListener(() {
        if (isRecording) setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) controller.reverse();
        else if (status == AnimationStatus.dismissed) controller.forward();
      })
      ..forward();
  }

  Color _getBgColor() => (isRecording) ? Colors.red : Colors.cyan;
  Icon _getIcon() => (isRecording) ? Icon(Icons.stop) : Icon(Icons.keyboard_voice);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin: mic_stream :: Debug'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _controlMicStream,
          child: _getIcon(),
          foregroundColor: _iconColor,
          backgroundColor: _getBgColor(),
          tooltip: (isRecording) ? "Stop recording" : "Start recording",
        ),
        body: CustomPaint(
          painter: WavePainter(currentSamples, _getBgColor(), context),
        )
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      isActive = true;
      print("Resume app");
      _controlMicStream(cmd: memRecordingState ? Cmd.start : Cmd.stop);
    }
    else if (isActive){
      print("Pause app");
      memRecordingState = isRecording;
      _controlMicStream(cmd: Cmd.stop);
      isActive = false;
    }
  }

  @override
  void dispose() {
    listener.cancel();
    controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class WavePainter extends CustomPainter {
  List<int> samples;
  List<Offset> points;
  Color color;
  BuildContext context;
  Size size;

  static int absMax = 0;

  WavePainter(this.samples, this.color, this.context);

  @override
  void paint(Canvas canvas, Size size) {

    this.size = context.size;
    size = this.size;

    Paint paint = new Paint()
        ..color = color
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

    points = toPoints(samples);

    Path path = new Path();
    path.addPolygon(points, false);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldPainting) => true;

  // Maps a list of ints and their indices to a list of points on a cartesian grid
  List<Offset> toPoints (List<int> samples) {
    List<Offset> points = [];
    if (samples == null) samples = List<int>.filled(size.width.toInt(), (0.5 * size.height).toInt());
    else samples.forEach((sample) => absMax = max(absMax, sample.abs()));
    for (int i = 0; i < min(size.width, samples.length).toInt(); i++) {
      points.add(new Offset(i.toDouble(), project(samples[i], absMax, size.height)));
    }
    return points;
  }

  double project(int val, int max, double height) {
    double waveHeight;
    if (max == 0) waveHeight = val.toDouble();
    else waveHeight = (val / max) * 0.5 * height;
    return waveHeight + 0.5 * height;
  }
}
