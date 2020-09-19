part of flutter_audio_recorder_widget;

class Utils {
  /// A date formatter (yyyyMMdd_HHmmss) useful for file names (it contains no spaces).
  static final DateFormat DATE_TS_FORMATTER = DateFormat("yyyyMMdd_HHmmss");

  /// Format a [seconds] duration to contain the hours/minutes/seconds part.
  static String formatDurationMillis(int seconds) {
    if (seconds == null) {
      return null;
    }
    String durationStr = "$seconds sec";
    if (seconds > 60) {
      double durationMinutes = seconds / 60.0;
      double leftSeconds = seconds % 60.0;
      durationStr = "${durationMinutes.toInt()} min";
      if (leftSeconds > 0) {
        durationStr += ", ${leftSeconds.toInt()} sec";
      }
      if (durationMinutes > 60) {
        double durationhours = durationMinutes / 60;
        double leftMinutes = durationMinutes % 60;
        durationStr = "${durationhours.toInt()} h";
        if (leftMinutes > 0) {
          durationStr += ", ${leftMinutes.toInt()} min";
        }
      }
    }
    return durationStr;
  }

  /// Show a user input dialog, adding a [title] and a [label].
  ///
  /// Optionally a [hintText] and a [defaultText] can be passed in and the
  /// strings for the [okText] and [cancelText] of the buttons.
  ///
  /// If the user pushes the cancel button, null will be returned, if user pushes ok without entering anything the empty string '' is returned.
  static Future<String> showInputDialog(
      BuildContext context, String title, String label,
      {defaultText: '',
      hintText: '',
      okText: 'Ok',
      cancelText: 'Cancel',
      isPassword: false,
      Function validationFunction}) async {
    String userInput = defaultText;
    String errorText;

    var textEditingController = new TextEditingController(text: defaultText);
    var inputDecoration =
        new InputDecoration(labelText: label, hintText: hintText);
    var _textWidget = new TextFormField(
      controller: textEditingController,
      autofocus: true,
      autovalidate: true,
      decoration: inputDecoration,
      obscureText: isPassword,
      validator: (inputText) {
        userInput = inputText;
        if (validationFunction != null) {
          errorText = validationFunction(inputText);
        } else {
          errorText = null;
        }
        return errorText;
      },
    );

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Builder(builder: (context) {
            var width = MediaQuery.of(context).size.width;
            return Container(
              width: width,
              child: new Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[new Expanded(child: _textWidget)],
              ),
            );
          }),
          actions: <Widget>[
            FlatButton(
              child: Text(cancelText),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            FlatButton(
              child: Text(okText),
              onPressed: () {
                if (errorText == null) {
                  Navigator.of(context).pop(userInput);
                }
              },
            ),
          ],
        );
      },
    );
  }
}

/// METHODS HERE BELOW ARE COPIED OVER FROM THE SOUNDS LIBRARY

/// Factory used to track what MediaFormat is currently selected.
class ActiveMediaFormat {
  static final ActiveMediaFormat _self = ActiveMediaFormat._internal();

  MediaFormat mediaFormat = OggVorbisMediaFormat();
  bool _encoderSupported = false;
  bool _decoderSupported = false;

  ///
  SoundRecorder recorderModule;

  /// Factory to access the active MediaFormat.
  factory ActiveMediaFormat() {
    return _self;
  }
  ActiveMediaFormat._internal();

  /// Set the active code for the the recording and player modules.
  Future<void> setMediaFormat(
      {bool withShadeUI, MediaFormat mediaFormat}) async {
    _encoderSupported = await mediaFormat.isNativeEncoder;
    _decoderSupported = await mediaFormat.isNativeDecoder;

    this.mediaFormat = mediaFormat;
  }

  /// [true] if the active coded is supported by the recorder
  bool get encoderSupported => _encoderSupported;

  /// [true] if the active coded is supported by the player
  bool get decoderSupported => _decoderSupported;
}

/// Tracks the Recoder UI's state.
class RecorderState {
  static final RecorderState _self = RecorderState._internal();

  /// primary recording moduel
  SoundRecorder recorderModule;

  /// Factory ctor
  factory RecorderState() {
    return _self;
  }

  RecorderState._internal() {
    recorderModule = SoundRecorder();
  }

  /// [true] if we are currently recording.
  bool get isRecording => recorderModule != null && recorderModule.isRecording;

  /// [true] if we are recording but currently paused.
  bool get isPaused => recorderModule != null && recorderModule.isPaused;

  /// required to initialize the recording subsystem.
  Future<void> init() async {
    ActiveMediaFormat().recorderModule = recorderModule;
  }

  /// Call this method if you have changed any of the recording
  /// options.
  /// Stops the recorder and cause the recording UI to refesh and update with
  /// any state changes.
  Future<void> reset() async {
    if (RecorderState().isRecording) await RecorderState().stopRecorder();
  }

  /// Returns a stream of [RecordingDisposition] so you can
  /// display db and duration of the recording as it records.
  /// Use this with a StreamBuilder
  Stream<RecordingDisposition> dispositionStream(
      {Duration interval = const Duration(milliseconds: 10)}) {
    return recorderModule.dispositionStream(interval: interval);
  }

  /// stops the recorder.
  Future<void> stopRecorder() async {
    try {
      await recorderModule.stop();
    } on Object catch (err) {
      print('stopRecorder error: $err');
      rethrow;
    }
  }

  /// starts the recorder.
  Future<void> startRecorder(
      BuildContext context, String outputFilePath) async {
    try {
      var track = Track.fromFile(outputFilePath,
          mediaFormat: ActiveMediaFormat().mediaFormat);
      await recorderModule.record(track);

      print('startRecorder: $track');

      // MediaPath()
      //     .setMediaFormatPath(ActiveMediaFormat().mediaFormat, track.url);
    } on RecorderException catch (err) {
      print('startRecorder error: $err');

      var error = SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to start recording: $err'));
      Scaffold.of(context).showSnackBar(error);

      stopRecorder();
    }
  }

  /// toggles the pause/resume start of the recorder
  void pauseResumeRecorder() {
    assert(recorderModule.isRecording || recorderModule.isPaused);
    if (recorderModule.isPaused) {
      {
        recorderModule.resume();
      }
    } else {
      recorderModule.pause();
    }
  }
}
