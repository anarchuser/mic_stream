import 'dart:async';

import 'package:permission/permission.dart';
import 'package:permission_handler/permission_handler.dart'as handler;
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'dart:typed_data';

// In reference to the implementation of the official sensors plugin
// https://github.com/flutter/plugins/tree/master/packages/sensors

enum AudioSource {
  DEFAULT,
  MIC,
  VOICE_UPLINK,
  VOICE_DOWNLINK,
  VOICE_CALL,
  CAMCORDER,
  VOICE_RECOGNITION,
  VOICE_COMMUNICATION,
  REMOTE_SUBMIX,
  UNPROCESSED,
  VOICE_PERFORMANCE
}
enum ChannelConfig { CHANNEL_IN_MONO, CHANNEL_IN_STEREO }
enum AudioFormat { ENCODING_PCM_8BIT, ENCODING_PCM_16BIT }

const AudioSource _DEFAULT_AUDIO_SOURCE = AudioSource.DEFAULT;
const ChannelConfig _DEFAULT_CHANNELS_CONFIG = ChannelConfig.CHANNEL_IN_MONO;
const AudioFormat _DEFAULT_AUDIO_FORMAT = AudioFormat.ENCODING_PCM_8BIT;
const int _DEFAULT_SAMPLE_RATE = 16000;

const int _MIN_SAMPLE_RATE = 1;
const int _MAX_SAMPLE_RATE = 100000;

const EventChannel _microphoneEventChannel =
    EventChannel('aaron.code.com/mic_stream');

Permissions _permission;
Stream _microphone;

// This function manages the permission and ensures you're allowed to record audio
Future<bool> get permissionStatus async {
  if(Platform.isIOS) {
    var micStatus = await handler.Permission.microphone.request();
    return !(micStatus.isDenied);
  } 
  _permission =
      (await Permission.getPermissionsStatus([PermissionName.Microphone]))
          .first;
  if (_permission.permissionStatus != PermissionStatus.allow)
    _permission =
        (await Permission.requestPermissions([PermissionName.Microphone]))
            .first;
  return (_permission.permissionStatus == PermissionStatus.allow);
}

// This function sets up a connection to the java backend (if not already available) and yields the elements in the stream
/// Returns a stream of lists of ints with the properties declared with the parameters.
/// audioSource:     The device used to capture audio. The default let's the OS decide.
/// sampleRate:      The amount of samples per second. More samples give better quality at the cost of higher data transmission
/// channelConfig:   States whether audio is mono or stereo
/// audioFormat:     Switch between 8- and 16-bit PCM streams
Stream microphone(
    {AudioSource audioSource: _DEFAULT_AUDIO_SOURCE,
    int sampleRate: _DEFAULT_SAMPLE_RATE,
    ChannelConfig channelConfig: _DEFAULT_CHANNELS_CONFIG,
    AudioFormat audioFormat: _DEFAULT_AUDIO_FORMAT}) async* {
  if (sampleRate < _MIN_SAMPLE_RATE || sampleRate > _MAX_SAMPLE_RATE)
    throw (RangeError.range(sampleRate, _MIN_SAMPLE_RATE, _MAX_SAMPLE_RATE));
  if (!(await permissionStatus)) throw (PlatformException);

  if (_microphone == null) {
    var stream = _microphoneEventChannel.receiveBroadcastStream([
      audioSource.index,
      sampleRate,
      channelConfig == ChannelConfig.CHANNEL_IN_MONO ? 16 : 12,
      audioFormat == AudioFormat.ENCODING_PCM_8BIT ? 3 : 2
    ]).cast<Uint8List>();
    _microphone = (audioFormat == AudioFormat.ENCODING_PCM_16BIT) ? stream : stream.map((x) => x.buffer.asUint16List());
  }
  yield* _microphone;
}

