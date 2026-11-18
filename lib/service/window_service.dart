import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:get_storage/get_storage.dart';
import 'package:oasx/utils/platform_utils.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class WindowService extends GetxService with WindowListener, TrayListener {
  // ignore: unused_field
  final _storage = GetStorage();

  /// 真正退出标记：托盘菜单点「退出」时置 true，
  /// 否则 onWindowClose 一律走「隐藏到托盘」。
  bool _quitting = false;

  @override
  Future<void> onInit() async {
    if (PlatformUtils.isDesktop) {
      await windowManager.ensureInitialized();
      // 拦截关闭事件：点 X 不退出，改成隐藏到托盘
      await windowManager.setPreventClose(true);
      WindowOptions windowOptions = const WindowOptions(
        size: Size(1200, 800),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
        await _initTray();
      });
      windowManager.addListener(this);
      trayManager.addListener(this);
    }
    super.onInit();
  }

  Future<void> _initTray() async {
    await trayManager.setIcon('assets/icons/tray_icon.ico');
    await trayManager.setToolTip('OASX');
    Menu menu = Menu(items: [
      MenuItem(key: 'show', label: '显示窗口'),
      MenuItem.separator(),
      MenuItem(key: 'exit', label: '退出 OASX'),
    ]);
    await trayManager.setContextMenu(menu);
  }

  Future<void> _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  /// 点右上角 X：隐藏到托盘，进程继续运行
  @override
  void onWindowClose() async {
    if (_quitting) {
      return;
    }
    await windowManager.hide();
  }

  /// 左键单击托盘图标：显示 / 隐藏 来回切换
  @override
  void onTrayIconMouseDown() async {
    if (await windowManager.isVisible()) {
      await windowManager.hide();
    } else {
      await _showWindow();
    }
  }

  /// 右键：Windows 上 setContextMenu 只是注册菜单，必须在这里主动弹出
  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show':
        await _showWindow();
        break;
      case 'exit':
        // 真退出：先标记、再解掉拦截，最后关窗
        _quitting = true;
        await trayManager.destroy();
        await windowManager.setPreventClose(false);
        await windowManager.close();
        break;
    }
  }
}
