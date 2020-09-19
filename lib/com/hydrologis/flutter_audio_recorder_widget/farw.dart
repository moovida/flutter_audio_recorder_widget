part of flutter_audio_recorder_widget;

/// Audio information class to show in the listview.
class AudioInfo {
  /// A unique identifier for the audio resource.
  int id;

  /// A label for the audio resource.
  String name;

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

  _AudioRecorderViewState(this.audioHandler);

  @override
  Future<void> afterFirstLayout(BuildContext context) async {
    await RecorderState().init();
    ActiveMediaFormat().recorderModule = RecorderState().recorderModule;
    await ActiveMediaFormat().setMediaFormat(
        withShadeUI: false, mediaFormat: WellKnownMediaFormats.oggVorbis);

    await loadExistingAudio();
  }

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
        var size = math.min(MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height);
        bodyWidget = Center(
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
                  await audioHandler.stopRecording();
                  _isRecording = false;
                  await loadExistingAudio();
                },
              ),
              Text("Tap to stop recording.")
            ],
          ),
        );
      }
      if (_audioLoaded) {
        bodyWidget = showAudioList();
      } else {
        bodyWidget = showProgressWithLabel();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Audio Recorder/Playback"),
      ),
      body: bodyWidget,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
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
      ),
    );
  }

  Widget showAudioList() {
    return ListView.builder(
      itemCount: _audioList.length,
      itemBuilder: (BuildContext context, int index) {
        var audioInfo = _audioList[index];

        return ListTile(
          leading: Icon(MdiIcons.waveform),
          title: Text(audioInfo.name),
          subtitle: audioInfo.duration > 0
              ? Text(Utils.formatDurationMillis(audioInfo.duration))
              : Text(""),
        );
      },
    );
  }

  Widget showProgressWithLabel() {
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
