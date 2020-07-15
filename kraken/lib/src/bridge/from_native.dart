import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:flutter/painting.dart';

import 'package:kraken/launcher.dart';
import 'package:kraken/element.dart';
import 'package:kraken/bridge.dart';
import 'package:kraken/module.dart';
import 'package:vibration/vibration.dart';
import 'platform.dart';

// Steps for using dart:ffi to call a Dart function from C:
// 1. Import dart:ffi.
// 2. Create a typedef with the FFI type signature of the Dart function.
// 3. Create a typedef for the variable that you’ll use when calling the
//    Dart function.
// 4. Open the dynamic library that register in the C.
// 5. Get a reference to the C function, and put it into a variable.
// 6. Call from C.

// Register InvokeUIManager
typedef Native_InvokeUIManager = Pointer<Utf8> Function(Pointer<JSContext> context, Int32 contextIndex, Pointer<Utf8>);
typedef Native_RegisterInvokeUIManager = Void Function(Pointer<NativeFunction<Native_InvokeUIManager>>);
typedef Dart_RegisterInvokeUIManager = void Function(Pointer<NativeFunction<Native_InvokeUIManager>>);

final Dart_RegisterInvokeUIManager _registerInvokeUIManager =
    nativeDynamicLibrary.lookup<NativeFunction<Native_RegisterInvokeUIManager>>('registerInvokeUIManager').asFunction();

const String BATCH_UPDATE = 'batchUpdate';
const String EMPTY_STRING = '';

String handleAction(Pointer<JSContext> context, int contextIndex, List directive) {
  String action = directive[0];
  List payload = directive[1];

  KrakenViewController controller = KrakenViewController.getViewControllerOfJSContextIndex(contextIndex);
  ElementManager elementManager = controller.getElementManager();

  var result = elementManager.applyAction(action, payload);

  if (result == null) {
    return EMPTY_STRING;
  }

  switch (result.runtimeType) {
    case String:
      return result;
    case Map:
    case List:
      return jsonEncode(result);
    default:
      return result.toString();
  }
}

String invokeUIManager(Pointer<JSContext> context, int contextIndex, String json) {
  dynamic directive = jsonDecode(json);

  if (directive == null) {
    return EMPTY_STRING;
  }

  if (directive[0] == BATCH_UPDATE) {
    List<dynamic> directiveList = directive[1];
    List<String> result = [];
    for (dynamic item in directiveList) {
      result.add(handleAction(context, contextIndex, item as List));
    }
    return EMPTY_STRING;
  } else {
    return handleAction(context, contextIndex, directive);
  }
}

Pointer<Utf8> _invokeUIManager(Pointer<JSContext> context, int contextIndex, Pointer<Utf8> json) {
  try {
    String result = invokeUIManager(context, contextIndex, Utf8.fromUtf8(json));
    return Utf8.toUtf8(result);
  } catch (e, stack) {
    return Utf8.toUtf8('Error: $e\n$stack');
  }
}

void registerInvokeUIManager() {
  Pointer<NativeFunction<Native_InvokeUIManager>> pointer = Pointer.fromFunction(_invokeUIManager);
  _registerInvokeUIManager(pointer);
}

// Register InvokeModule
typedef NativeAsyncModuleCallback = Void Function(Pointer<JSContext> context, Int32 contextIndex, Pointer<Utf8> json);
typedef DartAsyncModuleCallback = void Function(Pointer<JSContext> context, int contextIndex, Pointer<Utf8> json);

typedef Native_InvokeModule = Pointer<Utf8> Function(
    Pointer<JSContext> context, Int32 contextIndex,
    Pointer<Utf8>, Pointer<NativeFunction<NativeAsyncModuleCallback>>);
typedef Native_RegisterInvokeModule = Void Function(Pointer<NativeFunction<Native_InvokeModule>>);
typedef Dart_RegisterInvokeModule = void Function(Pointer<NativeFunction<Native_InvokeModule>>);

final Dart_RegisterInvokeModule _registerInvokeModule =
    nativeDynamicLibrary.lookup<NativeFunction<Native_RegisterInvokeModule>>('registerInvokeModule').asFunction();

