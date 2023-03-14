import Flutter
//import UIKit
import AVFoundation
import Dispatch
import AVFAudio
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
    var audioSession: AVAudioSession!
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            case "getSampleRate":
                result(self.actualSampleRate)//call the actual sample rate
                break;
            case "getBitDepth":
                result(self.actualBitDepth)
                break;
            case "getBufferSize":
                result(Int(self.audioSession.ioBufferDuration*self.audioSession.sampleRate))//calculate the true buffer size
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
        //print("this is config: \(config)")
        switch config.count {
            case 4:
                AUDIO_FORMAT = AudioFormat(rawValue:config[3]!)!;
                if(AUDIO_FORMAT != AudioFormat.ENCODING_PCM_16BIT) {
                    events(FlutterError(code: "-3",
                                                          message: "Currently only AudioFormat ENCODING_PCM_16BIT is supported", details:nil))
                    return nil
                }
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
                if(SAMPLE_RATE<8000 || SAMPLE_RATE>48000) {
                    events(FlutterError(code: "-3",
                                                          message: "iPhone only sample rates between 8000 and 48000 are supported", details:nil))
                    return nil
                }
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
            self.audioSession=AVAudioSession.sharedInstance()
            do {
                //magic word
                //This will allow developers to specify sample rates, etc.
                try session.automaticallyConfiguresApplicationAudioSession = false
                
                try audioCaptureDevice.lockForConfiguration()

                try audioSession.setCategory(AVAudioSession.Category.record,mode: .measurement)

                try audioSession.setPreferredSampleRate(Double(SAMPLE_RATE))

                //Calculate the time required for BufferSize
                let preferredIOBufferDuration: TimeInterval = 1.0 / audioSession.sampleRate * Double(self.BUFFER_SIZE)
                try audioSession.setPreferredIOBufferDuration(Double(preferredIOBufferDuration))

                //it does not seem like this is working
                //let numChannels = CHANNEL_CONFIG == ChannelConfig.CHANNEL_IN_MONO ? 1 : 2
                //try audioSession.setPreferredInputNumberOfChannels(1)


                // print("this is the session sample rate: \(audioSession.sampleRate)")
                // print("this is the session preferred sample rate: \(audioSession.preferredSampleRate)")
                // print("this is the session preferred IOBufferDuration: \(audioSession.preferredIOBufferDuration)")
                // print("this is the session IOBufferDuration: \(audioSession.ioBufferDuration)")
                // print("this is the session preferred input number of channels: \(audioSession.preferredInputNumberOfChannels)")
                // print("this is the session input number of channels: \(audioSession.inputNumberOfChannels)")

                try audioSession.setActive(true)
                
                
                let audioInput = try AVCaptureDeviceInput(device: audioCaptureDevice)
                
                
                audioCaptureDevice.unlockForConfiguration()

                if(self.session.canAddInput(audioInput)){
                    self.session.addInput(audioInput)
                }
                
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
                // print("Error encountered starting audio capture, see details for more information.")
                // print(e)
                
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
        //print(actualSampleRate)
        //print(audioSession.sampleRate)
        let data = Data(bytesNoCopy: audioBufferList.mBuffers.mData!, count: Int(audioBufferList.mBuffers.mDataByteSize), deallocator: .none)
        
        self.eventSink!(FlutterStandardTypedData(bytes: data))

    }
}
