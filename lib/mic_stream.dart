import 'dart:async';
import 'dart:typed_data';

import 'package:simple_permissions/simple_permissions.dart';

import 'package:flutter/services.dart';

/* Class handling the microphone */
class Microphone implements StreamController {
  StreamController<Uint8List> _controller;  // Internal implemented Controller

  static const _platform = const MethodChannel('mic_stream');
  static const DEFAULT_SAMPLE_RATE = 16000;
  static const MIN_SAMPLE_RATE = 1;
  static const MAX_SAMPLE_RATE = 16000;

  bool _isRecording = false;
  bool _isRunning = false;
  int _bufferSize;
  DateTime _timestamp;

  // Implemented Constructors
  Microphone() : _controller = new StreamController();
  Microphone.broadcast() : _controller = new StreamController.broadcast();

  // Implemented methods:
  close() => _controller.close();
  noSuchMethod(Invocation invocation) => _controller.noSuchMethod(invocation);
  toString() => _controller.toString();

  // Starts and returns an audio stream from the microphone, which is given back as Uint8List; each element has the length of .bufferSize
  // Throws an ArgumentError if Sample Rate is not between 1 and 16000
  Future<Stream<Uint8List>> start({int sampleRate = DEFAULT_SAMPLE_RATE}) async {
    if (!_isRecording) {
      _isRecording = true;

      print("Ask for permission to record audio...");
      await SimplePermissions.requestPermission(Permission.RecordAudio);

      print("mic_stream: Set timestamp");
      _timestamp = new DateTime.now();

      print("mic_stream: Set sample rate");
      await _platform.invokeMethod('setSampleRate', <String, int>{'sampleRate': sampleRate});

      print("mic_stream: Init Audio Recorder");
      try {
        await _platform.invokeMethod('initRecorder');
      }
      catch (PlatformException) {
        print("mic_stream: IOERROR - Could not initialize audio recorder");
        throw(StateError);
      }

      print("mic_stream: Update buffer size");
      _bufferSize = await bufferSize;

      print("mic_stream: Start recording:");
      _run();

      return _controller.stream;
    }
    else {
      throw("mic_stream: INITERROR - Microphone is already running!");
    }
  }

  void pause() {
    _isRecording = false;
    print("mic_stream: Pause recording");
  }

  void resume() {
    _isRecording = true;
    print("mic_Stream: Resume recording");
    _run();
  }

  Duration stop() {
    _isRecording = false;
    while (_isRunning) continue;
    _platform.invokeMethod('releaseRecorder');
    _controller.close();
    return duration;
  }

  // runs asynchronously in a loop and stores data to the stream
  void _run() async {

    print("mic_stream: Writing Bytes to buffer...");
    _isRunning = true;
    while(_isRecording) {
      try {
        _controller.add(await _platform.invokeMethod('getByteArray'));
      } finally {}
    }
    print("mic_stream: Stop writing Bytes");
    _isRunning = false;
  }

  // Changes the sample rate (only necessary for changing while recording - might cause unintended behaviour)
  set sampleRate(int sampleRate) {
    if (sampleRate < MIN_SAMPLE_RATE || sampleRate > MAX_SAMPLE_RATE) throw(RangeError.range(sampleRate, MIN_SAMPLE_RATE, MAX_SAMPLE_RATE));
    _platform.invokeMethod('setSampleRate', <String, int>{'sampleRate': sampleRate});
  }

  bool get isRecording => _isRecording;

  // Returns the duration since first start
  Duration get duration =>_timestamp.difference(DateTime.now());

  // Returns the amount of bytes per element (the length of one Uint8List)
  Future<int> get bufferSize async {
    return await _platform.invokeMethod('getBufferSize');
  }

  Stream<Uint8List> get stream => _controller.stream;

  // Returns the platform version
  static Future<String> get platformVersion async {
    return await _platform.invokeMethod('getPlatformVersion');
  }
}
