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

  Stream<Uint8Buffer> start() {
    try {
      _timestamp = new DateTime.now();
      _controller.addStream(
          new Stream<Uint8Buffer>.fromFuture(_platform.invokeMethod('play')));
    }
    finally {
      //TODO: Do something fancy here
    }
    return _controller.stream;
  }

  void pause() {
    try {
      _platform.invokeMethod('pause');
    }
    finally {
      //TODO: Do something fancy here
    }
  }

  Stream<Uint8Buffer> resume() {
    try {
      _controller.addStream(new Stream<Uint8Buffer>.fromFuture(_platform.invokeMethod('resume')));
    }
    finally {
      //TODO: Do something fancy here
    }
    return _controller.stream;
  }

  Duration stop() {
    try {
      _platform.invokeMethod('stop');
      _controller.close();
    }
    finally {
      //TODO: Do something fancy here
    }
    return duration();
  }

  static Future<String> getPlatformVersion() async {
    return await _platform.invokeMethod('getPlatformVersion');
  }

  Duration duration() {
    return _timestamp.difference(DateTime.now());
  }

}
