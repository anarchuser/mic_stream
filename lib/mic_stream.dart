import 'dart:async';

import 'package:permission/permission.dart';

import 'package:flutter/services.dart';

// Adapts the official sensors plugin
// https://github.com/flutter/plugins/tree/master/packages/sensors

const int DEFAULT_AUDIO_SOURCE = 0;       // 'DEFAULT' source
const int DEFAULT_SAMPLE_RATE = 16000;
const int DEFAULT_CHANNELS_CONFIG = 16;   // MONO
const int DEFAULT_AUDIO_FORMAT = 3;       // 8BIT PCM

const EventChannel _microphoneEventChannel = EventChannel('aaron.code.com/mic_stream');

Permissions _permission;
var _microphone;

Future<bool> get permissionStatus async {
  _permission = (await Permission.getPermissionsStatus([PermissionName.Microphone])).first;
  if (_permission.permissionStatus != PermissionStatus.allow) _permission = (await Permission.requestPermissions([PermissionName.Microphone])).first;
  return (_permission.permissionStatus == PermissionStatus.allow);
}

dynamic microphone({int audioSource: DEFAULT_AUDIO_SOURCE, int sampleRate: DEFAULT_SAMPLE_RATE, int channelConfig: DEFAULT_CHANNELS_CONFIG, int audioFormat: DEFAULT_AUDIO_FORMAT}) async* {
  if (!(await permissionStatus)) throw (PlatformException);
  if (_microphone == null) _microphone = _microphoneEventChannel
      .receiveBroadcastStream([audioSource, sampleRate, channelConfig, audioFormat]);
  yield* _microphone;
}
