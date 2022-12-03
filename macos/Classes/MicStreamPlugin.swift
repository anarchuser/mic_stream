import Cocoa
import FlutterMacOS

import AVFoundation

/// Notes:
/// 1. currently the only config supported is:
///     audioSource == DEFAULT
///     sampleRate == 48000
///     channelConfig == MONO
///     audioFormat == 16BIT
/// 2. AVAudioEngine is used to acquire the audio. The previous version uses 
///     AVCaptureAudioDataOutputSampleBufferDelegate, which records noise on
///     my machine
/// 3. The native audio sample is of float32 type. the samples are casted into
///     int16 to conform with the library definition


public class SwiftMicStreamPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = SwiftMicStreamPlugin()

    let micChannel = FlutterEventChannel(name:"aaron.code.com/mic_stream", binaryMessenger: registrar.messenger)
    micChannel.setStreamHandler(instance);

    let channel = FlutterMethodChannel(name: "aaron.code.com/mic_stream_method_channel", binaryMessenger: registrar.messenger)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  var sampleRate: Float64? = 48000;

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getSampleRate":
      result(self.sampleRate)
      break;
    case "getBitDepth":
      result(16) // always 16
      break;
    case "getBufferSize":
      result(-1) // not given, check received buffer length instead
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  var audioEngine = AVAudioEngine();
  var isRecording = false;

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    if (isRecording) {
      NSLog("onListen being called while recording")
      return FlutterError()
    }
    isRecording = true;

    // argument check
    let config = arguments as! [Int?];
    NSLog("received config \(config)")
    if (
      config.count == 4 &&
      config[0] == 0 &&     // audio source   must be DEFAULT
      config[1] == 48000 && // sampleRate     must be 48000 as tested on my machine
      config[2] == 16 &&    // channel config must be MONO
      config[3] == 2        // audio format   must be ENCODING_PCM_16BIT
    ) {} else {
      NSLog("warning: configuration not supported. The only supported config is (DEFAULT, 48000, MONO, 16BIT) ")
    }


    let input = audioEngine.inputNode
    let busID = 0
    let inputFormat = input.inputFormat(forBus: busID)

    sampleRate = inputFormat.sampleRate


    input.installTap(onBus: busID, bufferSize: 512, format: inputFormat) { (buffer, time) in
      guard let channelData = buffer.floatChannelData?[0] else { return }

      let floatArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
      //// used to findout the range of sample. it is even broader than -2 ... 2
      // NSLog("max \(floatArray.max()!) min \(floatArray.min()!)")
      var intArray = floatArray.map { val in 
        // clamp the val to -2.0 ... 2.0
        let clamped = min(max(-2.0, val), 2.0)
        return Int16(clamped * 16383) 
      }
      //// use the following to get length information
      // NSLog("\(intArray.count)")
      // NSLog("\(buffer.frameLength)")

      intArray.withUnsafeMutableBytes { unsafeMutableRawBufferPointer in
        let nBytes = Int(buffer.frameLength) * MemoryLayout<Int16>.size
        let unsafeMutableRawPointer = unsafeMutableRawBufferPointer.baseAddress!

        let data = Data(bytesNoCopy: unsafeMutableRawPointer, count: nBytes, deallocator: .none)
        events(FlutterStandardTypedData(bytes: data))
      }
    }

    try! audioEngine.start()
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError?  {
    NSLog("audio engine canceled");
    
    audioEngine.stop()
    audioEngine = AVAudioEngine()

    isRecording = false;
    return nil
  }
}
