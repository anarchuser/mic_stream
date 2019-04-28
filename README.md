# mic_stream: ^0.1.4

[Flutter Plugin]
Provides a tool to get the microphone input as PCM Stream (Stream<List<int>>)

## About mic_stream:

As Flutter still lacks some functionality, this plugin aims to provide the possibility to easily get an audio stream from the microphone, using a simple java implementation [=> Android only, iOS Support planned in the future].

## How to use:

The plugin provides one method:

`Stream<List<int>> microphone({options})`

Listening to this stream starts the audio recorder
while cancelling the subscription stops the stream.

#### Example:

```
// Init a new Stream
Stream<List<int>> stream = microphone(sampleRate: 44100);

// Start listening to the stream
StreamSubscription<List<int>> listener = stream.listen((samples) => print(samples));
```

```
// Cancel the subscription
listener.cancel()
```

## Flutter

About Flutter Plugins:
https://flutter.io/developing-packages/

Flutter Documentation:
https://flutter.io/docs
