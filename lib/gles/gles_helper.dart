import 'dart:ffi' as ffi;
import "dart:convert";
import "dart:async";

typedef _NativeInitEGL = ffi.Int64 Function(ffi.Int32, ffi.Int32, ffi.Int32);
typedef _DartInitEGL = int Function(int, int, int);

typedef _NativeSwapBuffersEGL = ffi.Void Function(ffi.Int64);
typedef _DartSwapBuffersEGL = void Function(int);

typedef _NativeGlClearColor = ffi.Void Function(
    ffi.Float, ffi.Float, ffi.Float, ffi.Float);
typedef _DartGlClearColor = void Function(double, double, double, double);

typedef _NativeGlClear = ffi.Void Function(ffi.Int32);
typedef _DartGlClear = void Function(int);

typedef _NativeGlCreateShader = ffi.Int32 Function(ffi.Int32);
typedef _DartGlCreateShader = int Function(int);

typedef _NativeGlShaderSource = ffi.Void Function(
    ffi.Int32, ffi.Int32, ffi.Pointer<Utf8>, ffi.Pointer<ffi.Int32>, ffi.Int32);
typedef _DartGlShaderSource = void Function(
    int, int, ffi.Pointer<Utf8>, ffi.Pointer<ffi.Int32>, int);
//
//int Function(Pointer<Utf8> filename, Pointer<Pointer<Database>> databaseOut,
//    int flags, Pointer<Utf8> vfs) sqlite3_open_v2;
//
//typedef sqlite3_open_v2_native_t = Int32 Function(Pointer<Utf8> filename,
//    Pointer<Pointer<Database>> ppDb, Int32 flags, Pointer<Utf8> vfs);

class GLESHelper {
  ffi.DynamicLibrary _threejsLibrary;
  ffi.DynamicLibrary _gles2Library;

  _DartInitEGL _initEGLFun;
  _DartSwapBuffersEGL _swapBuffersEGLFun;

  var _glClearColorFun;
  var _glClearFun;
  var _glCreateShaderFun;
  var _glShaderSourceFun;

  int _nativeGLESHelper;

  GLESHelper() {
    _loadEGLLibrary();
    _loadGLESLibrary();
  }

  void _loadEGLLibrary() {
    _threejsLibrary = ffi.DynamicLibrary.open("libflutter-threejs.so");
    _initEGLFun =
        _threejsLibrary.lookupFunction<_NativeInitEGL, _DartInitEGL>("initEGL");
    _swapBuffersEGLFun = _threejsLibrary.lookupFunction<_NativeSwapBuffersEGL,
        _DartSwapBuffersEGL>("swapBuffersEGL");
  }

  void _loadGLESLibrary() {
    _gles2Library = ffi.DynamicLibrary.open("libGLESv2.so");

    _glClearColorFun = _gles2Library
        .lookupFunction<_NativeGlClearColor, _DartGlClearColor>("glClearColor");

    _glClearFun =
        _gles2Library.lookupFunction<_NativeGlClear, _DartGlClear>("glClear");

    _glCreateShaderFun = _gles2Library.lookupFunction<_NativeGlCreateShader,
        _DartGlCreateShader>("glCreateShader");

    _glShaderSourceFun = _gles2Library.lookupFunction<_NativeGlShaderSource,
        _DartGlShaderSource>("glShaderSource");
  }

  void initEGL(nativeWindow) {
    _nativeGLESHelper = _initEGLFun(nativeWindow, 100, 100);
  }

  void swapBuffersEGL() {
    _swapBuffersEGLFun(_nativeGLESHelper);
  }

  void glClearColor(double red, double green, double blue, double alpha) {
    _glClearColorFun(red, green, blue, alpha);
  }

  void glClear(int mask) {
    _glClearFun(mask);
  }
}

/// [Arena] manages allocated C memory.
///
/// Arenas are zoned.
class Arena {
  Arena();

  List<ffi.Pointer<ffi.Void>> _allocations = [];

  /// Bound the lifetime of [ptr] to this [Arena].
  T scoped<T extends ffi.Pointer>(T ptr) {
    _allocations.add(ptr.cast());
    return ptr;
  }

  /// Frees all memory pointed to by [Pointer]s in this arena.
  void finalize() {
    for (final ptr in _allocations) {
      ptr.free();
    }
  }

  /// The last [Arena] in the zone.
  factory Arena.current() {
    return Zone.current[#_currentArena];
  }
}

/// Bound the lifetime of [ptr] to the current [Arena].
T scoped<T extends ffi.Pointer>(T ptr) => Arena.current().scoped(ptr);

class RethrownError {
  dynamic original;
  StackTrace originalStackTrace;

  RethrownError(this.original, this.originalStackTrace);

  toString() => """RethrownError(${original})
${originalStackTrace}""";
}

/// Runs the [body] in an [Arena] freeing all memory which is [scoped] during
/// execution of [body] at the end of the execution.
R runArena<R>(R Function(Arena) body) {
  Arena arena = Arena();
  try {
    return runZoned(() => body(arena),
        zoneValues: {#_currentArena: arena},
        onError: (error, st) => throw RethrownError(error, st));
  } finally {
    arena.finalize();
  }
}

class Utf8 extends ffi.Struct<Utf8> {
  @ffi.Int8()
  int char;

  /// Allocates a [CString] in the current [Arena] and populates it with
  /// [dartStr].
  static ffi.Pointer<Utf8> fromString(String dartStr) =>
      Utf8.fromStringArena(Arena.current(), dartStr);

  /// Allocates a [CString] in [arena] and populates it with [dartStr].
  static ffi.Pointer<Utf8> fromStringArena(Arena arena, String dartStr) =>
      arena.scoped(allocate(dartStr));

  /// Allocate a [CString] not managed in and populates it with [dartStr].
  ///
  /// This [CString] is not managed by an [Arena]. Please ensure to [free] the
  /// memory manually!
  static ffi.Pointer<Utf8> allocate(String dartStr) {
    List<int> units = Utf8Encoder().convert(dartStr);
    ffi.Pointer<Utf8> str = ffi.Pointer.allocate(count: units.length + 1);
    for (int i = 0; i < units.length; ++i) {
      str.elementAt(i).load<Utf8>().char = units[i];
    }
    str.elementAt(units.length).load<Utf8>().char = 0;
    return str.cast();
  }

  /// Read the string for C memory into Dart.
  String toString() {
    final str = addressOf;
    if (str == ffi.nullptr) return null;
    int len = 0;
    while (str.elementAt(++len).load<Utf8>().char != 0);
    List<int> units = List(len);
    for (int i = 0; i < len; ++i) units[i] = str.elementAt(i).load<Utf8>().char;
    return Utf8Decoder().convert(units);
  }
}
