# For more information about using CMake with Android Studio, read the
# documentation: https://d.android.com/studio/projects/add-native-code.html

# Sets the minimum version of CMake required to build the native library.

cmake_minimum_required(VERSION 3.4.1)
set(CMAKE_C_FLAGS "-Wno-error=format-security")

add_library(flutter-threejs SHARED OnLoad.cpp dart_gl_extension.cpp dart_gl_extension.h)

find_library(log-lib log)
include_directories(${CMAKE_SOURCE_DIR}/../cpp)

include_directories(/Users/zhenyu/work/develop/flutter/bin/cache/dart-sdk/include)

target_link_libraries(flutter-threejs
        android
        EGL
        GLESv2
        ${log-lib})