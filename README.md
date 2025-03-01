# mic_stream: 0.7.3

[Flutter Plugin]
Provides a tool to get the microphone input as 8 or 16 bit PCM Stream.
32 bit and floating point PCM are experimental WIP.

## About mic_stream:

As Flutter still lacks some functionality, this plugin aims to provide the possibility to easily get an audio stream from the microphone of mobile devices.

## How to use:

The plugin mainly provides one method to provide a raw audio stream:

`Stream<UInt8List> MicStream.microphone({options})`

and a `StreamTransformer` to provide a Stream of individual samples (not lists of samples):

`MicStream.toSampleStream`

that you can use to transform your mic stream:

`stream.transform(MicStream.toSampleStream)`

Listening to this stream starts the audio recorder
while cancelling the subscription stops the stream.

Available options are as follows:

```dart
audioSource: AudioSource      // The microphone you want to record from
sampleRate: int               // The amount of data points to record per second
channelConfig: ChannelConfig  // Mono or Stereo
audioFormat: AudioFormat      // 8 bit PCM or 16 bit PCM. Other formats are not yet supported
```

Some configuration options are platform dependent and can differ from the originally configured ones.
You can check the real values using:

```dart
Future<int> sampleRate = await MicStream.sampleRate;
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

You can disable the permission request dialogue by calling
`MicStream.shouldRequestPermission(false)`
This _will_ lead to an error if no permission to record audio has been requested, though.

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
// Transform the stream and print each sample individually
stream.transform(MicStream.toSampleStream).listen(print);
```

```
// Cancel the subscription
listener.cancel()
```

*Note*: This plugin is still under development, and some APIs might not be available yet.
[Feedback](https://github.com/anarchuser/mic_stream/issues) and
[Pull Requests](https://github.com/anarchuser/mic_stream/pulls) are most welcome!
