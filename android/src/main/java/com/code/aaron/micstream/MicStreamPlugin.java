package com.code.aaron.micstream;

import android.media.AudioAttributes;
import android.media.AudioFormat;
import android.media.AudioRecord;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** MicStreamPlugin
 *  In reference to from https://stackoverflow.com/questions/33403656/stream-microphone-to-speakers-android
 */
public class MicStreamPlugin implements MethodCallHandler {

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "mic_stream");
        channel.setMethodCallHandler(new MicStreamPlugin());
    }

    /** Variables **/
    private AudioRecord recorder;
    private int AUDIO_SOURCE;
    private int CHANNEL_CONFIG;
    private int AUDIO_FORMAT;
    private int SAMPLE_RATE;
    private int BUFFER_SIZE;

    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "initRecorder":
                BUFFER_SIZE = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT);
                if (BUFFER_SIZE == AudioRecord.ERROR_BAD_VALUE) result.error("-1", "Bad buffer size value", null);

                recorder = new AudioRecord(AUDIO_SOURCE, SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT, BUFFER_SIZE);
                if (recorder.getState() == AudioRecord.STATE_UNINITIALIZED) result.error("-2", "Failed to initialize recorder", null);
                recorder.startRecording();
                break;

            case "getPlatformVersion":
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                return;

            case "getBufferSize":
                result.success(BUFFER_SIZE);
                return;

            case "getByteArray":
                byte data[] = new byte[BUFFER_SIZE];
                recorder.read(data, 0, BUFFER_SIZE);
                result.success(data);
                return;

            case "setSampleRate":
                SAMPLE_RATE = call.argument("sampleRate");
                break;

            case "setAudioSource":
                AUDIO_SOURCE = call.argument("audioSource");
                break;

            case "setChannelConfig":
                CHANNEL_CONFIG = call.argument("channelConfig");
                break;

            case "setAudioFormat":
                AUDIO_FORMAT = call.argument("audioFormat");
                break;

            case "releaseRecorder":
                recorder.stop();
                recorder.release();
                break;

            default:
                result.notImplemented();
                return;
        }
        result.success("Success");
    }
}