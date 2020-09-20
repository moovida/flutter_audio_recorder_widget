import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder_widget/flutter_audio_recorder_widget.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sounds/sounds.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Recorder Widget Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainView(),
    );
  }
}

class MainView extends StatefulWidget {
  MainView({Key key}) : super(key: key);

  @override
  _MainViewState createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  AudioHandler _audioHandler = DemoAudioHandler();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: requestMicPermissions(context),
      initialData: false,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.data) {
          return AudioRecorderView(_audioHandler);
        } else {
          return Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircularProgressIndicator(),
                  // SizedBox(
                  //   height: 10,
                  // ),
                  // Text("Checking permission..."),
                ],
              ),
            ),
          );
          ;
        }
      },
    );
  }
}

/// An example audio handler that reads and writes samples to a given folder.
class DemoAudioHandler extends AudioHandler {
  @override
  Future<List<AudioInfo>> getAudioList() async {
    var audioFiles = listAudioFiles(await getOutputFolder());
    List<AudioInfo> infoList = [];
    for (var i = 0; i < audioFiles.length; i++) {
      infoList.add(
        AudioInfo()
          ..id = i + 1
          ..duration = -1
          ..name = audioFiles[i][0]
          ..path = audioFiles[i][1],
      );
    }

    return infoList;
  }

  @override
  Future<String> getOutputFolder() async {
    Directory docsFolder = await getApplicationDocumentsDirectory();
    return docsFolder.path;
  }
}

/// List supported audio files in the given [parentPath].
/// The returned format is a list of [name, path].
List<List<String>> listAudioFiles(String parentPath) {
  List<List<String>> nameAndPathList = [];

  try {
    var list = Directory(parentPath).listSync();
    for (var fse in list) {
      String path = fse.path;
      var isDirectory = FileSystemEntity.isDirectorySync(path);
      if (!isDirectory) {
        String filename = p.basename(path);
        if (filename.startsWith(".")) {
          continue;
        }
        if (filename.endsWith(ActiveMediaFormat().mediaFormat.extension)) {
          nameAndPathList.add([filename, path]);
        }
      }
    }

    nameAndPathList.sort((o1, o2) {
      String n1 = o1[1];
      String n2 = o2[1];
      return n1.compareTo(n2);
    });
  } catch (e) {
    print(e);
  }

  return nameAndPathList;
}
