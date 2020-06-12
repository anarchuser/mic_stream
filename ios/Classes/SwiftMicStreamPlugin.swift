import Flutter
import UIKit
import AVFoundation
import Dispatch

enum AudioFormat : Int { case ENCODING_PCM_8BIT, ENCODING_PCM_16BIT }
enum ChannelConfig : Int { case CHANNEL_IN_MONO	, CHANNEL_IN_STEREO }
enum AudioSource : Int { case DEFAULT }

public class SwiftMicStreamPlugin: NSObject, FlutterStreamHandler, FlutterPlugin, AVCaptureAudioDataOutputSampleBufferDelegate {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterEventChannel(name:"aaron.code.com/mic_stream", binaryMessenger: registrar.messenger())
        channel.setStreamHandler(SwiftMicStreamPlugin());
    }

    let isRecording:Bool = false;
    var AUDIO_FORMAT:AudioFormat = AudioFormat.ENCODING_PCM_16BIT;
    var CHANNEL_CONFIG:ChannelConfig = ChannelConfig.CHANNEL_IN_MONO;
    var SAMPLE_RATE:Int = 0;
    var AUDIO_SOURCE:AudioSource = AudioSource.DEFAULT;
    var BUFFER_SIZE = 0;

    var session : AVCaptureSession!

    public func onCancel(withArguments arguments:Any?) -> FlutterError?  {
        return nil
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        return nil
        if (isRecording) {
            return nil;
        }
    
        let config = arguments as! [Int?];

        // Set parameters, if available
        switch config.count {
            case 4:
                AUDIO_FORMAT = AudioFormat(rawValue:config[3]!)!;
            case 3:
                CHANNEL_CONFIG = ChannelConfig(rawValue:config[2]!)!;
            case 2:
                SAMPLE_RATE = config[1]!;
            case 1:
                AUDIO_SOURCE = AudioSource(rawValue:config[0]!)!;
                //if(AUDIO_SOURCE != 0)
                //    events(FlutterError(code: "-3",
                //                 message: "Currently only default AUDIO_SOURCE (id: 0) is supported"))
                //return nil
                    //              details: e)) // in case
            default:
              //do {
                BUFFER_SIZE = 1024; //try AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT);
              //} catch let e {
               //    events(FlutterError(code: "-3",
               //              message: "Invalid AudioRecord parameters",
               //              details: e)) // in case
              //}
            // this.eventSink = new MainThreadEventSink(eventSink);

            // // Try to initialize and start the recorder
            // recorder = new AudioRecord(AUDIO_SOURCE, SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT, BUFFER_SIZE);
            // if (recorder.getState() != AudioRecord.STATE_INITIALIZED) eventSink.error("-1", "PlatformError", null);
            // recorder.startRecording();
        }
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
                
                try AVAudioSession.sharedInstance().setPreferredSampleRate(try Double(SAMPLE_RATE))
                try AVAudioSession.sharedInstance().setPreferredInputNumberOfChannels(CHANNEL_CONFIG.rawValue + 1)
                try AVAudioSession.sharedInstance().setPreferredOutputNumberOfChannels(CHANNEL_CONFIG.rawValue + 1)
                let audioOutput = AVCaptureAudioDataOutput()
                
              //  audioOutput.audioSettings = [
                  
                   // AVLinearPCMBitDepthKey: AUDIO_FORMAT == AudioFormat.ENCODING_PCM_8BIT ? 8 : 16
//];
                audioOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global())

                if(self.session.canAddOutput(audioOutput)){
                    self.session.addOutput(audioOutput)
                }

                //supposed to start session not on UI queue coz it takes a while
                DispatchQueue.main.async {
                    print("starting captureSession")
                    self.session.startRunning()
                }
            } catch let e {
                print(e)
            }
        }
    }
    
    public func captureOutput(_            output      : AVCaptureOutput,
                   didOutput    sampleBuffer: CMSampleBuffer,
                   from         connection  : AVCaptureConnection) {

        var buffer: CMBlockBuffer? = nil

        // Needs to be initialized somehow, even if we take only the address
        let convenianceBuffer = AudioBuffer(mNumberChannels: 1, mDataByteSize: 0, mData: nil)
        var audioBufferList = AudioBufferList(mNumberBuffers: 1,
                                          mBuffers: convenianceBuffer)

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

        let abl = UnsafeMutableAudioBufferListPointer(&audioBufferList)

        for buffer in abl {
            let originRawPtr = buffer.mData
            let ptrDataSize = Int(buffer.mDataByteSize)

            // From raw pointer to typed Int16 pointer
            let buffPtrInt16 = originRawPtr?.bindMemory(to: Int16.self, capacity: ptrDataSize)

            // From pointer typed Int16 to pointer of [Int16]
                // So we can iterate on it simply
            let unsafePtrByteSize = ptrDataSize/Int16.bitWidth
            let samples = UnsafeMutableBufferPointer<Int16>(start: buffPtrInt16,
                                                        count: unsafePtrByteSize)
            print("got buffer")
        }
    }
}
