import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/service/locale_service.dart';
import 'package:oasx/service/theme_service.dart';
import 'package:oasx/service/websocket_service.dart';
import 'package:oasx/service/window_service.dart';
import 'package:oasx/utils/logger.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:get/get.dart';
import 'package:win32/win32.dart';

import 'package:oasx/views/routes.dart';
import 'package:oasx/utils/platform_utils.dart';
import 'package:oasx/controller/settings.dart';
import 'package:oasx/config/theme.dart' show lightTheme, darkTheme;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 单实例：已经有 oasx 在跑时，不新开一个，而是把已有窗口叫到前面。
  // 以前每点一次图标就多一个进程 + 一个托盘图标。
  if (PlatformUtils.isWindows) {
    if (await _acquireSingleInstanceLock()) {
      // 拿到锁，说明是第一个实例，正常启动
    } else if (_activateExistingWindow()) {
      // 向已有实例交棒，自己退出
      exit(0);
    }
    // 找不到已有窗口（异常情况）时不做处理，继续正常启动，避免点了没反应
  }

  await initService();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode && (PlatformUtils.isWindows),
      builder: (context) => const OASXApp(), // Wrap your app
    ),
  );
}

/// 进程生命周期内保持监听的本机端口，用来判定单实例。
/// 用端口而不是文件锁：Dart 的 FileLock 在锁被占用时会阻塞等待，不会抛异常，
/// 结果第二个实例直接卡死在 lock()，窗口也不出来。
ServerSocket? _instanceSocket;

/// 绑定本机固定端口：成功=首个实例，失败=已有实例占着
Future<bool> _acquireSingleInstanceLock() async {
  try {
    _instanceSocket = await ServerSocket.bind(
      InternetAddress.loopbackIPv4,
      45913,
    );
    return true;
  } catch (_) {
    return false;
  }
}

/// 找到已运行实例的窗口，还原并置前。
/// 窗口标题在 windows/runner/main.cpp 里固定为 "oasx"。
bool _activateExistingWindow() {
  const swShow = 5;
  const swRestore = 9;

  for (var i = 0; i < 5; i++) {
    final title = 'oasx'.toNativeUtf16();
    try {
      final hwnd = FindWindow(nullptr, title);
      if (hwnd != 0) {
        if (IsIconic(hwnd) != 0) {
          ShowWindow(hwnd, swRestore);
        } else {
          ShowWindow(hwnd, swShow);
        }
        SetForegroundWindow(hwnd);
        return true;
      }
    } finally {
      calloc.free(title);
    }
    // 已有实例可能正在初始化窗口，稍等再试
    sleep(const Duration(milliseconds: 400));
  }
  return false;
}

class OASXApp extends StatelessWidget {
  const OASXApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final localeService = Get.find<LocaleService>();

    return ResponsiveApp(builder: (context) {
      return GetMaterialApp(
        // useInheritedMediaQuery: true,
        debugShowCheckedModeBanner: false,
        // locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder, // 上面三个是使用device_preview
        scrollBehavior: GlobalBehavior(),
        translations: localeService.messages,
        locale: localeService.currentLocale,
        fallbackLocale: localeService.fallbackLocale, //语言选择无效时，备用语言
        title: 'OASX',
        onInit: onInit,
        initialRoute: Routes.initial,
        getPages: Routes.routes,
        theme: lightTheme,
        darkTheme: darkTheme,
      );
    });
  }

  /// 但是我不能确定 Getx 框架这个时候是否成功初始化
  void onInit() {
    Get.put(SettingsController());
  }
}

class GlobalBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        // etc.
      };
}

Future<void> initService() async {
  await initLogger();
  await GetStorage.init();

  await Future.wait([
    Get.putAsync(() async => LocaleService()),
    Get.putAsync(() async => ThemeService()),
    Get.putAsync(() async => WindowService()),
  ]);

  Get.lazyPut(() => WebSocketService());
}
