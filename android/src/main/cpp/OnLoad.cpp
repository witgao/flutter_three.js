//
// Created by zhenyu on 2019/3/16.
//
#include <jni.h>
#include <functional>
#include "dart_gl_extension.h"

namespace threejs {
        jint initialize(JavaVM *vm) noexcept {
            try {
                JNIEnv *env = NULL;
                vm->GetEnv((void **) &env, JNI_VERSION_1_6);
                if (JNI_FALSE == Register::registerNatives(env)) {
                    return JNI_ERR;
                }
                return JNI_VERSION_1_6;
            } catch (const std::exception &e) {
                return JNI_ERR;
            }
        }
}

extern "C" JNIEXPORT jint JNI_OnLoad(JavaVM *vm, void *reserved) {
    return threejs::initialize(vm);
}


