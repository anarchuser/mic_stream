package com.code.aaron.micstream;

import java.lang.Math;
import java.util.ArrayList;
import java.util.Arrays;

import android.annotation.TargetApi;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.os.Handler;
import android.os.Looper;

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

            // Repeatedly push audio samples to stream
            while (record) {

                // 8 Bit encoding
                if (AUDIO_FORMAT == AudioFormat.ENCODING_PCM_8BIT) {

                    // Read audio data into new byte array
                    byte[] data = new byte[BUFFER_SIZE];
                    recorder.read(data, 0, BUFFER_SIZE);

                    // push data into stream
                    try {
                        eventSink.success(data);
                    } catch (IllegalArgumentException e) {
                        System.out.println("mic_stream: " + Arrays.hashCode(data) + " is not valid!");
                        eventSink.error("-1", "Invalid Data", e);
                    }
                }

                // 16 Bit encoding
                else if (AUDIO_FORMAT == AudioFormat.ENCODING_PCM_16BIT) {

                    // Read audio data into new short array
                    short[] data_s = new short[BUFFER_SIZE];
                    byte[] data_b = new byte[BUFFER_SIZE * 2];
                    recorder.read(data_s, 0, BUFFER_SIZE);

                    // Split short into two bytes
                    for (int i = 0; i < BUFFER_SIZE; i++) {
                        data_b[2 * i] = (byte) Math.floor((data_s[i] + 32767) / 256.0);
                        data_b[2*i+1] = (byte) ((data_s[i] + 32767) % 256);
                    }

                    // push data into stream
                    try {
                        eventSink.success(data_b);
                    } catch (IllegalArgumentException e) {
                        System.out.println("mic_stream: " + Arrays.hashCode(data_b) + " is not valid!");
                        eventSink.error("-2", "Invalid Data", e);
                    }
                }
                else {
                    eventSink.error("-3", "Invalid Audio Format specified", null);
                    break;
                }
            }
            isRecording = false;
        }
    };

    /// Bug fix by https://github.com/Lokhozt
    /// following https://github.com/flutter/flutter/issues/34993
    private static class MainThreadEventSink implements EventChannel.EventSink {
        private EventChannel.EventSink eventSink;
        private Handler handler;

        MainThreadEventSink(EventChannel.EventSink eventSink) {
          this.eventSink = eventSink;
          handler = new Handler(Looper.getMainLooper());
        }

        @Override
        public void success(final Object o) {
          handler.post(new Runnable() {
            @Override
            public void run() {
              eventSink.success(o);
            }
          });
        }

        @Override
        public void error(final String s, final String s1, final Object o) {
          handler.post(new Runnable() {
            @Override
            public void run() {
              eventSink.error(s, s1, o);
            }
          });
        }

        @Override
        public void endOfStream() {
          handler.post(new Runnable() {
            @Override
            public void run() {
              eventSink.endOfStream();
            }
          });
        }
    }
    /// End

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
                try {
                    BUFFER_SIZE = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT);
                } catch (Exception e) {
                    eventSink.error("-3", "Invalid AudioRecord parameters", e);
                }
        }

        this.eventSink = new MainThreadEventSink(eventSink);

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

