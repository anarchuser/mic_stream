import 'dart:async';

import 'package:typed_data/typed_data.dart';
import 'package:flutter/services.dart';

/* Class handling the microphone */
class Microphone implements StreamController {
  static const _platform = const MethodChannel('mic_stream');
  static const DEFAULT_SAMPLE_RATE = 16000;
  bool isRecording = false;
  StreamController<Uint8Buffer> _controller;
  DateTime _timestamp;

  // Implemented Constructors
  Microphone() {
    _controller = new StreamController();
  }
  Microphone.broadcast() {
    _controller = new StreamController.broadcast();
  }

  // Implemented methods:
  close() => _controller.close();
  noSuchMethod(Invocation invocation) => _controller.noSuchMethod(invocation);
  toString() => _controller.toString();

  Stream<Uint8Buffer> start({int sampleRate = DEFAULT_SAMPLE_RATE}) {
    if (!isRecording) {
      _timestamp = new DateTime.now();
      _platform.invokeMethod(
          'setSampleRate', <String, int>{'sampleRate': sampleRate});
      _platform.invokeMethod('initRecorder');
    }
    return _controller.stream;
  }

  Duration stop() {
    if (isRecording) {
      isRecording = false;
      _controller.close();
    }
    return duration;
  }

  void initAudioStream() async {
    while(isRecording) {
      _controller.add(await _platform.invokeMethod('getByteArray'));
    }
  }

  static Future<String> get platformVersion async {
    return await _platform.invokeMethod('getPlatformVersion');
  }

  Duration get duration {
    return _timestamp.difference(DateTime.now());
  }

}
