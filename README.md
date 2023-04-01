# mic_stream: 0.6.5

[Flutter Plugin]
Provides a tool to get the microphone input as 8 or 16 bit PCM Stream.

## About mic_stream:

As Flutter still lacks some functionality, this plugin aims to provide the possibility to easily get an audio stream from the microphone of mobile devices.

## How to use:

The plugin provides one method:

`Future<Stream<UInt8List>> MicStream.microphone({options})`

Listening to this stream starts the audio recorder
while cancelling the subscription stops the stream.

The plugin also provides information about some properties:

```
Future<double> sampleRate = await MicStream.sampleRate;
Future<int> bitDepth = await MicStream.bitDepth;
Future<int> bufferSize = await MicStream.bufferSize;
```

### Permissions

Make sure you have microphone recording permissions enabled for your project.
To do so, add this line to the AndroidManifest.xml:

`<uses-permission android:name="android.permission.RECORD_AUDIO"/>`

In the Info.plist:

```
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access required</string>
```


For MacOS:

Open macos/Runner.xcworkspace
click Runner -> Signing & Capabilities -> Check "Audio Input"

#### Example:

```
// Init a new Stream
Stream<List<int>> stream = await MicStream.microphone(sampleRate: 44100);

// Start listening to the stream
StreamSubscription<List<int>> listener = stream.listen((samples) => print(samples));
```

```
// Cancel the subscription
listener.cancel()
```

*Note*: This plugin is still under development, and some APIs might not be available yet.
[Feedback](https://github.com/anarchuser/mic_stream/issues) and
[Pull Requests](https://github.com/anarchuser/mic_stream/pulls) are most welcome!
