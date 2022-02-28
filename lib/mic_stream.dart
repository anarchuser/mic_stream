import 'dart:async';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart' as handler;
import 'package:flutter/services.dart';
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

class MicStream {
  static const AudioSource _DEFAULT_AUDIO_SOURCE = AudioSource.DEFAULT;
  static const ChannelConfig _DEFAULT_CHANNELS_CONFIG =
      ChannelConfig.CHANNEL_IN_MONO;
  static const AudioFormat _DEFAULT_AUDIO_FORMAT =
      AudioFormat.ENCODING_PCM_8BIT;
  static const int _DEFAULT_SAMPLE_RATE = 16000;

  static const int _MIN_SAMPLE_RATE = 1;
  static const int _MAX_SAMPLE_RATE = 100000;

  static const EventChannel _microphoneEventChannel =
      EventChannel('aaron.code.com/mic_stream');
  static const MethodChannel _microphoneMethodChannel =
      MethodChannel('aaron.code.com/mic_stream_method_channel');

  /// The actual sample rate used for streaming.  This may return zero if invoked without listening to the _microphone Stream
  static Future<double>? _sampleRate;
  static Future<double>? get sampleRate => _sampleRate;

  /// The actual bit depth used for streaming. This may return zero if invoked without listening to the _microphone Stream first.
  static Future<int>? _bitDepth;
  static Future<int>? get bitDepth => _bitDepth;

  static Future<int>? _bufferSize;
  static Future<int>? get bufferSize => _bufferSize;

  /// The configured microphone stream;
  static Stream<Uint8List>? _microphone;

  // This function manages the permission and ensures you're allowed to record audio
  static Future<bool> get permissionStatus async {
    if(Platform.isMacOS){
      return true;
    }
    var micStatus = await handler.Permission.microphone.request();
    return !micStatus.isDenied;
  }

  /// This function initializes a connection to the native backend (if not already available).
  /// Returns a Uint8List stream representing the captured audio.
  /// IMPORTANT - on iOS, there is no guarantee that captured audio will be encoded with the requested sampleRate/bitDepth.
  /// You must check the sampleRate and bitDepth properties of the MicStream object *after* invoking this method (though this does not need to be before listening to the returned stream).
  /// This is why this method returns a Uint8List - if you request a 16-bit encoding, you will need to check that
  /// the returned stream is actually returning 16-bit data, and if so, manually cast uint8List.buffer.asUint16List()
  /// audioSource:     The device used to capture audio. The default let's the OS decide.
  /// sampleRate:      The amount of samples per second. More samples give better quality at the cost of higher data transmission
  /// channelConfig:   States whether audio is mono or stereo
  /// audioFormat:     Switch between 8- and 16-bit PCM streams
  ///
  static Future<Stream<Uint8List>?> microphone(
      {AudioSource audioSource: _DEFAULT_AUDIO_SOURCE,
      int sampleRate: _DEFAULT_SAMPLE_RATE,
      ChannelConfig channelConfig: _DEFAULT_CHANNELS_CONFIG,
      AudioFormat audioFormat: _DEFAULT_AUDIO_FORMAT}) async {
    if (sampleRate < _MIN_SAMPLE_RATE || sampleRate > _MAX_SAMPLE_RATE)
      throw (RangeError.range(sampleRate, _MIN_SAMPLE_RATE, _MAX_SAMPLE_RATE));
    if (!(await permissionStatus))
      throw (PlatformException);

    _microphone = _microphone ??
        _microphoneEventChannel.receiveBroadcastStream([
          audioSource.index,
          sampleRate,
          channelConfig == ChannelConfig.CHANNEL_IN_MONO ? 16 : 12,
          audioFormat == AudioFormat.ENCODING_PCM_8BIT ? 3 : 2
        ]).cast<Uint8List>();

    // sampleRate/bitDepth should be populated before any attempt to consume the stream externally.
    // configure these as Completers and listen to the stream internally before returning
    // these will complete only when this internal listener is called
    StreamSubscription<Uint8List>? listener;
    var sampleRateCompleter = new Completer<double>();
    var bitDepthCompleter = new Completer<int>();
    var bufferSizeCompleter = new Completer<int>();
    _sampleRate = sampleRateCompleter.future;
    _bitDepth = bitDepthCompleter.future;
    _bufferSize = bufferSizeCompleter.future;

    listener = _microphone!.listen((x) async {
      await listener!.cancel();
      listener = null;
      sampleRateCompleter.complete(await _microphoneMethodChannel
          .invokeMethod("getSampleRate") as double?);
      bitDepthCompleter.complete(
          await _microphoneMethodChannel.invokeMethod("getBitDepth") as int?);
      bufferSizeCompleter.complete(
          await _microphoneMethodChannel.invokeMethod("getBufferSize") as int?);
    });

    return _microphone;
  }
}
