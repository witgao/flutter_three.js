package com.zhenyu.flutter_threejs;

import android.view.Surface;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.view.TextureRegistry;

/**
 * FlutterThreejsPlugin
 */
public class FlutterThreejsPlugin implements MethodCallHandler {
    private static Registrar flutterRegistrar;

    static {
        System.loadLibrary("flutter-threejs");
    }

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        flutterRegistrar = registrar;

        final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_threejs");
        channel.setMethodCallHandler(new FlutterThreejsPlugin());
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (call.method.equals("getPlatformVersion")) {
            result.success("Android " + android.os.Build.VERSION.RELEASE);
        } else if (call.method.equals("createTextureId")) {
            TextureRegistry textureRegistry = flutterRegistrar.textures();
            TextureRegistry.SurfaceTextureEntry surfaceTexture = textureRegistry.createSurfaceTexture();
            Surface surface = new Surface(surfaceTexture.surfaceTexture());
            long nativeWindow = nativeCreateNativeWindow(surface);
            long textureId = surfaceTexture.id();
            Map<String, Long> map = new HashMap<>();
            map.put("textureId", textureId);
            map.put("nativeWindow", nativeWindow);
            result.success(map);
        } else {
            result.notImplemented();
        }
    }

    /**
     * 创建ANativeWindow
     *
     * @param surface surface
     * @return ANativeWindow对象指针
     */
    public static native long nativeCreateNativeWindow(Surface surface);
}
