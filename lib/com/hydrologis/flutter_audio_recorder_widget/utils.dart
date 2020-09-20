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

  /// Confirm dialog using custom [title] and [prompt].
  static Future<bool> showConfirmDialog(
      BuildContext context, String title, String prompt,
      {trueText: 'Yes', falseText: 'No'}) async {
    return await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(prompt),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: Text(trueText),
              ),
              FlatButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: Text(falseText),
              )
            ],
          );
        });
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

Future<bool> requestMicPermissions(BuildContext context) async {
  var granted = false;

  // Request Microphone permission if needed
  print('storage: ${await Permission.microphone.status}');
  var microphoneRequired = !await Permission.microphone.isGranted;

  /// build the 'reason' why and what we are asking permissions for.
  if (microphoneRequired) {
    var reason =
        "To record a message we need permission to access your microphone.";
    reason += " \n\nWhen prompted click the 'Allow' button.";

    /// tell the user we are about to ask for permissions.
    if (await showAlertDialog(context, reason)) {
      var permissions = <Permission>[Permission.microphone];

      /// ask for the permissions.
      await permissions.request();

      /// check the user gave us the permissions.
      granted = await Permission.microphone.isGranted;
      if (!granted) grantFailed(context);
    } else {
      granted = false;
      grantFailed(context);
    }
  } else {
    granted = true;
  }

  // we already have the required permissions.
  return granted;
}

Future<bool> requestPermissions(BuildContext context, Track track) async {
  var granted = false;

  /// change this to true if the track doesn't use
  /// external storage on android.
  var usingExternalStorage = false;

  // Request Microphone permission if needed
  print('storage: ${await Permission.microphone.status}');
  var microphoneRequired = !await Permission.microphone.isGranted;

  var storageRequired = false;

  if (usingExternalStorage) {
    /// only required if track is on external storage
    if (Permission.storage.status == PermissionStatus.undetermined) {
      print('You are probably missing the storage permission '
          'in your manifest.');
    }

    storageRequired =
        usingExternalStorage && !await Permission.storage.isGranted;
  }

  /// build the 'reason' why and what we are asking permissions for.
  if (microphoneRequired || storageRequired) {
    var both = false;

    if (microphoneRequired && storageRequired) {
      both = true;
    }

    var reason = "To record a message we need permission ";

    if (microphoneRequired) {
      reason += "to access your microphone";
    }

    if (both) {
      reason += " and ";
    }

    if (storageRequired) {
      reason += "to store a file on your phone";
    }

    reason += ".";

    if (both) {
      reason += " \n\nWhen prompted click the 'Allow' button on "
          "each of the following prompts.";
    } else {
      reason += " \n\nWhen prompted click the 'Allow' button.";
    }

    /// tell the user we are about to ask for permissions.
    if (await showAlertDialog(context, reason)) {
      var permissions = <Permission>[];
      if (microphoneRequired) permissions.add(Permission.microphone);
      if (storageRequired) permissions.add(Permission.storage);

      /// ask for the permissions.
      await permissions.request();

      /// check the user gave us the permissions.
      granted = await Permission.microphone.isGranted &&
          await Permission.storage.isGranted;
      if (!granted) grantFailed(context);
    } else {
      granted = false;
      grantFailed(context);
    }
  } else {
    granted = true;
  }

  // we already have the required permissions.
  return granted;
}

/// Display a snackbar saying that we can't record due to lack of permissions.
void grantFailed(BuildContext context) {
  var snackBar = SnackBar(
      content: Text('Recording cannot start as you did not allow '
          'the required permissions'));

  // Find the Scaffold in the widget tree and use it to show a SnackBar.
  Scaffold.of(context).showSnackBar(snackBar);
}

///
Future<bool> showAlertDialog(BuildContext context, String prompt) {
  // set up the buttons
  Widget cancelButton = FlatButton(
    child: Text("Cancel"),
    onPressed: () => Navigator.of(context).pop(false),
  );
  Widget continueButton = FlatButton(
    child: Text("Continue"),
    onPressed: () => Navigator.of(context).pop(true),
  );

  // set up the AlertDialog
  var alert = AlertDialog(
    title: Text("Recording Permissions"),
    content: Text(prompt),
    actions: [
      cancelButton,
      continueButton,
    ],
  );

  // show the dialog
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return alert;
    },
  );
}