String invokeModule(Pointer<JSContext> context, int contextIndex, String json, DartAsyncModuleCallback callback) {
  dynamic args = jsonDecode(json);
  String module = args[0];
  String result = EMPTY_STRING;
  try {
    if (module == 'Connection') {
      String method = args[1];
      if (method == 'getConnectivity') {
        Connection.getConnectivity((String json) {
          callback(context, contextIndex, Utf8.toUtf8(json));
        });
      } else if (method == 'onConnectivityChanged') {
        Connection.onConnectivityChanged((String json) {
          emitModuleEvent(context, contextIndex, '["onConnectivityChanged", $json]');
        });
      }
    } else if (module == 'fetch') {
      List fetchArgs = args[1];
      String url = fetchArgs[0];
      Map<String, dynamic> options = fetchArgs[1];
      fetch(url, options).then((Response response) {
        String json = jsonEncode(['', response.statusCode, response.data]);
        callback(context, contextIndex, Utf8.toUtf8(json));
      }).catchError((e, stack) {
        String errorMessage = e.message;
        String json;
        if (e.type == DioErrorType.RESPONSE) {
          json = jsonEncode([errorMessage, e.response.statusCode, EMPTY_STRING]);
        } else {
          json = jsonEncode(['$errorMessage\n$stack', null, EMPTY_STRING]);
        }
        callback(context, contextIndex, Utf8.toUtf8(json));
      });
    } else if (module == 'DeviceInfo') {
      String method = args[1];
      if (method == 'getDeviceInfo') {
        DeviceInfo.getDeviceInfo().then((String json) {
          callback(context, contextIndex, Utf8.toUtf8(json));
        });
      } else if (method == 'getHardwareConcurrency') {
        result = DeviceInfo.getHardwareConcurrency().toString();
      }
    } else if (module == 'AsyncStorage') {
      String method = args[1];
      if (method == 'getItem') {
        List methodArgs = args[2];
        String key = methodArgs[0];
        // @TODO: catch error case
        AsyncStorage.getItem(key).then((String value) {
          callback(context, contextIndex, Utf8.toUtf8(value ?? EMPTY_STRING));
        }).catchError((e, stack) {
          callback(context, contextIndex, Utf8.toUtf8('Error: $e\n$stack'));
        });
      } else if (method == 'setItem') {
        List methodArgs = args[2];
        String key = methodArgs[0];
        String value = methodArgs[1];
        AsyncStorage.setItem(key, value).then((bool isSuccess) {
          callback(context, contextIndex, Utf8.toUtf8(isSuccess.toString()));
        }).catchError((e, stack) {
          callback(context, contextIndex, Utf8.toUtf8('Error: $e\n$stack'));
        });
      } else if (method == 'removeItem') {
        List methodArgs = args[2];
        String key = methodArgs[0];
        AsyncStorage.removeItem(key).then((bool isSuccess) {
          callback(context, contextIndex, Utf8.toUtf8(isSuccess.toString()));
        }).catchError((e, stack) {
          callback(context, contextIndex, Utf8.toUtf8('Error: $e\n$stack'));
        });
      } else if (method == 'getAllKeys') {
        // @TODO: catch error case
        AsyncStorage.getAllKeys().then((Set<String> set) {
          List<String> list = List.from(set);
          callback(context, contextIndex, Utf8.toUtf8(jsonEncode(list)));
        }).catchError((e, stack) {
          callback(context, contextIndex, Utf8.toUtf8('Error: $e\n$stack'));
        });
      } else if (method == 'clear') {
        AsyncStorage.clear().then((bool isSuccess) {
          callback(context, contextIndex, Utf8.toUtf8(isSuccess.toString()));
        }).catchError((e, stack) {
          callback(context, contextIndex, Utf8.toUtf8('Error: $e\n$stack'));
        });
      }
    } else if (module == 'MQTT') {
      String method = args[1];
      if (method == 'init') {
        List methodArgs = args[2];
        return MQTT.init(methodArgs[0], methodArgs[1]);
      } else if (method == 'open') {
        List methodArgs = args[2];
        MQTT.open(methodArgs[0], methodArgs[1]);
      } else if (method == 'close') {
        List methodArgs = args[2];
        MQTT.close(methodArgs[0]);
      } else if (method == 'publish') {
        List methodArgs = args[2];
        MQTT.publish(methodArgs[0], methodArgs[1], methodArgs[2], methodArgs[3], methodArgs[4]);
      } else if (method == 'subscribe') {
        List methodArgs = args[2];
        MQTT.subscribe(methodArgs[0], methodArgs[1], methodArgs[2]);
      } else if (method == 'unsubscribe') {
        List methodArgs = args[2];
        MQTT.unsubscribe(methodArgs[0], methodArgs[1]);
      } else if (method == 'getReadyState') {
        List methodArgs = args[2];
        return MQTT.getReadyState(methodArgs[0]);
      } else if (method == 'addEvent') {
        List methodArgs = args[2];
        MQTT.addEvent(methodArgs[0], methodArgs[1], (String id, String event) {
          emitModuleEvent(context, contextIndex, '["MQTT", $id, $event]');
        });
      }
    } else if (module == 'Geolocation') {
      String method = args[1];
      if (method == 'getCurrentPosition') {
        List positionArgs = args[2];
        Map<String, dynamic> options;
        if (positionArgs.length > 0) {
          options = positionArgs[0];
        }
        Geolocation.getCurrentPosition(options, (json) {
          callback(context, contextIndex, Utf8.toUtf8(json));
        });
      } else if (method == 'watchPosition') {
        List positionArgs = args[2];
        Map<String, dynamic> options;
        if (positionArgs.length > 0) {
          options = positionArgs[0];
        }
        return Geolocation.watchPosition(options, (String result) {
          emitModuleEvent(context, contextIndex, '["watchPosition", $result]');
        }).toString();
      } else if (method == 'clearWatch') {
        List positionArgs = args[2];
        int id = positionArgs[0];
        Geolocation.clearWatch(id);
      }
    } else if (module == 'Performance') {
      String method = args[1];
      if (method == 'now') {
        return Performance.now().toString();
      } else if (method == 'getTimeOrigin') {
        return Performance.getTimeOrigin().toString();
      }
    } else if (module == 'MethodChannel') {
      String method = args[1];
      if (method == 'invokeMethod') {
        List methodArgs = args[2];
        KrakenMethodChannel.invokeMethod(methodArgs[0], methodArgs[1]).then((result) {
          String ret;
          if (result is String) {
            ret = result;
          } else {
            ret = jsonEncode(result);
          }
          callback(context, contextIndex, Utf8.toUtf8(ret));
        }).catchError((e, stack) {
          callback(context, contextIndex, Utf8.toUtf8('Error: $e\n$stack'));
        });
      } else if (method == 'setMethodCallHandler') {
        KrakenMethodChannel.setMethodCallHandler((MethodCall call) async {
          emitModuleEvent(context, contextIndex, jsonEncode(['MethodChannel', call.method, call.arguments]));
        });
      }
    } else if (module == 'Clipboard') {
      String method = args[1];
      if (method == 'readText') {
        KrakenClipboard.readText().then((String value) {
          callback(context, contextIndex, Utf8.toUtf8(value ?? ''));
        }).catchError((e, stack) {
          callback(context, contextIndex, Utf8.toUtf8('Error: $e\n$stack'));
        });
      } else if (method == 'writeText') {
        List methodArgs = args[2];
        KrakenClipboard.writeText(methodArgs[0]).then((_) {
          callback(context, contextIndex, Utf8.toUtf8(EMPTY_STRING));
        }).catchError((e, stack) {
          callback(context, contextIndex, Utf8.toUtf8('Error: $e\n$stack'));
        });
      }
    } else if (module == 'WebSocket') {
      String method = args[1];
      if (method == 'init') {
        List methodArgs = args[2];
        return KrakenWebSocket.init(methodArgs[0], (String id, String event) {
          emitModuleEvent(context, contextIndex, '["WebSocket", $id, ${jsonEncode(event)}]');
        });
      } else if (method == 'addEvent') {
        List methodArgs = args[2];
        KrakenWebSocket.addEvent(methodArgs[0], methodArgs[1]);
      } else if (method == 'send') {
        List methodArgs = args[2];
        KrakenWebSocket.send(methodArgs[0], methodArgs[1]);
      } else if (method == 'close') {
        List methodArgs = args[2];
        KrakenWebSocket.close(methodArgs[0], methodArgs[1], methodArgs[2]);
      }
    } else if (module == 'Navigator') {
      String method = args[1];
      if (method == 'vibrate') {
        List methodArgs = args[2];
        if (methodArgs.length == 1) {
          int duration = methodArgs[0];
          Vibration.vibrate(duration: duration);
        } else {
          List<int> filteredArgs = [];
          for (var number in methodArgs) {
            if (number is double)
              filteredArgs.add(number.floor());
            else if (number is int) filteredArgs.add(number);
          }
          // Pattern must have even number of elements, default duration to 500ms.
          if (filteredArgs.length.isOdd) filteredArgs.add(500);
          Vibration.vibrate(pattern: filteredArgs);
        }
      } else if (method == 'cancelVibrate') {
        Vibration.cancel();
      }
    }
  } catch (e, stack) {
    // Dart side internal error should print it directly.
    print('$e\n$stack');
  }

  return result;
}

