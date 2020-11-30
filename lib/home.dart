import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_flutter/player.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime _lastQuitTime;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String currPlay = '';
  List musicList = [];

  _getPlay() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String lastPlaySong = prefs.getString('lastPlaySong');
    if (lastPlaySong != null) {
      setState(() {
        currPlay = lastPlaySong;
      });
    }
  }

  _setPlay(path) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('lastPlaySong', path);
  }

  playLocal(path, name) async {
    _setPlay(path);
    setState(() {
      currPlay = path;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Player(record: {'path': path, 'name': name}),
        ),
      );
    });
  }

  /// 此方法返回本地文件地址
  _getLocalFile() async {
    List arr = [];
    List<Directory> a = await getExternalStorageDirectories();
    for (var o in a) {
      String dir = o.path.substring(0, o.path.indexOf('Android')) + 'Music/';
      print(dir);
      if (await FileSystemEntity.isDirectory(dir)) {
        Directory directory = Directory(dir);
        if (directory.listSync() is List) {
          directory.listSync().forEach((element) {
            String path = element.path;
            if (['mp4'].contains(path.substring(path.lastIndexOf('.') + 1))) {
              if (!arr.contains(element.path)) {
                arr.add(element.path);
              }
            }
          });
        }
      }
    }
    if (arr.isEmpty) {
      _message('视频文件放在手机存储或SD卡的Music下');
    }
    if (!mounted) return;
    setState(() {
      musicList = arr;
    });
  }

  _message(val) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Container(
          height: 34,
          alignment: Alignment.center,
          child: Text(val),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _getLocalFile();
    _getPlay();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          elevation: 0,
          title: Text('${musicList.length > 0 ? ' 共${musicList.length}部' : ''}'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_outlined),
              onPressed: _getLocalFile,
            ),
          ],
        ),
        body: ListView.builder(
          itemBuilder: (context, index) {
            String path = musicList[index];
            String name = path.substring(path.lastIndexOf('/') + 1, path.lastIndexOf('.'));
            return ListTile(
              onTap: () {
                playLocal(path, name);
              },
              title: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(
                Icons.play_arrow_outlined,
                color: currPlay == path ? Color(0xff000000) : Colors.white,
              ),
            );
          },
          itemCount: musicList.length,
        ),
      ),
      onWillPop: () async {
        if (_lastQuitTime == null || DateTime.now().difference(_lastQuitTime).inSeconds > 1) {
          _message('再按一次 Back 按钮退出');
          _lastQuitTime = DateTime.now();
          return false;
        }
        return true;
      },
    );
  }
}
