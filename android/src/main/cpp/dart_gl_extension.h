//
// Created by zhenyu on 2019-07-20.
//

#ifndef ANDROID_DART_GL_EXTENSION_H
#define ANDROID_DART_GL_EXTENSION_H

#include <jni.h>
#include <EGL/egl.h>
#include "dart_native_api.h"

namespace threejs {
    class Register {
    private:
        typedef JNINativeMethod ptr[1];
        static constexpr auto _javaClassName = "com/zhenyu/flutter_threejs/FlutterThreejsPlugin";

    public:
        static jint registerNatives(JNIEnv *env);
    };

    class GLESHelper {
    private:
        EGLDisplay _display;
        EGLSurface _surface;

    public:
        void initEGL(ANativeWindow *aNativeWindow, int width, int height);
        void swapBuffersEGL();
    };

    DART_EXPORT long initEGL(long nativeWindow, int width, int height);
    DART_EXPORT void swapBuffersEGL(long eglHelper);

    static jlong nativeCreateNativeWindow(JNIEnv *jenv, jobject obj, jobject surface);

}


#endif //ANDROID_DART_GL_EXTENSION_H
