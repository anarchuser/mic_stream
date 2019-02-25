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