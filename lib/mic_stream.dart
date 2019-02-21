import 'dart:async';

import 'package:typed_data/typed_data.dart';
import 'package:flutter/services.dart';

//TODO: Check if interval needed
//const int INTERVAL_IN_MICROSECONDS = 50;

/* Class handling the microphone */
class Microphone implements StreamController {
  static const _platform = const MethodChannel('mic_stream');
  final StreamController<Uint8Buffer> _controller;
  DateTime _timestamp;

  // Implemented Constructors
  Microphone() : _controller = new StreamController();
  Microphone.broadcast() : _controller = new StreamController.broadcast();

  // Implemented methods:
  close() => _controller.close();
  noSuchMethod(Invocation invocation) => _controller.noSuchMethod(invocation);
  toString() => _controller.toString();

  Stream<Uint8Buffer> start() {
    _timestamp = new DateTime.now();
    //TODO: Start Microphone here
    // => _controller.stream.add("Mic-input")
  }

  void pause() {
    try {
      //TODO: Pause Microphone here
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

  Duration duration() {
    try {
      return _timestamp.difference(DateTime.now());
    }
    finally {
      return new Duration();
    }
  }

}
