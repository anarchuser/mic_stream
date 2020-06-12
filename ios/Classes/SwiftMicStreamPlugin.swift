import Flutter
import UIKit

public class SwiftMicStreamPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterEventChannel(name:"aaron.code.com/mic_stream", binaryMessenger: registrar.messenger())
    channel.setStreamHandler(SwiftMicStreamPlugin());
      }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }

public class SwiftAudioStreamingRecorderPlugin: NSObject, FlutterPlugin, AVAudioRecorderDelegate {
  
  let isRecording:Bool = false;
  let AUDIO_FORMAT:Int = 0;
  let CHANNEL_CONFIG:Int = 0;
  let SAMPLE_RATE:Int = 0;
  let AUDIO_SOURCE = 0;
  let BUFFER_SIZE =0;

  var session : AVCaptureSession!

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {    

    if (isRecording) return;

        let config = args as? [Int!}];

        // Set parameters, if available
        switch config.count {
            case 4:
                AUDIO_FORMAT = config.get(3);
            case 3:
                CHANNEL_CONFIG = config.get(2);
            case 2:
                SAMPLE_RATE = config.get(1);
            case 1:
                AUDIO_SOURCE = config.get(0);
            default:
              do {
                try {
                    BUFFER_SIZE = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT);
                } catch (Exception e) {
                   events(FlutterError(code: "-3",
                             message: "Invalid AudioRecord parameters",
                             details: e)) // in case o
                }
        }

        // this.eventSink = new MainThreadEventSink(eventSink);

        // // Try to initialize and start the recorder
        // recorder = new AudioRecord(AUDIO_SOURCE, SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT, BUFFER_SIZE);
        // if (recorder.getState() != AudioRecord.STATE_INITIALIZED) eventSink.error("-1", "PlatformError", null);
        // recorder.startRecording();                  


         if let audioCaptureDevice : AVCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio) {

            self.session = AVCaptureSession()

            try audioCaptureDevice.lockForConfiguration()

            let audioInput = try AVCaptureDeviceInput(device: audioCaptureDevice)
            audioCaptureDevice.unlockForConfiguration()

            if(captureSession.canAddInput(audioInput)){
                captureSession.addInput(audioInput)
            }

            let audioOutput = AVCaptureAudioDataOutput()

            audioOutput.setSampleBufferDelegate(self, queue: GlobalUserInitiatedQueue)

            if(captureSession.canAddOutput(audioOutput)){
                captureSession.addOutput(audioOutput)
            }

            dispatch_async(GlobalUserInitiatedQueue) {
                self.captureSession.startRunning()
            }
        }
        return nil                                                                                                                                                                           
    }                              
  

func captureOutput(_            output      : AVCaptureOutput,
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

        // Average of each sample squared, then root squared
        let sumOfSquaredSamples = samples.map(Float.init).reduce(0) { $0 + $1*$1 }
        let averageOfSomething = sqrt(sumOfSquaredSamples / Float(samples.count))

        DispatchQueue.main.async {
            print("Calulcus of something: \(String(averageOfSomething))" )
        }
    }
}
}
