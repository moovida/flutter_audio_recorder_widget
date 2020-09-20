part of flutter_audio_recorder_widget;

/// Audio information class to show in the listview.
class AudioInfo {
  /// A unique identifier for the audio resource.
  int id;

  /// A label for the audio resource.
  String name;

  /// If filebased, the path to the resource.
  ///
  /// Could be null if the audio is saved to database.
  String path;

  /// The duration of the audio in seconds.
  int duration;
}

/// An abstract audio handler class.
abstract class AudioHandler {
  /// Get the list of existing [AudioInfo]s.
  Future<List<AudioInfo>> getAudioList();

  /// Override to set the output folder for the recordings.
  Future<String> getOutputFolder();

  /// Stop the recording session.
  Future stopRecording() async {
    if (RecorderState().isRecording || RecorderState().isPaused) {
      await RecorderState().stopRecorder();
    }
  }

  /// Start recording to a file named [audioName] and saved in the [getOutputFolder].
  Future startRecording(BuildContext context, String audioName) async {
    var ext = ActiveMediaFormat().mediaFormat.extension;
    if (!audioName.endsWith(ext)) {
      audioName += ".$ext";
    }
    String folderPath = await getOutputFolder();
    var directory = Directory(folderPath);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    var outFilePath = p.join(folderPath, audioName);
    final file = File(outFilePath);
    file.createSync();

    await RecorderState().startRecorder(context, outFilePath);
  }
}

/// Main recorder view, featuring a list of available
/// recordings and a FAB to record new audio.
class AudioRecorderView extends StatefulWidget {
  final AudioHandler audioHandler;

  AudioRecorderView(this.audioHandler, {Key key}) : super(key: key);

  @override
  _AudioRecorderViewState createState() =>
      _AudioRecorderViewState(audioHandler);
}

class _AudioRecorderViewState extends State<AudioRecorderView>
    with AfterLayoutMixin {
  AudioHandler audioHandler;
  bool _audioLoaded = false;
  List<AudioInfo> _audioList;
  String errorMessage;
  bool _isRecording = false;
  String newRecordingName;
  String outputFolder;

  _AudioRecorderViewState(this.audioHandler);

  @override
  Future<void> afterFirstLayout(BuildContext context) async {
    // initialize the audio recording system and set the media format.
    await RecorderState().init();
    ActiveMediaFormat().recorderModule = RecorderState().recorderModule;
    await ActiveMediaFormat()
        .setMediaFormat(withShadeUI: false, mediaFormat: AdtsAacMediaFormat());

    // get the output folder, to which all samples will be saved
    outputFolder = await audioHandler.getOutputFolder();

    await loadExistingAudio();
  }

  /// Load existing audio samples from the filesystem ([audioHandler.getOutputFolder()] is used)
  Future loadExistingAudio() async {
    try {
      _audioList = await audioHandler.getAudioList();
      errorMessage = null;
    } on Exception catch (e) {
      errorMessage = "An error occurred while loading audio resources.";
      print(e);
    }
    setState(() {
      _audioLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyWidget;

    if (errorMessage != null) {
      bodyWidget = getErrorWidget(errorMessage);
    } else {
      if (_isRecording) {
        bodyWidget = getWhileRecordingWidget(context);
      } else {
        if (_audioLoaded) {
          bodyWidget = getAudioListWidget(context);
        } else {
          bodyWidget = getProgressWithLabelWidget();
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Audio Recorder/Playback"),
      ),
      body: bodyWidget,
      floatingActionButton: !_isRecording
          ? FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: () async {
                // prompt the user for a name for the recorded sample, proposing a timestamp based
                String trackName =
                    "Track_${Utils.DATE_TS_FORMATTER.format(DateTime.now())}";
                var audioName = await Utils.showInputDialog(
                  context,
                  "Record new audio",
                  "Please enter a name for the new recording",
                  defaultText: trackName,
                );
                if (audioName != null && audioName.isNotEmpty) {
                  audioHandler.startRecording(context, audioName);
                }
                setState(() {
                  _isRecording = true;
                });
              },
              child: Icon(MdiIcons.recordRec),
            )
          : null,
    );
  }

  /// Build the widget used during recording (featuring the stop button).
  Widget getWhileRecordingWidget(BuildContext context) {
    var size = math.min(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          FlatButton(
            child: Icon(
              MdiIcons.recordRec,
              size: size / 2,
              color: Colors.red,
            ),
            onPressed: () async {
              await stopRecordingOnTap();
            },
          ),
          FlatButton(
            child: Text("Tap to stop recording."),
            onPressed: () async {
              await stopRecordingOnTap();
            },
          )
        ],
      ),
    );
  }

  Future stopRecordingOnTap() async {
    await audioHandler.stopRecording();
    _isRecording = false;
    await loadExistingAudio();
  }

  /// Build the widget containing the list of existing audio samples for playback.
  Widget getAudioListWidget(BuildContext context) {
    if (newRecordingName == null) {
      newRecordingName =
          "Track_${Utils.DATE_TS_FORMATTER.format(DateTime.now())}.${ActiveMediaFormat().mediaFormat.extension}";
    }

    var outFilePath = p.join(outputFolder, newRecordingName);
    final file = File(outFilePath);
    file.createSync();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          flex: 1,
          child: ListView.builder(
            itemCount: _audioList.length,
            itemBuilder: (BuildContext context, int index) {
              AudioInfo audioInfo = _audioList[index];

              var track = Track.fromFile(audioInfo.path,
                  mediaFormat: ActiveMediaFormat().mediaFormat);

              var soundPlayerUI = SoundPlayerUI.fromTrack(track);

              return ListTile(
                leading: Icon(
                  MdiIcons.waveform,
                  color: Colors.green,
                  size: 64,
                ),
                title: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    audioInfo.name
                        .substring(0, audioInfo.name.lastIndexOf('.')),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                subtitle: soundPlayerUI,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget getProgressWithLabelWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(
            height: 10,
          ),
          Text("Loading existing audio..."),
        ],
      ),
    );
  }

  Widget getErrorWidget(String errorMsg) {
    return Container(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.all(8.0),
        elevation: 5,
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            errorMsg,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
