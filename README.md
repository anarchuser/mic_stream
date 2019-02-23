# mic_stream

[Flutter Plugin]
Provides a tool to get the microphone input as Byte Stream (Stream<Uint8List>)

## About mic_stream:

As Flutter still lacks some functionality, this plugin aims to provide the possibility to easily get an audio stream from the microphone, using a simple java implementation [=> Android only, iOS Support planned in the future].

## Example

/** Instantiate a 'Microphone' object inheriting the 'StreamController' class: */

Microphone microphone = new Microphone();

// Or as Broadcaster:

Microphone broadcast = new Microphone.broadcast();

// Instantiate a Java AudioRecord object and start recording with an optional sampling rate as argument:

microphone.start();                           // Default: 16000

microphone.start(samplerate = 8000);

// .start() returns a Stream<Uint8List> from dart:typed_data, meaning you can use it like this:

microphone.start().listen((sample) => print(sample.toString());

// Or this:

StreamSubcription<Uint8List> subscriptor = microphone.start().listen((sample) => print(sample.toString());
  
// Or like this, esp. to use on a braodcaster with multiple possible subsriptors

Stream<Uint8List> stream = broadcast.start();
StreamSubscription<Uint8List> subscriptor1 = stream.listen((sample) => print(sample.toString());
StreamSubscription<Uint8List> subscriptor2 = stream.listen((sample) => print(sample.toString());

// etc...

// To stop the streaming, call

microphone.stop();

## Flutter

About Flutter Plugins:
https://flutter.io/developing-packages/

Flutter Documentation:
https://flutter.io/docs