Pointer<Utf8> _invokeModule(
    Pointer<JSContext> context, int contextIndex,
    Pointer<Utf8> json, Pointer<NativeFunction<NativeAsyncModuleCallback>> callback) {
  String result = invokeModule(context, contextIndex, Utf8.fromUtf8(json), callback.asFunction());
  return Utf8.toUtf8(result);
}

void registerInvokeModule() {
  Pointer<NativeFunction<Native_InvokeModule>> pointer = Pointer.fromFunction(_invokeModule);
  _registerInvokeModule(pointer);
}

// Register reloadApp
typedef Native_ReloadApp = Void Function(Pointer<JSContext> context, Int32 contextIndex);
typedef Native_RegisterReloadApp = Void Function(Pointer<NativeFunction<Native_ReloadApp>>);
typedef Dart_RegisterReloadApp = void Function(Pointer<NativeFunction<Native_ReloadApp>>);

final Dart_RegisterReloadApp _registerReloadApp =
    nativeDynamicLibrary.lookup<NativeFunction<Native_RegisterReloadApp>>('registerReloadApp').asFunction();

void _reloadApp(Pointer<JSContext> context, int contextIndex) {
  KrakenViewController controller = KrakenViewController.getViewControllerOfJSContextIndex(contextIndex);

  try {
    controller.reloadCurrentView();
  } catch (e, stack) {
    print('Dart Error: $e\n$stack');
  }
}

