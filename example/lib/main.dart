import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_threejs/flutter_threejs.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  GLRender _glRender;

  var _bgColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _glRender = GLRender();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await FlutterThreeJsPlugin.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
    setState(() {
      _platformVersion = platformVersion;
    });
  }

  void _clear() {
    if (_bgColor == Colors.red) {
      _glRender.glesHelper.glClearColor(1, 0, 0, 1);
      setState(() {
        _bgColor = Colors.blue;
      });
    } else {
      _glRender.glesHelper.glClearColor(1, 1, 1, 1);
      setState(() {
        _bgColor = Colors.red;
      });
    }
    _glRender.glesHelper.glClear(0x00004000);
    _glRender.glesHelper.swapBuffersEGL();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('example app'),
          ),
          body: Scaffold(
            body: _glRender.canvas(),
            floatingActionButton: FloatingActionButton(
              onPressed: _clear,
              backgroundColor: _bgColor,
              tooltip: 'clear',
              child: Icon(Icons.brush),
            ),
          )),
    );
  }
}
