import 'dart:async';

import 'package:permission/permission.dart';

import 'package:flutter/services.dart';

// In reference to the implementation of the official sensors plugin
// https://github.com/flutter/plugins/tree/master/packages/sensors

enum AudioSource {DEFAULT, MIC, VOICE_UPLINK, VOICE_DOWNLINK, VOICE_CALL, CAMCORDER, VOICE_RECOGNITION, VOICE_COMMUNICATION, REMOTE_SUBMIX, UNPROCESSED, VOICE_PERFORMANCE}
enum ChannelConfig {CHANNEL_IN_MONO, CHANNEL_IN_STEREO}
enum AudioFormat {ENCODING_PCM_8BIT, ENCODING_PCM_16BIT}

const AudioSource _DEFAULT_AUDIO_SOURCE = AudioSource.DEFAULT;
const ChannelConfig _DEFAULT_CHANNELS_CONFIG = ChannelConfig.CHANNEL_IN_MONO;
const AudioFormat _DEFAULT_AUDIO_FORMAT = AudioFormat.ENCODING_PCM_8BIT;
const int _DEFAULT_SAMPLE_RATE = 16000;

const int _MIN_SAMPLE_RATE = 1;
const int _MAX_SAMPLE_RATE = 100000;

const EventChannel _microphoneEventChannel = EventChannel('aaron.code.com/mic_stream');

Permissions _permission;
Stream<dynamic> _microphone;

// This function manages the permission and ensures you're allowed to record audio
Future<bool> get permissionStatus async {
  _permission = (await Permission.getPermissionsStatus([PermissionName.Microphone])).first;
  if (_permission.permissionStatus != PermissionStatus.allow) _permission = (await Permission.requestPermissions([PermissionName.Microphone])).first;
  return (_permission.permissionStatus == PermissionStatus.allow);
}

// This function sets up a connection to the java backend (if not already available) and yields the elements in the stream
Stream<List<int>> microphone({AudioSource audioSource: _DEFAULT_AUDIO_SOURCE, int sampleRate: _DEFAULT_SAMPLE_RATE, ChannelConfig channelConfig: _DEFAULT_CHANNELS_CONFIG, AudioFormat audioFormat: _DEFAULT_AUDIO_FORMAT}) async* {
  if (sampleRate < _MIN_SAMPLE_RATE || sampleRate > _MAX_SAMPLE_RATE) throw (RangeError.range(sampleRate, _MIN_SAMPLE_RATE, _MAX_SAMPLE_RATE));
  if (!(await permissionStatus)) throw (PlatformException);
  if (_microphone == null) _microphone = _microphoneEventChannel
      .receiveBroadcastStream([audioSource.index, sampleRate, channelConfig == ChannelConfig.CHANNEL_IN_MONO ? 16 : 12, audioFormat == AudioFormat.ENCODING_PCM_8BIT ? 3 : 2]);
  yield* (audioFormat == AudioFormat.ENCODING_PCM_8BIT) ? _parseStream(_microphone) : _squashStream(_microphone);
}

// I'm getting a weird stream (_BroadcastStream<dynamic>), so to work with this, I cast it to Stream<List<int>>
// The first step converts _BroadcastStream to the normal Dart Stream
Stream<List<int>> _parseStream(Stream audio) {
  print(audio.runtimeType);
  return audio.map(_parseList);
}

// The second step casts the <dynamic> byte list to a List<int>
List<int> _parseList(var samples) {
  List<int> sampleList = samples;
  return sampleList;
}


// The following is needed for 16bit PCM transmission, as I can only transmit byte arrays from java to dart
// This function then squashes two bytes together to one short
Stream<List<int>> _squashStream(Stream audio) {
  return audio.map(_squashList);
}

// If someone reading this has a suggestion to do this more efficiently, let me know
List<int> _squashList(var byteSamples) {
  List<int> shortSamples = List();
  bool isFirstElement = true;
  int sum = 0;
  for (var sample in byteSamples) {
    if (isFirstElement) {
      sum += sample * 256;
    }
    else {
      sum += sample;
      shortSamples.add(sum - 32767);
      sum = 0;
    }
    isFirstElement = !isFirstElement;
  }
  return shortSamples;
}
