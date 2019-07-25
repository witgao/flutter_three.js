import 'package:flutter/services.dart';

class FlutterThreeJsPlugin {
  static const MethodChannel _channel = const MethodChannel('flutter_threejs');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<Map<dynamic, dynamic>> initSurface() async {
    final Map<dynamic, dynamic> map =
        await _channel.invokeMethod('createTextureId');
    return map;
  }
}
