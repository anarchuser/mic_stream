# mic_stream: 0.2.0

[Flutter Plugin]
Provides a tool to get the microphone input as 8 or 16 bit PCM Stream (Stream<List<int>>)

## About mic_stream:

As Flutter still lacks some functionality, this plugin aims to provide the possibility to easily get an audio stream from the microphone, using a simple java implementation [=> Android only, iOS Support planned in the future].

## How to use:

### Permissions

Make sure you have microphone recording permissions enabled for your project.
To do so, add this line to the AndroidManifest.xml:

`<uses-permission android:name="android.permission.RECORD_AUDIO"/>`

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
