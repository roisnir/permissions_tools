// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
import 'dart:io' show Platform, File;
import 'dart:math' as math;
import 'package:example_flutter/permissions_view.dart';
import 'package:flutter/material.dart';
import 'package:file_chooser/file_chooser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_size/window_size.dart' as window_size;

import 'common/permission.dart';

void main() {
  // Try to resize and reposition the window to be half the width and height
  // of its screen, centered horizontally and shifted up from center.
  WidgetsFlutterBinding.ensureInitialized();
  window_size.getWindowInfo().then((window) {
    if (window.screen != null) {
      final screenFrame = window.screen.visibleFrame;
      final width = math.max((screenFrame.width / 2).roundToDouble(), 800.0);
      final height = math.max((screenFrame.height / 2).roundToDouble(), 600.0);
      final left = ((screenFrame.width - width) / 2).roundToDouble();
      final top = ((screenFrame.height - height) / 3).roundToDouble();
      final frame = Rect.fromLTWH(left, top, width, height);
      window_size.setWindowFrame(frame);
      window_size
          .setWindowTitle('Permissions Viewer');

      if (Platform.isMacOS) {
        window_size.setWindowMinSize(Size(800, 600));
        window_size.setWindowMaxSize(Size(1600, 1200));
      }
    }
  });

  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Permissions Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue,
        accentColor: Colors.blue,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
          body: MainPermissions()),
    );
  }
}

class MainPermissions extends StatefulWidget {
  @override
  _MainPermissionsState createState() => _MainPermissionsState();
}

class _MainPermissionsState extends State<MainPermissions> {
  String fileName;
  Future<Directory> dirFuture;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          buildFileSelectionButton(context),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            color: Colors.grey[200],
              child: Text(fileName ?? '<no file selected>'))
        ],),
        FutureBuilder<Directory>(
            future: dirFuture,
            builder: (c, snap) =>
            snap.connectionState != ConnectionState.done
                ? (fileName == null ? Container() : CircularProgressIndicator())
                : Expanded(child: PermissionsView(snap.data))
        ),
      ],
    );
  }
  Widget buildFileSelectionButton(BuildContext context){
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: RaisedButton(
        color: Colors.blue,
        textColor: Colors.white,
        child: const Text('OPEN FILE'),
        onPressed: () async {
          String initialDirectory;
          initialDirectory = (await getApplicationDocumentsDirectory()).path;
          final result = await showOpenPanel(
              allowsMultipleSelection: false,
              initialDirectory: initialDirectory,
          allowedFileTypes: [FileTypeFilterGroup(label: 'JSON files', fileExtensions: ['json'])]);
          if (result.canceled) return;
          setState(() {
            fileName = result.paths[0];
            dirFuture = readPermissionsJson(File(fileName));
          });
        },
      ),
    );
  }

}

