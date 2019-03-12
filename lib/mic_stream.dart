import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:simple_permissions/simple_permissions.dart';

import 'package:flutter/services.dart';

bool _isRecording = false;
bool _isRunning = false;

/* Class handling the microphone */
class Microphone implements StreamController {
  StreamController<Uint8List> _controller;  // Internal implemented Controller

  static const _platform = const MethodChannel('mic_stream');

  static const DEFAULT_AUDIO_SOURCE = 1;      // Mic

  static const DEFAULT_CHANNEL_CONFIG = 16;   // Mono

  static const DEFAULT_AUDIO_FORMAT = 3;      // 8-bit PCM

  static const DEFAULT_SAMPLE_RATE = 32000;   //in HZ
  static const MIN_SAMPLE_RATE = 1;
  static const MAX_SAMPLE_RATE = 96000;

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
  Stream<Uint8List> start(
      {int audioSource = DEFAULT_AUDIO_SOURCE, int sampleRate = DEFAULT_SAMPLE_RATE, int channelConfig = DEFAULT_CHANNEL_CONFIG, int audioFormat = DEFAULT_AUDIO_FORMAT}
      ) async* {
    if (!_isRecording) {
      _isRecording = true;
      _isRunning = true;

      print("mic_stream: Set timestamp");
      _timestamp = new DateTime.now();
      print(_timestamp);

      print("mic_stream: Ask for permission to record audio...");
      await SimplePermissions.requestPermission(Permission.RecordAudio);

      print("mic_stream: Set audio source");
      setAudioSource(audioSource);

      print("mic_stream: Set sample rate");
      setSampleRate(sampleRate);

      print("mic_stream: Set channel config");
      setChannelConfig(channelConfig);

      print("mic_stream: Set audio format");
      setAudioFormat(audioFormat);

      print("mic_stream: Update buffer size");
      _bufferSize = await bufferSize;

      print("mic_stream: Init Audio Recorder");
      try {
        await _platform.invokeMethod('initRecorder');
      }
      catch (PlatformException) {
        print("mic_stream: IOERROR - Could not initialize audio recorder");
        throw(StateError);
      }

      print("mic_stream: Start writing bytes to buffer");
      //Duration _sleep = new Duration(milliseconds: 1);
      while(_isRunning) {
        if (_isRecording) yield await _platform.invokeMethod('getByteArray');
      }

      _platform.invokeMethod('releaseRecorder');
      _controller.close();
    }
    else {
      throw("mic_stream: INITERROR - Microphone is already running!");
    }
  }

  void pause() {
    if (_isRecording) {
      _isRecording = false;
      print("mic_stream: Pause recording");
    }
    else {
      print("mic_stream: Already paused");
    }
  }

  void resume() {
    if (!_isRecording) {
      _isRecording = true;
      print("mic_stream: Resume recording");
    }
    else {
      print("mic_stream: Already recording");
    }
  }

  DateTime _reset() {
    pause();
    DateTime old = _timestamp;
    _timestamp = DateTime.now();
    resume();
    return old;
  }

  void stop() {
    _isRunning = false;
    _isRecording = false;
    //return duration;
  }

  // Getters
  Future<int> get bufferSize async => await _platform.invokeMethod('getBufferSize');
  //Duration get duration => -_timestamp.difference(new DateTime.now());
  bool get isRecording => _isRecording;
  static Future<String> get platformVersion async => await _platform.invokeMethod('getPlatformVersion');
  Stream<Uint8List> get stream => _controller.stream;

  // Setters
  setAudioSource (int audioSource) => _platform.invokeMethod('setAudioSource', <String, int>{'audioSource': audioSource});
  setChannelConfig (int channelConfig) => _platform.invokeMethod('setChannelConfig', <String, int>{'channelConfig': channelConfig});
  setAudioFormat (int audioFormat) => _platform.invokeMethod('setAudioFormat', <String, int>{'audioFormat': audioFormat});
  setSampleRate(int sampleRate) {
    if (sampleRate < MIN_SAMPLE_RATE || sampleRate > MAX_SAMPLE_RATE) throw(RangeError.range(sampleRate, MIN_SAMPLE_RATE, MAX_SAMPLE_RATE));
    _platform.invokeMethod('setSampleRate', <String, int>{'sampleRate': sampleRate});
  }

}
