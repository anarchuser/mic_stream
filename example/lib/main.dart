import 'dart:async';
import 'dart:math';
import 'dart:core';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:mic_stream/mic_stream.dart';

enum Command {
  start,
  stop,
  change,
}

int screenWidth = 0;

void main() => runApp(MicStreamExampleApp());

class MicStreamExampleApp extends StatefulWidget {
  @override
  _MicStreamExampleAppState createState() => _MicStreamExampleAppState();
}

class _MicStreamExampleAppState extends State<MicStreamExampleApp>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Stream<Uint8List>? stream;
  late StreamSubscription listener;

  List<double>? waveSamples;
  List<double>? intensitySamples;
  int sampleIndex = 0;
  double localMax = 0;
  double localMin = 0;

  // Refreshes the Widget for every possible tick to force a rebuild of the sound wave
  late AnimationController controller;

  Color _iconColor = Colors.white;
  bool isRecording = false;
  bool memRecordingState = false;
  late bool isActive;
  DateTime? startTime;

  int page = 0;
  List state = ["SoundWavePage", "IntensityWavePage", "InformationPage"];

  @override
  void initState() {
    print("Init application");
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setState(() {
      initPlatformState();
    });
  }

  void _controlPage(int index) => setState(() => page = index);

  // Responsible for switching between recording / idle state
  void _controlMicStream({Command command = Command.change}) async {
    switch (command) {
      case Command.change:
        _changeListening();
        break;
      case Command.start:
        _startListening();
        break;
      case Command.stop:
        _stopListening();
        break;
    }
  }

  Future<bool> _changeListening() async =>
      !isRecording ? await _startListening() : _stopListening();

  late int bytesPerSample;
  late int samplesPerSecond;

  Future<bool> _startListening() async {
    if (isRecording) return false;
    // Default option. Set to false to disable request permission dialogue
    MicStream.shouldRequestPermission(true);

    stream = MicStream.microphone(
        audioSource: AudioSource.DEFAULT,
        sampleRate: 48000,
        channelConfig: ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: AudioFormat.ENCODING_PCM_16BIT);
    listener = stream!
        .transform(MicStream.toSampleStream)
        .listen(_processSamples);
    listener.onError(print);
    print("Start listening to the microphone, sample rate is ${await MicStream.sampleRate}, bit depth is ${await MicStream.bitDepth}, bufferSize: ${await MicStream.bufferSize}");

    localMax = 0;
    localMin = 0;

    bytesPerSample = await MicStream.bitDepth ~/ 8;
    samplesPerSecond = await MicStream.sampleRate;
    setState(() {
      isRecording = true;
      startTime = DateTime.now();
    });
    return true;
  }

  void _processSamples(_sample) async {
    if (screenWidth == 0) return;

    double sample = 0;
    if ("${_sample.runtimeType}" == "(int, int)" || "${_sample.runtimeType}" == "(double, double)") {
      sample = 0.5 * (_sample.$1 + _sample.$2);
    } else {
      sample = _sample.toDouble();
    }
    waveSamples ??= List.filled(screenWidth, 0);

    final overridden = waveSamples![sampleIndex];
    waveSamples![sampleIndex] = sample;
    sampleIndex = (sampleIndex + 1) % screenWidth;

    if (overridden == localMax) {
      localMax = 0;
      for (final val in waveSamples!) {
        localMax = max(localMax, val);
      }
    } else if (overridden == localMin) {
      localMin = 0;
      for (final val in waveSamples!) {
        localMin = min(localMin, val);
      }
    } else {
      if (sample > 0) localMax = max(localMax, sample);
      else localMin = min(localMin, sample);
    }

    _calculateIntensitySamples();
  }

  void _calculateIntensitySamples() {
  }

  bool _stopListening() {
    if (!isRecording) return false;
    print("Stop listening to the microphone");
    listener.cancel();

    setState(() {
      isRecording = false;
      waveSamples = List.filled(screenWidth, 0);
      intensitySamples = List.filled(screenWidth, 0);
      startTime = null;
    });
    return true;
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    if (!mounted) return;
    isActive = true;

    Statistics(false);

    controller =
        AnimationController(duration: Duration(seconds: 1), vsync: this)
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
  Icon _getIcon() =>
      (isRecording) ? Icon(Icons.stop) : Icon(Icons.keyboard_voice);

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
          bottomNavigationBar: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.broken_image),
                label: "Sound Wave",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.broken_image),
                label: "Intensity Wave",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.view_list),
                label: "Statistics",
              )
            ],
            backgroundColor: Colors.black26,
            elevation: 20,
            currentIndex: page,
            onTap: _controlPage,
          ),
          body: (page == 0 || page == 1)
              ? CustomPaint(
                  painter: page == 0
                      ? WavePainter(samples: waveSamples, color: _getBgColor(), index: sampleIndex, localMax: localMax, localMin: localMin, context: context,)
                      : IntensityPainter(samples: intensitySamples, color: _getBgColor(), index: sampleIndex, localMax: localMax, localMin: localMin, context: context,)
                )
              : Statistics(
                  isRecording,
                  startTime: startTime,
                )),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      isActive = true;
      print("Resume app");

      _controlMicStream(command: memRecordingState ? Command.start : Command.stop);
    } else if (isActive) {
      memRecordingState = isRecording;
      _controlMicStream(command: Command.stop);

      print("Pause app");
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
  int? index;
  double? localMax;
  double? localMin;
  List<double>? samples;
  late List<Offset> points;
  Color? color;
  BuildContext? context;
  Size? size;

  WavePainter({this.samples, this.color, this.context, this.index, this.localMax, this.localMin});

  @override
  void paint(Canvas canvas, Size? size) {
    this.size = context!.size;
    size = this.size;
    if (size == null) return;
    screenWidth = size.width.toInt();

    Paint paint = new Paint()
      ..color = color!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    samples ??= List.filled(screenWidth, 0);
    index ??= 0;
    points = toPoints(samples!, index!);

    Path path = new Path();
    path.addPolygon(points, false);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldPainting) => true;

  // Maps a list of ints and their indices to a list of points on a cartesian grid
  List<Offset> toPoints(List<double> samples, int index) {
    List<Offset> points = [];
    double totalMax = max(-1 * localMin!, localMax!);
    double maxHeight = 0.5 * size!.height;
    for (int i = 0; i < screenWidth; i++) {
      double height = maxHeight + ((totalMax == 0 || index == 0) ? 0 : (samples[(i + index) % index] / totalMax * maxHeight));
      var point = Offset(i.toDouble(), height);
      points.add(point);
    }
    return points;
  }
}

