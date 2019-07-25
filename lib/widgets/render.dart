import 'dart:isolate';

import 'package:flutter_threejs/gles/gles_helper.dart';
import 'package:flutter_threejs/plugin/flutter_threejs_plugin.dart';
import 'package:flutter/material.dart';

class GLRender {
  GLESHelper glesHelper;

  Widget canvas() {
    return GLCanvas(this);
  }

  void init(nativeWindow) async {
    glesHelper = GLESHelper();
    glesHelper.initEGL(nativeWindow);

//    await createIsolate();
//    sendPort.send(nativeWindow);
  }

//  createIsolate() async {
//    final response = new ReceivePort();
//    await Isolate.spawn(_isolate, response.sendPort);
//    this.sendPort = await response.first as SendPort;
////    final answer = new ReceivePort();
////    sendPort.send([this.nativeWindow]);
//  }
}

//void _isolate(SendPort initialReplyTo) {
//  final port = new ReceivePort();
//  initialReplyTo.send(port.sendPort);
//  port.listen((message) {
//    final nativeWindow = message[0] as int;
//    var glesHelper = GLESHelper();
//    glesHelper.initEGL(nativeWindow);
//    glesHelper.glClearColor(1, 0, 0, 1);
//    glesHelper.glClear(0x00004000);
//    glesHelper.swapBuffersEGL();
//  });
//}

class GLCanvas extends StatefulWidget {
  GLRender glRender;

  GLCanvas(this.glRender);

  @override
  State createState() {
    return new GLCanvasState();
  }
}

class GLCanvasState extends State<GLCanvas> {
  int _textureId = -1;

  @override
  void initState() {
    super.initState();
    initSurface();
  }

  @override
  Widget build(BuildContext context) {
    if (_textureId == -1) {
      return Text('');
    } else {
      return new Texture(textureId: _textureId);
    }
  }

  void initSurface() async {
    Map<dynamic, dynamic> map = await FlutterThreeJsPlugin.initSurface();
    var textureId = map["textureId"];
    var nativeWindow = map["nativeWindow"];
    if (!mounted) return;
    setState(() {
      _textureId = textureId;
    });
    widget.glRender.init(nativeWindow);
  }
}
