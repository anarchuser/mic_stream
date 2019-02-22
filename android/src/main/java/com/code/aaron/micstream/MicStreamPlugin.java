package com.code.aaron.micstream;

import android.media.AudioFormat;

import java.util.stream.*;
import java.io.ByteArrayInputStream;

import javax.sound.sampled.*;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** MicStreamPlugin */
public class MicStreamPlugin implements MethodCallHandler {

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "mic_stream");
        channel.setMethodCallHandler(new MicStreamPlugin());
    }

    AudioFormat test;

    /** Variables **/
    private Stream<Byte> audioStream;

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "start":
                result.success(play());
                break;
            case "pause":
                pause();
                break;
            case "resume":
                result.success(resume());
                break;
            case "stop":
                stop();
                break;
            default:
                result.notImplemented();
        }
    }

    private Stream<Byte> play() {
        return audioStream;
    }

    private void pause() {

    }

    private Stream<Byte> resume() {
        return audioStream;
    }

    private void stop() {

    }
}