class IntensityPainter extends CustomPainter {
  int? index;
  double? localMax;
  double? localMin;
  List<double>? samples;
  late List<Offset> points;
  Color? color;
  BuildContext? context;
  Size? size;

  IntensityPainter({this.samples, this.color, this.context, this.index, this.localMax, this.localMin});

  @override
  void paint(Canvas canvas, Size? size) {
  }

  @override
  bool shouldRepaint(CustomPainter oldPainting) => true;

  // Maps a list of ints and their indices to a list of points on a cartesian grid
  List<Offset> toPoints(List<int>? samples) {
    return points;
  }

  double project(double val, double max, double height) {
    if (max == 0) {
      return 0.5 * height;
    }
    var rv = val / max * 0.5 * height;
    return rv;
  }
}

class Statistics extends StatelessWidget {
  final bool isRecording;
  final DateTime? startTime;

  final String url = "https://github.com/anarchuser/mic_stream";

  Statistics(this.isRecording, {this.startTime});

  @override
  Widget build(BuildContext context) {
    return ListView(children: <Widget>[
      ListTile(
          leading: Icon(Icons.title),
          title: Text("Microphone Streaming Example App")),
      ListTile(
        leading: Icon(Icons.keyboard_voice),
        title: Text((isRecording ? "Recording" : "Not recording")),
      ),
      ListTile(
          leading: Icon(Icons.access_time),
          title: Text((isRecording
              ? DateTime.now().difference(startTime!).toString()
              : "Not recording"))),
    ]);
  }
}

Iterable<T> eachWithIndex<E, T>(
    Iterable<T> items, E Function(int index, T item) f) {
  var index = 0;

  for (final item in items) {
    f(index, item);
    index = index + 1;
  }

  return items;
}
