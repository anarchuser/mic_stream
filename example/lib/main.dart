import 'dart:async';
import 'dart:math';
import 'dart:core';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

import 'package:mic_stream/mic_stream.dart';
import 'package:path_provider/path_provider.dart';

enum Command {
  start,
  stop,
  change,
}

const AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT;

void main() => runApp(MicStreamExampleApp());

class MicStreamExampleApp extends StatefulWidget {
  @override
  _MicStreamExampleAppState createState() => _MicStreamExampleAppState();
}

class _MicStreamExampleAppState extends State<MicStreamExampleApp>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Stream stream;
  StreamSubscription listener;
  List<int> currentSamples;

  // Refreshes the Widget for every possible tick to force a rebuild of the sound wave
  AnimationController controller;

  Color _iconColor = Colors.white;
  bool isRecording = false;
  bool memRecordingState = false;
  bool isActive;
  DateTime startTime;

  int page = 0;
  List state = ["SoundWavePage", "InformationPage"];


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
  void _controlMicStream({Command command: Command.change}) async {
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

  Future<bool> _startListening() async {
    if (isRecording) return false;
    // if this is the first time invoking the microphone() method to get the stream, we don't yet have access to the sampleRate and bitDepth properties
    stream = await MicStream.microphone(
        audioSource: AudioSource.DEFAULT,
        sampleRate: 16000,
        channelConfig: ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: AUDIO_FORMAT);
    // after invoking the method for the first time, though, these will be available;
    // It is not necessary to setup a listener first, the stream only needs to be returned first
    print("Start Listening to the microphone, sample rate is ${await MicStream.sampleRate}, bit depth is ${await MicStream.bitDepth}");

    setState(() {
      isRecording = true;
      startTime = DateTime.now();
    });
    listener = stream.listen((samples) async { 
	    File((await getApplicationDocumentsDirectory()).path + "/pcmdata").writeAsBytesSync(samples, mode:FileMode.append); 
	    currentSamples = samples; 
    });
    return true;
  }

  bool _stopListening() {
    if (!isRecording) return false;
    print("Stop Listening to the microphone");
    listener.cancel();

    setState(() {
      isRecording = false;
      currentSamples = null;
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
            if (status == AnimationStatus.completed)
              controller.reverse();
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
                title: Text("Sound Wave"),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.view_list),
                title: Text("Statistics"),
              )
            ],
            backgroundColor: Colors.black26,
            elevation: 20,
            currentIndex: page,
            onTap: _controlPage,
          ),
          body: (page == 0)
              ? CustomPaint(
                  painter: WavePainter(currentSamples, _getBgColor(), context),
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

      _controlMicStream(
          command: memRecordingState ? Command.start : Command.stop);
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
  List<int> samples;
  List<Offset> points;
  Color color;
  BuildContext context;
  Size size;

  // Set max val possible in stream, depending on the config
  final int absMax = (AUDIO_FORMAT == AudioFormat.ENCODING_PCM_8BIT) ? 127 : 32767;

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
  List<Offset> toPoints(List<int> samples) {
    List<Offset> points = [];
    if (samples == null)
      samples =
          List<int>.filled(size.width.toInt(), (0.5 * size.height).toInt());
    for (int i = 0; i < min(size.width, samples.length).toInt(); i++) {
      points.add(
          new Offset(i.toDouble(), project(samples[i], absMax, size.height)));
    }
    return points;
  }

  double project(int val, int max, double height) {
    double waveHeight = (max == 0) ? val.toDouble() : (val / max) * 0.5 * height;
    return waveHeight + 0.5 * height;
  }
}

class Statistics extends StatelessWidget {
  final bool isRecording;
  final DateTime startTime;

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
              ? DateTime.now().difference(startTime).toString()
              : "Not recording"))),
    ]);
  }
}
