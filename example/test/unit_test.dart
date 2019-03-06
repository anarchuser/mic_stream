import 'dart:typed_data';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mic_stream/mic_stream.dart';

void main() {
  Microphone microphone;


  test('Create microphone instance and start it', () {

    print('Instantiate class');
    microphone = new Microphone();

    print('Start recording - Yields a stream if successful');
    expect(microphone.start(), isNotNull);

    print('Test whether it actually runs');
    expect(microphone.isRecording, true);

    print('Test whether a string representation is given back');
    expect(microphone.toString(), isNotNull);

    //print('Test for nonexistent method');
    //expect(microphone.TEST(), isNoSuchMethodError);

    microphone.pause();
    expect(microphone.isRecording, false);

    microphone.resume();
    expect(microphone.isRecording, true);

    StreamSubscription<Uint8List> listener = microphone.stream.listen((sample) {
      sample.forEach((value) => expect(value, isNotNull));
    });

    sleep(new Duration(milliseconds: 1000));
    listener.cancel();
  });



  Microphone broadcast = new Microphone.broadcast();

}
