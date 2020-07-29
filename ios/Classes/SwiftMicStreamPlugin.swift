import Flutter
import UIKit
import AVFoundation
import Dispatch

enum AudioFormat : Int { case ENCODING_PCM_8BIT=3, ENCODING_PCM_16BIT=2 }
enum ChannelConfig : Int { case CHANNEL_IN_MONO=16	, CHANNEL_IN_STEREO=12 }
enum AudioSource : Int { case DEFAULT }

public class SwiftMicStreamPlugin: NSObject, FlutterStreamHandler, FlutterPlugin, AVCaptureAudioDataOutputSampleBufferDelegate {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterEventChannel(name:"aaron.code.com/mic_stream", binaryMessenger: registrar.messenger())
        let methodChannel = FlutterMethodChannel(name: "aaron.code.com/mic_stream_method_channel", binaryMessenger: registrar.messenger())
        let instance = SwiftMicStreamPlugin()
        channel.setStreamHandler(instance);
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
    }

    let isRecording:Bool = false;
    var CHANNEL_CONFIG:ChannelConfig = ChannelConfig.CHANNEL_IN_MONO;
    var SAMPLE_RATE:Int = 44100; // this is the sample rate the user wants
    var actualSampleRate:Float64?; // this is the actual hardware sample rate the device is using
    var AUDIO_FORMAT:AudioFormat = AudioFormat.ENCODING_PCM_16BIT; // this is the encoding/bit-depth the user wants
    var actualBitDepth:UInt32?; // this is the actual hardware bit-depth
    var AUDIO_SOURCE:AudioSource = AudioSource.DEFAULT;
    var BUFFER_SIZE = 4096;
    var eventSink:FlutterEventSink?;
    var session : AVCaptureSession!
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            case "getSampleRate":
                result(self.actualSampleRate)
                break;
            case "getBitDepth":
                result(self.actualBitDepth)
                break;
            case "getBufferSize":
                result(self.BUFFER_SIZE)
                break;
            default:
                result(FlutterMethodNotImplemented)
        }
    }
    
    public func onCancel(withArguments arguments:Any?) -> FlutterError?  {
        self.session?.stopRunning()
        return nil
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        
        if (isRecording) {
            return nil;
        }
    
        let config = arguments as! [Int?];
        // Set parameters, if available
        print(config);
        switch config.count {
            case 4:
                AUDIO_FORMAT = AudioFormat(rawValue:config[3]!)!;
                fallthrough
            case 3:
                CHANNEL_CONFIG = ChannelConfig(rawValue:config[2]!)!;
                if(CHANNEL_CONFIG != ChannelConfig.CHANNEL_IN_MONO) {
                    events(FlutterError(code: "-3",
                                                          message: "Currently only ChannelConfig CHANNEL_IN_MONO is supported", details:nil))
                    return nil
                }
                fallthrough
            case 2:
                SAMPLE_RATE = config[1]!;
                fallthrough
            case 1:
                AUDIO_SOURCE = AudioSource(rawValue:config[0]!)!;
                if(AUDIO_SOURCE != AudioSource.DEFAULT) {
                    events(FlutterError(code: "-3",
                                        message: "Currently only default AUDIO_SOURCE (id: 0) is supported", details:nil))
                    return nil
                }
            default:
                events(FlutterError(code: "-3",
                                  message: "At least one argument (AudioSource) must be provided ", details:nil))
                return nil
        }
        self.eventSink = events;
        startCapture();
        return nil;
    }
    
    func startCapture() {
    
        if let audioCaptureDevice : AVCaptureDevice = AVCaptureDevice.default(for:AVMediaType.audio) {

            self.session = AVCaptureSession()
            do {
                try audioCaptureDevice.lockForConfiguration()
                
                let audioInput = try AVCaptureDeviceInput(device: audioCaptureDevice)
                audioCaptureDevice.unlockForConfiguration()

                if(self.session.canAddInput(audioInput)){
                    self.session.addInput(audioInput)
                }
                
                
                let numChannels = CHANNEL_CONFIG == ChannelConfig.CHANNEL_IN_MONO ? 1 : 2
                // setting the preferred sample rate on AVAudioSession  doesn't magically change the sample rate for our AVCaptureSession
                // try AVAudioSession.sharedInstance().setPreferredSampleRate(Double(SAMPLE_RATE))
 
                // neither does setting AVLinearPCMBitDepthKey on audioOutput.audioSettings (unavailable on iOS)
                // 99% sure it's not possible to set streaming sample rate/bitrate
                // try AVAudioSession.sharedInstance().setPreferredOutputNumberOfChannels(numChannels)
                let audioOutput = AVCaptureAudioDataOutput()
                audioOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global())
              
                if(self.session.canAddOutput(audioOutput)){
                    self.session.addOutput(audioOutput)
                }

                DispatchQueue.main.async {
                    self.session.startRunning()
                }
            } catch let e {
                self.eventSink!(FlutterError(code: "-3",
                             message: "Error encountered starting audio capture, see details for more information.", details:e))
            }
        }
    }
    
    public func captureOutput(_            output      : AVCaptureOutput,
                   didOutput    sampleBuffer: CMSampleBuffer,
                   from         connection  : AVCaptureConnection) {	

        var buffer: CMBlockBuffer? = nil
        let numChannels:UInt32 = self.CHANNEL_CONFIG == ChannelConfig.CHANNEL_IN_MONO ? 1 : 2;
        let audioBuffer = AudioBuffer(mNumberChannels: numChannels, mDataByteSize: 0, mData: nil)
        var audioBufferList = AudioBufferList(mNumberBuffers: 1,
                                          mBuffers: audioBuffer)
        
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: &audioBufferList,
            bufferListSize: MemoryLayout<AudioBufferList>.size(ofValue: audioBufferList),
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: UInt32(kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment),
            blockBufferOut: &buffer
        )

        if(audioBufferList.mBuffers.mData == nil) {
            return
        }
        
        if(self.actualSampleRate == nil) {
            let fd = CMSampleBufferGetFormatDescription(sampleBuffer)
            let asbd:UnsafePointer<AudioStreamBasicDescription>? = CMAudioFormatDescriptionGetStreamBasicDescription(fd!)
            self.actualSampleRate = asbd?.pointee.mSampleRate
            self.actualBitDepth = asbd?.pointee.mBitsPerChannel
        }
        
        let data = Data(bytesNoCopy: audioBufferList.mBuffers.mData!, count: Int(audioBufferList.mBuffers.mDataByteSize), deallocator: .none)
        self.eventSink!(FlutterStandardTypedData(bytes: data))

    }
}