void registerReloadApp() {
  Pointer<NativeFunction<Native_ReloadApp>> pointer = Pointer.fromFunction(_reloadApp);
  _registerReloadApp(pointer);
}

typedef NativeAsyncCallback = Void Function(Pointer<JSContext> context, Int32 contextIndex, Pointer<Utf8> timeout);
typedef DartAsyncCallback = void Function(Pointer<JSContext> context, int contextIndex, Pointer<Utf8> timeout);
typedef NativeRAFAsyncCallback = Void Function(Pointer<JSContext> context, Int32 contextIndex, Double data, Pointer<Utf8>);
typedef DartRAFAsyncCallback = void Function(Pointer<JSContext> context, int contextIndex, double data, Pointer<Utf8>);

// Register requestBatchUpdate
typedef Native_RequestBatchUpdate = Void Function(Pointer<JSContext> context, Int32 contextIndex, Pointer<NativeFunction<NativeAsyncCallback>>);
typedef Native_RegisterRequestBatchUpdate = Void Function(Pointer<NativeFunction<Native_RequestBatchUpdate>>);
typedef Dart_RegisterRequestBatchUpdate = void Function(Pointer<NativeFunction<Native_RequestBatchUpdate>>);

final Dart_RegisterRequestBatchUpdate _registerRequestBatchUpdate = nativeDynamicLibrary
    .lookup<NativeFunction<Native_RegisterRequestBatchUpdate>>('registerRequestBatchUpdate')
    .asFunction();

void _requestBatchUpdate(Pointer<JSContext> context, int contextIndex, Pointer<NativeFunction<NativeAsyncCallback>> callback) {
  return requestBatchUpdate((Duration timeStamp) {
    DartAsyncCallback func = callback.asFunction();
    try {
      func(context, contextIndex, nullptr);
    } catch (e, stack) {
      func(context, contextIndex, Utf8.toUtf8('Error: $e\n$stack'));
    }
  });
}

