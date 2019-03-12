package com.code.aaron.mic_stream;

import java.util.ArrayList;

import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.os.Handler;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** MicStreamPlugin
 *  In reference to flutter sensors plugin
 */
public class MicStreamPlugin implements EventChannel.StreamHandler {
    private static final String MICROPHONE_CHANNEL_NAME = "aaron.code.com/mic_stream";

    /**
     * Plugin registration
     */
    public static void registerWith(Registrar registrar) {
        final EventChannel microphone = new EventChannel(registrar.messenger(), MICROPHONE_CHANNEL_NAME);
        microphone.setStreamHandler(new MicStreamPlugin());
    }

    private final Handler handler = new Handler();
    private final Runnable runnable = new Runnable() {
        @Override
        public void run() {
            isRunning = true;
            while(isRunning) {
                short[] data = new short[BUFFER_SIZE];
                recorder.read(data, 0, BUFFER_SIZE);
                eventSink.success(data);
            }
        }
    };

    private boolean isRunning = false;
    private int AUDIO_SOURCE = MediaRecorder.AudioSource.DEFAULT;
    private int SAMPLE_RATE = 16000;
    private int CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO;
    private int AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT;
    private int BUFFER_SIZE = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT);

    private EventChannel.EventSink eventSink;
    private AudioRecord recorder;

    @Override
    public void onListen(Object args, final EventChannel.EventSink eventSink) {
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
        recorder = new AudioRecord(AUDIO_SOURCE, SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT, BUFFER_SIZE);
        if (recorder.getState() != AudioRecord.STATE_INITIALIZED) eventSink.error("-1", "PlatformError", null);
        recorder.startRecording();
        if (recorder.getRecordingState() != AudioRecord.RECORDSTATE_RECORDING) eventSink.error("-2", "PlatformError", null);
        runnable.run();
    }

    @Override
    public void onCancel(Object o) {
        isRunning = false;
        eventSink.endOfStream();
        handler.removeCallbacks(runnable);
        recorder.release();
        recorder = null;
    }
}