package com.code.aaron.micstream;

import java.lang.Math;
import java.util.ArrayList;
import java.util.Arrays;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.os.Handler;
import android.os.Looper;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** MicStreamPlugin
 *  In reference to flutters official sensors plugin
 *  and the example of the streams_channel (v0.2.2) plugin
 */

@TargetApi(16)  // Should be unnecessary, but isn't // fix build.gradle...?
public class MicStreamPlugin implements FlutterPlugin, EventChannel.StreamHandler, MethodCallHandler {
    private static final String MICROPHONE_CHANNEL_NAME = "aaron.code.com/mic_stream";
    private static final String MICROPHONE_METHOD_CHANNEL_NAME = "aaron.code.com/mic_stream_method_channel";

    /// New way of registering plugin
    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        registerWith(binding.getBinaryMessenger());
    }

    /// Cleanup after connection loss to flutter
    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        onCancel(null);
    }

    /// Deprecated way of registering plugin
    public void registerWith(Registrar registrar) {
        registerWith(registrar.messenger());
    }

    private void registerWith(BinaryMessenger messenger) {
        final EventChannel microphone = new EventChannel(messenger, MICROPHONE_CHANNEL_NAME);
        microphone.setStreamHandler(this);
        MethodChannel methodChannel = new MethodChannel(messenger, MICROPHONE_METHOD_CHANNEL_NAME);
        methodChannel.setMethodCallHandler(this);
    }

    private EventChannel.EventSink eventSink;

    // Audio recorder + initial values
    private static volatile AudioRecord recorder = null;

    private int AUDIO_SOURCE = MediaRecorder.AudioSource.DEFAULT;
    private int SAMPLE_RATE = 8000;
    private int actualSampleRate;
    private int CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO;
    private int AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT;
    private int actualBitDepth;
    private int BUFFER_SIZE = bufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT);//AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT);

    short[] buffer1000ms = new short[8000];
    float[] floatBuffer1000ms = new float[8000];
    short[] phaseBuffer = new short[8000];
    float[] floatPhaseBuffer = new float[8000];
    short[] buffer = new short[400];
    float[] floatBuffer = new float[400];
    short[] temp = new short[buffer1000ms.length];
    float[] floatTemp = new float[buffer1000ms.length];

    int numSamples;
    int mTotalSamples = 0;
    int mPhaseTotalSamples = 0;




    // Runnable management
    private volatile boolean record = false;
    private volatile boolean isRecording = false;

    // Method channel handlers to get sample rate / bit-depth
    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "getSampleRate":
                result.success((double)this.actualSampleRate); // cast to double just for compatibility with the iOS version
                break;
            case "getBitDepth":
                result.success(this.actualBitDepth);
                break;
            case "getBufferSize":
                result.success(this.BUFFER_SIZE);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    @SuppressLint("MissingPermission")
    private void initRecorder () {
        // Try to initialize and start the recorder
        recorder = new AudioRecord(AUDIO_SOURCE, SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT, BUFFER_SIZE);
        if (recorder.getState() != AudioRecord.STATE_INITIALIZED) {
            eventSink.error("-1", "PlatformError", null);
            return;
        }

        recorder.startRecording();
    }

    private final Runnable runnable = new Runnable() {
        @Override
        public void run() {
            if (recorder == null) initRecorder();
            isRecording = true;

            actualSampleRate = recorder.getSampleRate();
            actualBitDepth = (recorder.getAudioFormat() == AudioFormat.ENCODING_PCM_8BIT ? 8 : 16);

            // Wait until recorder is initialised
            while (recorder == null || recorder.getRecordingState() != AudioRecord.RECORDSTATE_RECORDING);

            // Repeatedly push audio samples to stream
            while (record) {
                numSamples = recorder.read(buffer, 0, buffer.length);
                for(int i=0;i<buffer.length;i++){
                    floatBuffer[i] = lpf_x(buffer[i]);
                }

                System.arraycopy(floatBuffer,0,floatTemp,floatTemp.length-floatBuffer.length,floatBuffer.length);
                System.arraycopy(floatBuffer1000ms,floatBuffer.length,floatTemp,0,floatBuffer1000ms.length-floatBuffer.length);
                floatBuffer1000ms=floatTemp;
                mTotalSamples += numSamples;
                

                // Read audio data into new byte array
                //byte[] data = new byte[BUFFER_SIZE];
                //recorder.read(data, 0, BUFFER_SIZE);

                // push data into stream
                try {
                    eventSink.success(floatBuffer);
                } catch (IllegalArgumentException e) {
                    System.out.println("mic_stream: " + Arrays.hashCode(floatBuffer) + " is not valid!");
                    eventSink.error("-1", "Invalid Data", e);
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
        
        if(AUDIO_FORMAT != AudioFormat.ENCODING_PCM_8BIT && AUDIO_FORMAT != AudioFormat.ENCODING_PCM_16BIT) {
            eventSink.error("-3", "Invalid Audio Format specified", null);
            return;
        }

        this.eventSink = new MainThreadEventSink(eventSink);

        // Start runnable
        record = true;
        new Thread(runnable).start();
    }

    @Override
    public void onCancel(Object o) {
        // Stop runnable
        record = false;
        while (isRecording);
        if(recorder != null) {
            // Stop and reset audio recorder
            recorder.stop();
            recorder.release();
        }
        recorder = null;
    }

    private int bufferSize(int sampleRateInHz, int channelConfig,int audioFormat) {
        int buffSize = AudioRecord.getMinBufferSize(sampleRateInHz, channelConfig,audioFormat);
        if (buffSize < sampleRateInHz) {
            buffSize = sampleRateInHz;
        }
        return buffSize;
    }

    final double f0 = 500;
    final double fs = 8000;
    final double w0 = 2* Math.PI*f0/fs;
    final double Q = 1/ Math.sqrt(2);
    final double alpha = Math.sin(w0)/(2*Q);
    final double b0 =  (1 - Math.cos(w0))/2;
    final double b1 =   1 - Math.cos(w0);
    final double b2 =  (1 - Math.cos(w0))/2;
    final double a0 =   1 + alpha;
    final double a1 =  -2 * Math.cos(w0);
    final double a2 =   1 - alpha;
    final float[] results = new float[8000];
    final float b0a0 = (float)(b0/a0);
    final float b1a0 = (float)(b1/a0);
    final float b2a0 = (float)(b2/a0);
    final float a1a0 = (float)(a1/a0);
    final float a2a0 = (float)(a2/a0);

    short x_1 = 0, x_2 = 0;
    float y_1 = 0, y_2 = 0;
    public float lpf_x(short x) {

        float y = (b0a0)*x + (b1a0)*x_1 + (b2a0)*x_2
                - (a1a0)*y_1 - (a2a0)*y_2;

        x_2 = x_1;
        y_2 = y_1;
        x_1 = x;
        y_1 = y;
        return y;
    }
}