void registerRequestBatchUpdate() {
  Pointer<NativeFunction<Native_RequestBatchUpdate>> pointer = Pointer.fromFunction(_requestBatchUpdate);
  _registerRequestBatchUpdate(pointer);
}

// Register setTimeout
typedef Native_SetTimeout = Int32 Function(Pointer<JSContext> context, Int32 contextIndex, Pointer<NativeFunction<NativeAsyncCallback>>, Int32);
typedef Native_RegisterSetTimeout = Void Function(Pointer<NativeFunction<Native_SetTimeout>>);
typedef Dart_RegisterSetTimeout = void Function(Pointer<NativeFunction<Native_SetTimeout>>);

final Dart_RegisterSetTimeout _registerSetTimeout =
    nativeDynamicLibrary.lookup<NativeFunction<Native_RegisterSetTimeout>>('registerSetTimeout').asFunction();

int _setTimeout(Pointer<JSContext> context, int contextIndex, Pointer<NativeFunction<NativeAsyncCallback>> callback, int timeout) {
  return setTimeout(timeout, () {
    DartAsyncCallback func = callback.asFunction();
    try {
      func(context, contextIndex, nullptr);
    } catch (e, stack) {
      func(context, contextIndex, Utf8.toUtf8('Error: $e\n$stack'));
    }
  });
}

const int SET_TIMEOUT_ERROR = -1;
void registerSetTimeout() {
  Pointer<NativeFunction<Native_SetTimeout>> pointer = Pointer.fromFunction(_setTimeout, SET_TIMEOUT_ERROR);
  _registerSetTimeout(pointer);
}

// Register setInterval
typedef Native_SetInterval = Int32 Function(Pointer<JSContext>, Int32 contextIndex, Pointer<NativeFunction<NativeAsyncCallback>>, Int32);
typedef Native_RegisterSetInterval = Void Function(Pointer<NativeFunction<Native_SetTimeout>>);
typedef Dart_RegisterSetInterval = void Function(Pointer<NativeFunction<Native_SetTimeout>>);

final Dart_RegisterSetInterval _registerSetInterval =
    nativeDynamicLibrary.lookup<NativeFunction<Native_RegisterSetTimeout>>('registerSetInterval').asFunction();

int _setInterval(Pointer<JSContext> context, int contextIndex, Pointer<NativeFunction<NativeAsyncCallback>> callback, int timeout) {
  return setInterval(timeout, () {
    DartAsyncCallback func = callback.asFunction();
    try {
      func(context, contextIndex, nullptr);
    } catch (e, stack) {
      func(context, contextIndex, Utf8.toUtf8('Dart Error: $e\n$stack'));
    }
  });
}

const int SET_INTERVAL_ERROR = -1;
void registerSetInterval() {
  Pointer<NativeFunction<Native_SetInterval>> pointer = Pointer.fromFunction(_setInterval, SET_INTERVAL_ERROR);
  _registerSetInterval(pointer);
}

// Register clearTimeout
typedef Native_ClearTimeout = Void Function(Int32);
typedef Native_RegisterClearTimeout = Void Function(Pointer<NativeFunction<Native_ClearTimeout>>);
typedef Dart_RegisterClearTimeout = void Function(Pointer<NativeFunction<Native_ClearTimeout>>);

final Dart_RegisterClearTimeout _registerClearTimeout =
    nativeDynamicLibrary.lookup<NativeFunction<Native_RegisterClearTimeout>>('registerClearTimeout').asFunction();

void _clearTimeout(int timerId) {
  return clearTimeout(timerId);
}

void registerClearTimeout() {
  Pointer<NativeFunction<Native_ClearTimeout>> pointer = Pointer.fromFunction(_clearTimeout);
  _registerClearTimeout(pointer);
}

// Register requestAnimationFrame
typedef Native_RequestAnimationFrame = Int32 Function(Pointer<JSContext> context, Int32 contextIndex, Pointer<NativeFunction<NativeRAFAsyncCallback>>);
typedef Native_RegisterRequestAnimationFrame = Void Function(Pointer<NativeFunction<Native_RequestAnimationFrame>>);
typedef Dart_RegisterRequestAnimationFrame = void Function(Pointer<NativeFunction<Native_RequestAnimationFrame>>);

