import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

// In reference to the implementation of the official sensors plugin
// https://github.com/flutter/plugins/tree/master/packages/sensors

/// Source and type of audio recorded
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

/// Mono: Records using one microphone;
/// Stereo: Records using two spatially distant microphones (if applicable)
enum ChannelConfig {
  CHANNEL_IN_MONO,
  CHANNEL_IN_STEREO,
}

/// Bit depth.
/// 8 bit means each sample consists of 1 byte
/// 16 bit means each sample consists of 2 consecutive bytes, in little endian
/// 24 bit is currently not supported (cause nobody needs this)
/// 32 bit means each sample consists of 4 consecutive bytes, in little endian
/// float is the same as 32 bit, except it represents a floating point number
enum AudioFormat {
  ENCODING_PCM_8BIT,
  ENCODING_PCM_16BIT,
  ENCODING_PCM_FLOAT,
//ENCODING_PCM_24BIT_PACKED,
  ENCODING_PCM_32BIT
}

class MicStream {
  static bool _requestPermission = true;

  static const AudioSource DEFAULT_AUDIO_SOURCE = AudioSource.DEFAULT;
  static const ChannelConfig DEFAULT_CHANNELS_CONFIG =
      ChannelConfig.CHANNEL_IN_MONO;
  static const AudioFormat DEFAULT_AUDIO_FORMAT = AudioFormat.ENCODING_PCM_8BIT;
  static const int DEFAULT_SAMPLE_RATE = 16000;

  static const int _MIN_SAMPLE_RATE = 1;
  static const int _MAX_SAMPLE_RATE = 100000;

  static const EventChannel _microphoneEventChannel =
      EventChannel('aaron.code.com/mic_stream');
  static const MethodChannel _microphoneMethodChannel =
      MethodChannel('aaron.code.com/mic_stream_method_channel');

  /// The actual sample rate used for streaming. Only completes once a stream started.
  static Future<int> get sampleRate async {
    _memoisedSampleRate ??= await _microphoneFuture.then((_) {
      return _microphoneMethodChannel.invokeMethod("getSampleRate")
          .then((value) => (value as double).toInt());
    });
    return _memoisedSampleRate!;
  }
  static int? _memoisedSampleRate;

  /// The actual bit depth used for streaming. Only completes once a stream started.
  static Future<int> get bitDepth async {
    _memoisedBitDepth = await _microphoneFuture.then((_) {
      return _microphoneMethodChannel.invokeMethod("getBitDepth")
          .then((value) => value as int);
    });
    return _memoisedBitDepth!;
  }
  static int? _memoisedBitDepth;

  /// The amount of recorded data, per sample, in bytes. Only completes once a stream started.
  static Future<int> get bufferSize async {
    _memoisedBufferSize ??= await _microphoneFuture.then((_) {
      return _microphoneMethodChannel.invokeMethod("getBufferSize")
          .then((value) => value as int);
    });
    return _memoisedBufferSize!;
  }
  static int? _memoisedBufferSize;

  /// The configured microphone stream
  static Stream<Uint8List>? _microphone;
  static Completer _microphoneCompleter = new Completer();
  static Future get _microphoneFuture async {
    if (!_microphoneCompleter.isCompleted) {
      await _microphoneCompleter.future;
    }
  }

  /// The configured stream config
  static AudioSource? __audioSource;
  static int? __sampleRate;
  static ChannelConfig? __channelConfig;
  static AudioFormat? __audioFormat;

  /// This function manages the permission and ensures you're allowed to record audio
  static Future<bool> get permissionStatus async {
    if (Platform.isMacOS) {
      return true;
    }
    var micStatus = await handler.Permission.microphone.request();
    return !micStatus.isDenied && !micStatus.isPermanentlyDenied;
  }

  /// This function initializes a connection to the native backend (if not already available).
  /// Returns a Uint8List stream representing the captured audio.
  /// IMPORTANT - on iOS, there is no guarantee that captured audio will be encoded with the requested sampleRate/bitDepth.
  /// You must check the sampleRate and bitDepth properties of the MicStream object *after* invoking this method (though this does not need to be before listening to the returned stream).
  /// This is why this method returns a Uint8List - if you request a deeper encoding,
  /// you will need to manually convert the returned stream to the appropriate type,
  /// e.g., for 16 bit map each element using uint8List.buffer.asUint16List().
  /// Alternatively, you can call `toSampleStream(Stream<Uint8List>)` to transform the raw stream to a more easily usable stream.
  ///
  /// audioSource:     The device used to capture audio. The default let's the OS decide.
  /// sampleRate:      The amount of samples per second. More samples give better quality at the cost of higher data transmission
  /// channelConfig:   States whether audio is mono or stereo
  /// audioFormat:     Switch between 8, 16, 32 bit, and floating point PCM streams
  ///
  static Stream<Uint8List> microphone(
      {AudioSource? audioSource,
      int? sampleRate,
      ChannelConfig? channelConfig,
      AudioFormat? audioFormat}) {
    audioSource ??= DEFAULT_AUDIO_SOURCE;
    sampleRate ??= DEFAULT_SAMPLE_RATE;
    channelConfig ??= DEFAULT_CHANNELS_CONFIG;
    audioFormat ??= DEFAULT_AUDIO_FORMAT;

    if (sampleRate < _MIN_SAMPLE_RATE || sampleRate > _MAX_SAMPLE_RATE)
      return Stream.error(
          RangeError.range(sampleRate, _MIN_SAMPLE_RATE, _MAX_SAMPLE_RATE));

    final permissionStatus = _requestPermission
        ? Stream.fromFuture(MicStream.permissionStatus)
        : Stream.value(true);

    return permissionStatus.asyncExpand((grantedPermission) {
      if (!grantedPermission) {
        throw Exception('Microphone permission is not granted');
      }
      return _setupMicStream(
        audioSource!,
        sampleRate!,
        channelConfig!,
        audioFormat!,
      );
    });
  }

