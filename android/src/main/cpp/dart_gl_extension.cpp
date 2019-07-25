//
// Created by zhenyu on 2019-07-20.
//

#include "dart_gl_extension.h"
//#include <android/native_window.h> // requires ndk r5 or newer
#include <android/native_window_jni.h>
#include <EGL/egl.h>
//#include <GLES/gl.h>
#include <GLES2/gl2.h>
#include <EGL/eglplatform.h>
#include <android/log.h>

#define  LOGE(TAG, ...)  __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

#include<thread>
#include <sstream>
#include <android/looper.h>

using namespace std;

namespace threejs {

    // ------------------------------- java jni -----------------------------------

    jint Register::registerNatives(JNIEnv *env) {
        ptr methods = {
                {"nativeCreateNativeWindow", "(Landroid/view/Surface;)J", (void *) nativeCreateNativeWindow},
        };
        jclass clazz;
        clazz = env->FindClass(_javaClassName);
        if (clazz == NULL) {
            return JNI_FALSE;
        }
        if ((env->RegisterNatives(clazz, methods, sizeof(methods) / sizeof(methods[0]))) < 0) {
            env->DeleteLocalRef(clazz);
            return JNI_FALSE;
        }
        env->DeleteLocalRef(clazz);
        return JNI_TRUE;
    }

    jlong nativeCreateNativeWindow(JNIEnv *jenv, jobject obj, jobject surface) {
        std::thread::id tid = std::this_thread::get_id();
        std::stringstream sin;
        sin << tid;
        LOGE("witgao", "id = %s", sin.str().data());
        ANativeWindow *pNativeWindow = ANativeWindow_fromSurface(jenv, surface);
        return reinterpret_cast<jlong>(pNativeWindow);
    }

    // ------------------------------- dart ffi -----------------------------------
    long initEGL(long nativeWindow, int width, int height) {
        GLESHelper *pGLESHelper = new GLESHelper();
        ANativeWindow *pNativeWindow = reinterpret_cast<ANativeWindow *>(nativeWindow);
        pGLESHelper->initEGL(pNativeWindow, width, height);
        return reinterpret_cast<long>(pGLESHelper);
    }

    void swapBuffersEGL(long eglHelper) {
        GLESHelper *pGLESHelper = reinterpret_cast<GLESHelper *>(eglHelper);
        pGLESHelper->swapBuffersEGL();
    }

