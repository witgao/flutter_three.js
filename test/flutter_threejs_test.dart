import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_threejs/plugin/flutter_threejs_plugin.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_threejs');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FlutterThreeJsPlugin.platformVersion, '42');
  });
}
