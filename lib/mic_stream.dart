import 'dart:async';

import 'package:typed_data/typed_data.dart';
import 'package:flutter/services.dart';

//TODO: Check if interval needed
//const int INTERVAL_IN_MICROSECONDS = 50;

/* Class handling the microphone */
class Microphone implements StreamController {
  static const _platform = const MethodChannel('mic_stream');
  StreamController<Uint8Buffer> _controller;
  DateTime _timestamp;
  Stream<Uint8Buffer> _stream;

  // Implemented Constructors
  Microphone() {
    _controller = new StreamController();
    _stream = _controller.stream;
  }
  Microphone.broadcast() {
    _controller = new StreamController.broadcast();
    _stream = _controller.stream;
  }

  // Implemented methods:
  close() => _controller.close();
  noSuchMethod(Invocation invocation) => _controller.noSuchMethod(invocation);
  toString() => _controller.toString();

  Future<Stream<Uint8Buffer>> start() async {
    _timestamp = new DateTime.now();
    _controller.addStream(await _platform.invokeMethod('play'));
    return _stream;
  }

  void pause() {
    try {
      _platform.invokeMethod('pause');
    }
    finally {
      //TODO: Do something fancy here
      return;
    }
  }

  void resume() {
    try {
      //TODO: Resume Microphone here
    }
    finally {
      //TODO: Do something fancy here
      return;
    }
  }

  Duration stop() {
    //TODO: Stop Microphone here
    return duration();
  }

  static Future<String> getPlatformVersion() async {
    return await _platform.invokeMethod('getPlatformVersion');
  }

  Duration duration() {
    try {
      return _timestamp.difference(DateTime.now());
    }
    finally {
      return new Duration();
    }
  }

}
