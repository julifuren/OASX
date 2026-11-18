import 'dart:async';
import 'dart:io';

/// 单实例控制。
///
/// 第一个实例绑定本机端口并监听；后续启动的实例连上来发一个信号就退出，
/// 由**老实例自己**把窗口显示出来。
///
/// 为什么不让新实例直接 ShowWindow：跨进程改窗口可见状态后，
/// Flutter/window_manager 内部状态和实际窗口不一致，表现为窗口闪一下又没了。
class SingleInstance {
  SingleInstance._();

  static const int _port = 45913;

  static ServerSocket? _socket;

  /// 由 WindowService 在窗口就绪后注入：怎么把窗口叫出来
  static Future<void> Function()? _onActivate;

  /// 信号来得太早（窗口还没就绪）时先记下来，注入回调后补发
  static bool _pending = false;

  static set onActivate(Future<void> Function()? callback) {
    _onActivate = callback;
    if (callback != null && _pending) {
      _pending = false;
      callback();
    }
  }

  /// 抢占单实例：成功=自己是第一个，失败=已有实例在跑
  static Future<bool> acquire() async {
    try {
      _socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, _port);
      _socket!.listen((client) {
        client.destroy();
        final callback = _onActivate;
        if (callback == null) {
          _pending = true;
        } else {
          callback();
        }
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 通知已运行的实例显示窗口。发出去就算成功，窗口由对方负责显示。
  static Future<bool> requestActivate() async {
    try {
      final socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        _port,
        timeout: const Duration(seconds: 2),
      );
      socket.write('show');
      await socket.flush();
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }
}
