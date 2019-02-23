import 'dart:async';
import 'dart:typed_data';
import 'dart:developer';

import 'package:flutter/services.dart';

/* Class handling the microphone */
class Microphone implements StreamController {
  static const _platform = const MethodChannel('mic_stream');
  static const DEFAULT_SAMPLE_RATE = 16000;
  bool _isRecording = false;
  StreamController<Uint8List> _controller;
  DateTime _timestamp;

  // Implemented Constructors
  Microphone() : _controller = new StreamController();
  Microphone.broadcast() : _controller = new StreamController.broadcast();

  // Implemented methods:
  close() => _controller.close();
  noSuchMethod(Invocation invocation) => _controller.noSuchMethod(invocation);
  toString() => _controller.toString();

  // Starts and returns an audio stream from the microphone, which is given back as Uint8List; each element has the length of .bufferSize
  Future<Stream<Uint8List>> start({int sampleRate = DEFAULT_SAMPLE_RATE}) async {
    if (!_isRecording) {
      _isRecording = true;
      print("  Init timestamp");
      _timestamp = new DateTime.now();
      print("  Set sample rate");
      await _platform.invokeMethod('setSampleRate', <String, int>{'sampleRate': sampleRate});
      print("  Init Audio Recorder");
      await _platform.invokeMethod('initRecorder');
      print("  Start recording:");
      _run();
    }
    return _controller.stream;
  }

  Duration stop() {
    _isRecording = false;
    _platform.invokeMethod('releaseRecorder');
    _controller.close();
    return duration;
  }

  // runs asynchronously in a loop and stores data to the stream
  void _run() async {
    print("    Testing...");
    while(isRecording) {
      print("    ...test...");
      _controller.add(await _platform.invokeMethod('getByteArray'));
    }
  }

  // Changes the sample rate (only necessary for changing while recording - keep track of the buffer size!)
  set sampleRate(int sampleRate) {
    _platform.invokeMethod('setSampleRate', <String, int>{'sampleRate': sampleRate});
  }

  bool get isRecording => _isRecording;

  // Returns the duration since first start
  Duration get duration =>_timestamp.difference(DateTime.now());

  // Returns the amount of bytes per element (the length of one Uint8List)
  Future<int> get bufferSize async {
    return await _platform.invokeMethod('getBufferSize');
  }


  // Returns the platform version
  static Future<String> get platformVersion async {
    return await _platform.invokeMethod('getPlatformVersion');
  }
}
