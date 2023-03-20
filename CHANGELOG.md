## 0.6.5
* Fixed sampleRate settings to be adapted to iOS

## 0.6.4

* Change interface from having const default values to taking nullable parameters (#54)
* Make default values publicly accessible

## 0.6.3

* Switch to a different MacOS backend to resolve issues of white noise (#49)

### 0.6.2

* Upgrade `permission_handler` to version 10.0.0 and update compileSdk to 33 accordingly

### 0.6.1

* Fix issues of the Audio Recorder not always being properly reinitialised on android

## 0.6.0

+ Changing microphone config now reconfigures audio recorder. To change config, recall `microphone({config})` with the new config.

### 0.5.5

* Add flag to prevent permission request dialogue

### 0.5.4

* Don't ask for permission on MacOS, since they seem to have permission anyways

#### 0.5.3+1

* Retroactively update description for version 0.4.0

* Some cleanup

### 0.5.3

* Comply with [Null safety](https://flutter.dev/docs/null-safety)

### 0.5.2

* Fixed permissions to record audio not being requested (solves [#19](https://github.com/anarchuser/mic_stream/issues/19))

### 0.5.1

* Fix a bug caused by lacking synchronisation between audio stream generator and event handler

#### 0.5.0+1

+ Migrate to new [Android Plugin APIs](https://flutter.dev/docs/development/packages-and-plugins/plugin-api-migration)

## 0.5.0

+ Add Pull Request #16, adding support for macOS

+ Add intensity viewer to the example app

## 0.4.0

BREAKING CHANGE: Now always returns a `Stream<Uint8list>`. With a 16BIT PCM config, every pair of bytes constitutes one 16Bit value. Refer to #29 for further information.

* Fix Issue #11, making the plugin work on iOS devices

* Formatted Code.

### 0.2.1

* Update permission plugin dependency

* Make AndroidX compatible


### 0.2.0+2

* Formatted Code.


### 0.2.0+1

* Updated README.


## 0.2.0

* Fixed value truncation, now ensuring correct values for 16BIT_PCM

+ Added a better example application in ./example/lib/main.dart


## 0.1.5

* Fixed Issue #8, causing immediate crashes in the latest flutter update


## 0.1.4

- Removed Debug output

* Fixed casting issue

+ Added Error handling for exceptions thrown on wrong AudioRecord params


## 0.1.3

* Updated README.


## 0.1.2

+ Added 16Bit PCM mode


## 0.1.1

+ Added customisability for the recorder
+ Added some error handling of the input params


## 0.1.0

* Rewritten Plugin to make use of EventChannel.StreamHandlers (Much nicer than before)

* microphone({Options}) returns a Stream<List<int>>
  * The stream starts upon onListen() and runs until onCancel()

* listen to the stream to start recording
* stop the subscription to stop


## 0.0.8

- Calculations of durations, as multi-threading currently makes it not working. Will be included in future releases

+ Some unit tests (Will be extended in the future to fully ensure the plugin's working)


## 0.0.7

* Fixed crucial bug from 0.0.6


## 0.0.6

* Smaller changes


## 0.0.5

+ Setter for microphone (audioSource, sampleRate, channelConfig, audioFormat)


## 0.0.4

* Changed Values for default and maximum sample rate (to 32 kHZ and 48 kHZ, respectively)


## 0.0.3

+ pause:            Pauses writing data to the stream
+ resume:           Resumes a paused stream


## 0.0.2

+ Getter for internal stream: microphone.stream


## 0.0.1

Initial release - Android support only!

Provides the Class Microphone inheriting StreamController<T> with .start() and .stop() to start and stop sending an audio stream from the microphone to the Microphone's internal Stream (Microphone.stream).
Also provides Microphone,broadcast which works the same but allows multiple StreamSubscriptions.
On start, a timestamp is set and returned on stop.

Constructor takes the Sample Rate as optional argument.

##### Provides methods to:
* platformVersion:  Getter to return current platform version
* bufferSize:       Getter to return current buffer size (calculated from the sample size)
* isRecording:      Returns the state of the class
* sampleRate:       Setter to manually update the sample rate (use with caution, though)
* close:            Closes the internal StreamController
* toString:         Pass-through to internal StreamController