    void GLESHelper::initEGL(ANativeWindow *aNativeWindow, int width, int height) {
        const EGLint attribs[] = {
                // 设置surface类型，有三种，window_surface,pbuffer_surface,pixmap_surface
                // 只有window_surface和window有关联，可以在window上显示
                EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
                // 指定opengl-es版本为2.0
                EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
                EGL_BLUE_SIZE, 8,
                EGL_GREEN_SIZE, 8,
                EGL_RED_SIZE, 8,
                EGL_NONE
        };
        EGLConfig config;
        EGLint numConfigs;
        EGLint format;
        EGLDisplay display;
        EGLContext context;
        EGLSurface eglSurface;
        GLfloat ratio;
        GLsizei glwidth, glheight;

        std::thread::id tid = std::this_thread::get_id();
        std::stringstream sin;
        sin << tid;
        LOGE("witgao", "id = %s", sin.str().data());
        // 获取当前设备中默认屏幕的handle，display对象可以认为就是一块物理的屏幕，如果没有对应的display，则返回EGL_NO_DISPLAY。
        if ((display = eglGetDisplay(EGL_DEFAULT_DISPLAY)) == EGL_NO_DISPLAY) {
//        Shader::eglPrintError("eglGetDisplay()", eglGetError());
            LOGE("witgao", "eglGetDisplay");
            return;
        }
        // 针对获取的屏幕对指定版本的egl进行初始化（display，返回的主版本号,返回的次版本号）
        EGLint major, minor;
        if (!eglInitialize(display, &major, &minor) || major == NULL || minor == NULL) {
            LOGE("witgao", "eglInitialize");
//        Shader::eglPrintError("eglInitialize()", eglGetError());
            return;
        }
        // 获取设备中支持指定属性的配置集合（display，指定的属性，输出的配置，输出配置的个数，所有支持指定属性的配置的个数）
        if (!eglChooseConfig(display, attribs, &config, 1, &numConfigs)) {
//        Shader::eglPrintError("eglChooseConfig()", eglGetError());
//        destroy();
            LOGE("witgao", "eglChooseConfig");
            return;
        }
        // 查询上面获取的配置中关联的native visual的ID（display，配置，具体属性名，返回的属性值）
        if (!eglGetConfigAttrib(display, config, EGL_NATIVE_VISUAL_ID, &format)) {
//        Shader::eglPrintError("eglGetConfigAttrib()", eglGetError());
//        destroy();
            LOGE("witgao", "eglGetConfigAttrib");
            return;
        }

        int mBufferWidth = (int) (width);
        int mBufferHeight = (int) (height);
        // 重新设置原生window缓冲区的几何形状（原生window，宽，高，像素格式）
        ANativeWindow_setBuffersGeometry(aNativeWindow, mBufferWidth, mBufferHeight, format);

        // 创建一个提供给opengl-es绘制的surface（display，配置，原生window，指定属性）
        if (!(eglSurface = eglCreateWindowSurface(display, config, aNativeWindow, 0))) {
//        Shader::eglPrintError("eglCreateWindowSurface()", eglGetError());
//        destroy();
            LOGE("witgao", "eglCreateWindowSurface");
            return;
        }
//    const EGLint attribs2[] = {
//            EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
//            EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
//            EGL_BLUE_SIZE, 8,
//            EGL_GREEN_SIZE, 8,
//            EGL_RED_SIZE, 8,
//            EGL_NONE
//    };
//    eglChooseConfig(display, attribs2, &config, 1, &numConfigs);
        const EGLint context_attribs[] = {
                // 设置context针对的opengl-es的版本，（EGL_NONE设置的是默认值，为1）
                // 此处的版本需要和上面的EGL_RENDERABLE_TYPE 对应
                EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE
        };
        // 创建context，在context中保存了opengl-es的状态信息 （display，配置，共享context的handle 一般设为null，属性）
        // 一个display可以创建多个context
        if (!(context = eglCreateContext(display, config, 0, context_attribs))) {
//        Shader::eglPrintError("eglCreateContext()", eglGetError());
//        destroy();
            LOGE("witgao", "eglCreateContext");
            return;
        }
        // 将上面创建的context绑定到当前线程上，并将context与surface进行关联。当makeCurrent执行后，就可以调用opengl-es的api对context中的状态集进行设定，
        // 然后进而向surface中绘制内容，再把surface中的内容读取出来。
        if (!eglMakeCurrent(display, eglSurface, eglSurface, context)) {
//        Shader::eglPrintError("eglMakeCurrent()", eglGetError());
//        destroy();
            LOGE("witgao", "eglMakeCurrent");
            return;
        }

        if (!eglQuerySurface(display, eglSurface, EGL_WIDTH, &width) ||
            !eglQuerySurface(display, eglSurface, EGL_HEIGHT, &height)) {
//        Shader::eglPrintError("eglQuerySurface()", eglGetError());
//        destroy();
            LOGE("witgao", "eglQuerySurface");
            return;
        }
        LOGE("witgao", "width = %d,height = %d", width, height);
        _display = display;
        _surface = eglSurface;
//    _context = context;
//    if (!shader->initShader(NULL)) {
//        Shader::eglPrintError("initShader()", eglGetError());
//        destroy();
//        return false;
//    }
//    if (DEBUG)
//        LOGI(LOG_TAG_RENDERER, "initializeGL() context: %d windows: %p   %dx%d",
//             _context, _window, width, height);
        glClearColor(1, 1, 1, 1);
        glClear(GL_COLOR_BUFFER_BIT);
        // swap to clear window
        // 当opengl-es将内容绘制到了surface上，通过该函数，将surface中的color-buffer的内容交换到屏幕上显示。

//        glClearColor(1, 0, 0, 1);
//        glClear(GL_COLOR_BUFFER_BIT);
        if (!eglSwapBuffers(display, eglSurface)) {
            LOGE("witgao", "eglSwapBuffers");
//        Shader::eglPrintError("eglSwapBuffers()", eglGetError());
        }
    }

    void GLESHelper::swapBuffersEGL() {
        if (!eglSwapBuffers(_display, _surface)) {
            LOGE("witgao", "eglSwapBuffers");
//        Shader::eglPrintError("eglSwapBuffers()", eglGetError());
        }
    }
}

