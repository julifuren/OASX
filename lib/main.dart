import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/service/locale_service.dart';
import 'package:oasx/service/single_instance.dart';
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

  // 单实例：已经有 oasx 在跑时，不新开一个，而是让老实例把窗口显示出来。
  // 以前每点一次图标就多一个进程 + 一个托盘图标。
  if (PlatformUtils.isWindows) {
    final isFirst = await SingleInstance.acquire();
    if (!isFirst) {
      // 让老实例自己显示窗口；万一来不及（正在启动中）再退化为跨进程激活
      final notified = await SingleInstance.requestActivate();
      if (notified || _activateExistingWindow()) {
        exit(0);
      }
      // 两条路都失败时不退出，继续正常启动，避免「点了没反应」
    }
  }

  await initService();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode && (PlatformUtils.isWindows),
      builder: (context) => const OASXApp(), // Wrap your app
    ),
  );
}

/// 兜底：直接跨进程把已有窗口显示出来。
/// 只在老实例还没就绪、没响应端口信号时用到。
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
