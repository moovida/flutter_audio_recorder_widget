import 'dart:io';

import 'package:farw_example/com/hydrologis/flutter_audio_recorder_widget_demo/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder_widget/flutter_audio_recorder_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
    return FutureBuilder(
      future: requestPermissions(context),
      initialData: false,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.data) {
          return AudioRecorderView(_audioHandler);
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircularProgressIndicator(),
                SizedBox(
                  height: 10,
                ),
                Text("Checking permission..."),
              ],
            ),
          );
          ;
        }
      },
    );
  }
}

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
          ..name = audioFiles[i],
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

List<String> listAudioFiles(String parentPath) {
  List<String> names = [];

  try {
    var list = Directory(parentPath).listSync();
    for (var fse in list) {
      String path = fse.path;
      String filename = p.basename(path);
      if (filename.startsWith(".")) {
        continue;
      }
      var isDirectory = FileSystemEntity.isDirectorySync(path);
      if (!isDirectory &&
          filename.endsWith(ActiveMediaFormat().mediaFormat.extension)) {
        names.add(filename);
      }
    }
  } catch (e) {
    print(e);
  }

  names.sort((o1, o2) {
    String n1 = o1[1];
    String n2 = o2[1];
    return n1.compareTo(n2);
  });

  return names;
}