final Dart_RegisterRequestAnimationFrame _registerRequestAnimationFrame = nativeDynamicLibrary
    .lookup<NativeFunction<Native_RegisterRequestAnimationFrame>>('registerRequestAnimationFrame')
    .asFunction();

int _requestAnimationFrame(Pointer<JSContext> context, int contextIndex, Pointer<NativeFunction<NativeRAFAsyncCallback>> callback) {
  return requestAnimationFrame((double highResTimeStamp) {
    DartRAFAsyncCallback func = callback.asFunction();
    try {
      func(context, contextIndex, highResTimeStamp, nullptr);
    } catch (e, stack) {
      func(context, contextIndex, highResTimeStamp, Utf8.toUtf8('Error: $e\n$stack'));
    }
  });
}

const int RAF_ERROR_CODE = -1;
// `-1` represents some error occurred in requestAnimationFrame execution.
void registerRequestAnimationFrame() {
  Pointer<NativeFunction<Native_RequestAnimationFrame>> pointer =
      Pointer.fromFunction(_requestAnimationFrame, RAF_ERROR_CODE);
  _registerRequestAnimationFrame(pointer);
}

// Register cancelAnimationFrame
typedef Native_CancelAnimationFrame = Void Function(Pointer<JSContext> context, Int32 contextIndex, Int32 id);
typedef Native_RegisterCancelAnimationFrame = Void Function(Pointer<NativeFunction<Native_CancelAnimationFrame>>);
typedef Dart_RegisterCancelAnimationFrame = void Function(Pointer<NativeFunction<Native_CancelAnimationFrame>>);

final Dart_RegisterCancelAnimationFrame _registerCancelAnimationFrame = nativeDynamicLibrary
    .lookup<NativeFunction<Native_RegisterCancelAnimationFrame>>('registerCancelAnimationFrame')
    .asFunction();

void _cancelAnimationFrame(Pointer<JSContext> context, int contextIndex, int timerId) {
  // TODO cancelAnimationFrame
//  cancelAnimationFrame(context, contextIndex, timerId);
}

void registerCancelAnimationFrame() {
  Pointer<NativeFunction<Native_CancelAnimationFrame>> pointer = Pointer.fromFunction(_cancelAnimationFrame);
  _registerCancelAnimationFrame(pointer);
}

// Register devicePixelRatio
typedef Native_DevicePixelRatio = Double Function();
typedef Native_RegisterDevicePixelRatio = Void Function(Pointer<NativeFunction<Native_DevicePixelRatio>>);
typedef Dart_RegisterDevicePixelRatio = void Function(Pointer<NativeFunction<Native_DevicePixelRatio>>);

final Dart_RegisterDevicePixelRatio _registerDevicePixelRatio = nativeDynamicLibrary
    .lookup<NativeFunction<Native_RegisterDevicePixelRatio>>('registerDevicePixelRatio')
    .asFunction();

double _devicePixelRatio() {
  return window.devicePixelRatio;
}

void registerDevicePixelRatio() {
  Pointer<NativeFunction<Native_DevicePixelRatio>> pointer = Pointer.fromFunction(_devicePixelRatio, 0.0);
  _registerDevicePixelRatio(pointer);
}

// Register platformBrightness
typedef Native_PlatformBrightness = Pointer<Utf8> Function();
typedef Native_RegisterPlatformBrightness = Void Function(Pointer<NativeFunction<Native_PlatformBrightness>>);
typedef Dart_RegisterPlatformBrightness = void Function(Pointer<NativeFunction<Native_PlatformBrightness>>);

final Dart_RegisterPlatformBrightness _registerPlatformBrightness = nativeDynamicLibrary
    .lookup<NativeFunction<Native_RegisterPlatformBrightness>>('registerPlatformBrightness')
    .asFunction();

final Pointer<Utf8> _dark = Utf8.toUtf8('dark');
final Pointer<Utf8> _light = Utf8.toUtf8('light');

Pointer<Utf8> _platformBrightness() {
  return window.platformBrightness == Brightness.dark ? _dark : _light;
}

void registerPlatformBrightness() {
  Pointer<NativeFunction<Native_PlatformBrightness>> pointer = Pointer.fromFunction(_platformBrightness);
  _registerPlatformBrightness(pointer);
}

