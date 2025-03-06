package com.code.aaron.micstream;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;

import android.annotation.SuppressLint;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class MicStreamPlugin implements FlutterPlugin, EventChannel.StreamHandler, MethodCallHandler {
    private static final String MICROPHONE_CHANNEL_NAME = "aaron.code.com/mic_stream";
    private static final String MICROPHONE_METHOD_CHANNEL_NAME = "aaron.code.com/mic_stream_method_channel";

    private EventChannel eventChannel;
    private MethodChannel methodChannel;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        registerWith(binding.getBinaryMessenger());
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        onCancel(null);
        eventChannel.setStreamHandler(null);
        methodChannel.setMethodCallHandler(null);
    }

    private void registerWith(BinaryMessenger messenger) {
        eventChannel = new EventChannel(messenger, MICROPHONE_CHANNEL_NAME);
        eventChannel.setStreamHandler(this);
        methodChannel = new MethodChannel(messenger, MICROPHONE_METHOD_CHANNEL_NAME);
        methodChannel.setMethodCallHandler(this);
    }

    private EventChannel.EventSink eventSink;

    // Audio recorder + initial values
    private static volatile AudioRecord recorder = null;

    private int AUDIO_SOURCE = MediaRecorder.AudioSource.DEFAULT;
    private int SAMPLE_RATE = 16000;
    private int actualSampleRate;
    private int CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO;
    private int AUDIO_FORMAT = AudioFormat.ENCODING_PCM_8BIT;
    private int actualBitDepth;
    private int BUFFER_SIZE = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT);

    // Runnable management
    private volatile boolean record = false;
    private volatile boolean isRecording = false;

    @Override
    public void onMethodCall(MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "getSampleRate":
                result.success((double) this.actualSampleRate);
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
    private void initRecorder() {
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
            switch (recorder.getAudioFormat()) {
                case AudioFormat.ENCODING_PCM_8BIT:
                    actualBitDepth = 8;
                    break;
                case AudioFormat.ENCODING_PCM_16BIT:
                    actualBitDepth = 16;
                    break;
                case AudioFormat.ENCODING_PCM_32BIT:
                    actualBitDepth = 32;
                    break;
                case AudioFormat.ENCODING_PCM_FLOAT:
                    actualBitDepth = 32;
                    break;
            }

            while (recorder == null || recorder.getRecordingState() != AudioRecord.RECORDSTATE_RECORDING);

            ByteBuffer data = ByteBuffer.allocateDirect(BUFFER_SIZE);
            ByteOrder nativeOrder = ByteOrder.nativeOrder();
            data.order(nativeOrder);
            System.out.println("mic_stream: Using native byte order " + nativeOrder);

            while (record) {
                recorder.read(data, BUFFER_SIZE, AudioRecord.READ_BLOCKING);
                try {
                    eventSink.success(data.array());
                } catch (IllegalArgumentException e) {
                    System.out.println("mic_stream: " + data + " is not valid!");
                    eventSink.error("-1", "Invalid Data", e);
                }
                data.clear();
            }
            isRecording = false;
        }
    };

    private static class MainThreadEventSink implements EventChannel.EventSink {
        private final EventChannel.EventSink eventSink;
        private final Handler handler;

        MainThreadEventSink(EventChannel.EventSink eventSink) {
            this.eventSink = eventSink;
            handler = new Handler(Looper.getMainLooper());
        }

        @Override
        public void success(final Object o) {
            handler.post(() -> eventSink.success(o));
        }

        @Override
        public void error(final String s, final String s1, final Object o) {
            handler.post(() -> eventSink.error(s, s1, o));
        }

        @Override
        public void endOfStream() {
            handler.post(() -> eventSink.endOfStream());
        }
    }

    @Override
    public void onListen(Object args, final EventChannel.EventSink eventSink) {
        if (isRecording) return;

        if (!(args instanceof ArrayList)) {
            eventSink.error("-4", "Invalid parameter type. Expected ArrayList.", null);
            return;
        }

        @SuppressWarnings("unchecked")
        ArrayList<Integer> config = (ArrayList<Integer>) args;

        try {
            AUDIO_SOURCE = config.get(0);
            SAMPLE_RATE = config.get(1);
            CHANNEL_CONFIG = config.get(2);
            AUDIO_FORMAT = config.get(3);
            BUFFER_SIZE = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT);
        } catch (IndexOutOfBoundsException e) {
            eventSink.error("-4", "Invalid number of parameters. Expected 4, got " + config.size(), e);
        } catch (Exception e) {
            eventSink.error("-3", "Invalid AudioRecord parameters", e);
        }

        this.eventSink = new MainThreadEventSink(eventSink);

        record = true;
        new Thread(runnable).start();
    }

    @Override
    public void onCancel(Object o) {
        record = false;
        while (isRecording);
        if (recorder != null) {
            recorder.stop();
            recorder.release();
        }
        recorder = null;
    }
}