  static Stream<Uint8List> _setupMicStream(
    AudioSource audioSource,
    int sampleRate,
    ChannelConfig channelConfig,
    AudioFormat audioFormat,
  ) {
    // If first time or configs have changed reinitialise audio recorder
    if (audioSource != __audioSource ||
        sampleRate != __sampleRate ||
        channelConfig != __channelConfig ||
        audioFormat != __audioFormat) {

      // Reset runtime values
      if (_microphone != null) {
        var _tmpCompleter = _microphoneCompleter;
        _microphoneCompleter = new Completer();
        _tmpCompleter.complete(_microphoneCompleter.future);
      }
      _memoisedSampleRate = null;
      _memoisedBitDepth = null;
      _memoisedBufferSize = null;

      // Reset configuration
      __audioSource = audioSource;
      __sampleRate = sampleRate;
      __channelConfig = channelConfig;
      __audioFormat = audioFormat;

      // Reset audio stream
      _microphone = _microphoneEventChannel.receiveBroadcastStream([
        audioSource.index,
        sampleRate,
        channelConfig == ChannelConfig.CHANNEL_IN_MONO ? 16 : 12,
        switch (audioFormat) {
        AudioFormat.ENCODING_PCM_8BIT => 3,
        AudioFormat.ENCODING_PCM_16BIT => 2,
//      AudioFormat.ENCODING_PCM_24BIT_PACKED => 21,
        AudioFormat.ENCODING_PCM_32BIT => 22,
        AudioFormat.ENCODING_PCM_FLOAT => 4
        }
      ]).cast<Uint8List>();
    }

    // Check for errors
    if (_microphone == null) {
      if (!_microphoneCompleter.isCompleted) {
        _microphoneCompleter.completeError(StateError);
      }
      return Stream.error(StateError);
    }

    // Force evaluation of actual config values
    _microphone!.first.then((value) {
      if (!_microphoneCompleter.isCompleted) {
        _microphoneCompleter.complete();
      }
    });

    return _microphone!;
  }

  /// StreamTransformer to convert a raw Stream<Uint8List> to num streams, e.g.:
  /// 8 bit PCM + mono => Stream<int>, where each int is a *signed* byte, i.e., [-2^7; 2^7)
  /// 16 bit PCM + stereo => Stream<(int, int)>, where each int is a *signed* byte, i.e., [-2^15; 2^15)
  /// float bit PCM + stereo => Stream<(double, double)>, with double e [-1.0; 1.0), and 32 bit precision
  static StreamTransformer<Uint8List, dynamic> get toSampleStream =>
      // TODO: check bitDepth here already and call different handlers for every possible combination
      (__channelConfig == ChannelConfig.CHANNEL_IN_MONO)
          ? new StreamTransformer.fromHandlers(handleData: _expandUint8ListMono)
          : new StreamTransformer.fromHandlers(handleData: _expandUint8ListStereo);

  static void _expandUint8ListMono(Uint8List raw, EventSink sink) async {
    switch (await bitDepth) {
      case 8: raw.buffer.asInt8List().forEach(sink.add); break;
      case 16: raw.buffer.asInt16List().forEach(sink.add); break;
      case 24: sink.addError("24 bit PCM encoding is not supported"); break;
      case 32: (__audioFormat == AudioFormat.ENCODING_PCM_32BIT)
          ? raw.buffer.asInt32List().forEach(sink.add)
          : raw.buffer.asFloat32List().forEach(sink.add);
        break;
      default:
        sink.addError("No stream configured yet");
    }
  }
  static void _expandUint8ListStereo(Uint8List raw, EventSink sink) async {
    switch (await bitDepth) {
      case 8: _listToPairList(raw.buffer.asInt8List()).forEach(sink.add); break;
      case 16: _listToPairList(raw.buffer.asInt16List()).forEach(sink.add); break;
      case 24: sink.addError("24 bit PCM encoding is not supported"); break;
      case 32: (__audioFormat == AudioFormat.ENCODING_PCM_32BIT)
          ? _listToPairList(raw.buffer.asInt32List()).forEach(sink.add)
          : _listToPairList(raw.buffer.asFloat32List()).forEach(sink.add);
      break;
      default:
        sink.addError("No stream configured yet");
    }
  }
  static List<(num, num)> _listToPairList(List<num> mono) {
    List<(num, num)> stereo = List.empty(growable: true);
    num? first;
    for (num sample in mono) {
      if (first == null) {
        first = sample;
      }
      else {
        stereo.add((first, sample));
        first = null;
      }
    }
    return stereo;
  }

  static void clean() {
    _microphoneMethodChannel.invokeMethod("clean");
  }

  /// Updates flag to determine whether to request audio recording permission. Set to false to disable dialogue, set to true (default) to request permission if necessary
  static bool shouldRequestPermission(bool requestPermission) {
    return _requestPermission = requestPermission;
  }
}