// Register getScreen
class ScreenSize extends Struct {}

typedef Native_GetScreen = Pointer<ScreenSize> Function();
typedef Native_RegisterGetScreen = Void Function(Pointer<NativeFunction<Native_GetScreen>>);
typedef Dart_RegisterGetScreen = void Function(Pointer<NativeFunction<Native_GetScreen>>);

final Dart_RegisterGetScreen _registerGetScreen =
    nativeDynamicLibrary.lookup<NativeFunction<Native_RegisterGetScreen>>('registerGetScreen').asFunction();

Pointer<ScreenSize> _getScreen() {
  Size size = window.physicalSize;
  return createScreen(size.width / window.devicePixelRatio, size.height / window.devicePixelRatio);
}

void registerGetScreen() {
  Pointer<NativeFunction<Native_GetScreen>> pointer = Pointer.fromFunction(_getScreen);
  _registerGetScreen(pointer);
}

typedef NativeAsyncBlobCallback = Void Function(Pointer<JSContext> context, Int32 contextIndex, Pointer<Utf8>, Pointer<Uint8>, Int32);
typedef DartAsyncBlobCallback = void Function(Pointer<JSContext> context, int contextIndex, Pointer<Utf8>, Pointer<Uint8>, int);
typedef Native_ToBlob = Void Function(Pointer<JSContext> context, Int32 contextIndex, Pointer<NativeFunction<NativeAsyncBlobCallback>>, Int32, Double);
typedef Native_RegisterToBlob = Void Function(Pointer<NativeFunction<Native_ToBlob>>);
typedef Dart_RegisterToBlob = void Function(Pointer<NativeFunction<Native_ToBlob>>);

final Dart_RegisterToBlob _registerToBlob =
    nativeDynamicLibrary.lookup<NativeFunction<Native_RegisterToBlob>>('registerToBlob').asFunction();

void _toBlob(
    Pointer<JSContext> context,
    int contextIndex,
    Pointer<NativeFunction<NativeAsyncBlobCallback>> callback, int id, double devicePixelRatio) {
  DartAsyncBlobCallback func = callback.asFunction();
  KrakenViewController controller = KrakenViewController.getViewControllerOfJSContextIndex(contextIndex);
  ElementManager manager = controller.getElementManager();

  try {
    if (!manager.existsTarget(id)) {
      Pointer<Utf8> msg = Utf8.toUtf8('toBlob: unknown node id: $id');
      func(context, contextIndex, msg, nullptr, -1);
      return;
    }

    var node = manager.getEventTargetByTargetId<EventTarget>(id);
    if (node is Element) {
      node.toBlob(devicePixelRatio: devicePixelRatio).then((Uint8List bytes) {
        Pointer<Uint8> bytePtr = allocate<Uint8>(count: bytes.length);
        Uint8List byteList = bytePtr.asTypedList(bytes.length);
        byteList.setAll(0, bytes);
        func(context, contextIndex, nullptr, bytePtr, bytes.length);
      }).catchError((e, stack) {
        Pointer<Utf8> msg =
            Utf8.toUtf8('toBlob: failed to export image data from element id: $id. error: $e}.\n$stack');
        func(context, contextIndex, msg, nullptr, -1);
      });
    } else {
      Pointer<Utf8> msg = Utf8.toUtf8('toBlob: node is not an element, id: $id');
      func(context, contextIndex, msg, nullptr, -1);
      return;
    }
  } catch (e, stack) {
    Pointer<Utf8> msg = Utf8.toUtf8('toBlob: unexpected error: $e\n$stack');
    func(context, contextIndex, msg, nullptr, -1);
  }
}

void registerToBlob() {
  Pointer<NativeFunction<Native_ToBlob>> pointer = Pointer.fromFunction(_toBlob);
  _registerToBlob(pointer);
}

void registerDartMethodsToCpp() {
  registerInvokeUIManager();
  registerInvokeModule();
  registerRequestBatchUpdate();
  registerReloadApp();
  registerSetTimeout();
  registerSetInterval();
  registerClearTimeout();
  registerRequestAnimationFrame();
  registerCancelAnimationFrame();
  registerGetScreen();
  registerDevicePixelRatio();
  registerPlatformBrightness();
  registerToBlob();
}
