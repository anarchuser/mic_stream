package com.code.aaron.micstream;

import java.lang.reflect.Type;
import java.util.ArrayList;

import android.annotation.TargetApi;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** MicStreamPlugin
 *  In reference to flutters official sensors plugin
 *  and the example of the streams_channel (v0.2.2) plugin
 */

@TargetApi(16)  // Should be unnecessary, but isn't // fix build.gradle...?
public class MicStreamPlugin implements EventChannel.StreamHandler {
    private static final String MICROPHONE_CHANNEL_NAME = "aaron.code.com/mic_stream";

    /**
     * Plugin registration
     */
    public static void registerWith(Registrar registrar) {
        final EventChannel microphone = new EventChannel(registrar.messenger(), MICROPHONE_CHANNEL_NAME);
        microphone.setStreamHandler(new MicStreamPlugin());
    }

    private EventChannel.EventSink eventSink;

    // Audio recorder + initial values
    private static volatile AudioRecord recorder;

    private int AUDIO_SOURCE = MediaRecorder.AudioSource.DEFAULT;
    private int SAMPLE_RATE = 16000;
    private int CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO;
    private int AUDIO_FORMAT = AudioFormat.ENCODING_PCM_8BIT;
    private int BUFFER_SIZE = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT);

    // Runnable management
    private volatile boolean record = false;
    private volatile boolean isRecording = false;

    private final Runnable runnable = new Runnable() {
        @Override
        public void run() {
            isRecording = true;
            while (record) {
                // Read audio data into new short array
                byte[] data = new byte[BUFFER_SIZE];
                recorder.read(data, 0, BUFFER_SIZE);

                // push data into stream
                try {eventSink.success(data);}
                catch (IllegalArgumentException e) {
                    System.out.println("mic_stream: " + data.toString() + " is not valid!");
                    break;
                }
            }
            isRecording = false;
        }
    };

    @Override
    public void onListen(Object args, final EventChannel.EventSink eventSink) {
        if (isRecording) return;

        ArrayList<Integer> config = (ArrayList<Integer>) args;

        // Set parameters, if available
        switch(config.size()) {
            case 4:
                AUDIO_FORMAT = config.get(3);
            case 3:
                CHANNEL_CONFIG = config.get(2);
            case 2:
                SAMPLE_RATE = config.get(1);
            case 1:
                AUDIO_SOURCE = config.get(0);
            default:
                BUFFER_SIZE = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT);
        }

        this.eventSink = eventSink;

        // Try to initialize and start the recorder
        recorder = new AudioRecord(AUDIO_SOURCE, SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT, BUFFER_SIZE);
        if (recorder.getState() != AudioRecord.STATE_INITIALIZED) eventSink.error("-1", "PlatformError", null);
        recorder.startRecording();

        // Start runnable
        record = true;
        new Thread(runnable).start();
    }

    @Override
    public void onCancel(Object o) {
        // Stop runnable
        record = false;

        // Stop and reset audio recorder
        recorder.stop();
        recorder.release();
        recorder = null;
    }
}