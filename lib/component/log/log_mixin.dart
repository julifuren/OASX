import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:path_provider/path_provider.dart';

/// 日志级别筛选
enum LogLevelFilter { all, info, warning, error }

mixin LogMixin on GetxController {
  /// max lines to store in log
  int get maxLines => 500;

  /// max logs+pending
  int get maxBuffer => 3000;

  /// max burst line when refreshing
  int get maxBurst => 50;

  /// min burst line when refreshing
  int get minBurst => 1;

  /// ui log
  final logs = <String>[].obs;

  /// auto scroll to bottom
  final autoScroll = true.obs;

  /// collapse log content
  final collapseLog = false.obs;

  /// 级别筛选（全部 / INFO / WARNING / ERROR）
  final levelFilter = LogLevelFilter.all.obs;

  /// 关键字过滤
  final searchText = ''.obs;

  /// 暂停：仍然收日志进缓冲，但不刷到界面上，方便盯住当前几行
  final paused = false.obs;

  /// logs buffer, used to limit speeded log refresh
  final _pendingLogs = <String>[];

  /// refresh timer for log
  Timer? _refreshTimer;

  double _savedScrollOffset = 0.0;

  void Function({bool isJump, bool force, int scrollOffset})? scrollLogs;

  @override
  void onInit() {
    _refreshTimer ??= Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_pendingLogs.isEmpty) {
        return;
      }
      _clearOverflowLogs();
      // 暂停时只保留数据，不刷新界面
      if (paused.value) {
        return;
      }
      _updateUILogs();
      _removeUIOldLogs();
      scrollLogs?.call();
    });
    super.onInit();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    super.onClose();
  }

  /// 按级别 + 关键字过滤后的日志，界面只渲染这个
  List<String> get filteredLogs {
    final keyword = searchText.value.trim().toLowerCase();
    final level = levelFilter.value;
    if (level == LogLevelFilter.all && keyword.isEmpty) {
      return logs;
    }
    return logs.where((line) {
      if (level != LogLevelFilter.all) {
        final upper = line.toUpperCase();
        final bool hit = switch (level) {
          LogLevelFilter.error =>
            upper.contains('ERROR') || upper.contains('CRITICAL'),
          LogLevelFilter.warning => upper.contains('WARNING'),
          LogLevelFilter.info => upper.contains('INFO'),
          LogLevelFilter.all => true,
        };
        if (!hit) return false;
      }
      if (keyword.isNotEmpty && !line.toLowerCase().contains(keyword)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  /// 各级别条数，用于在筛选按钮上显示角标
  Map<LogLevelFilter, int> get levelCounts {
    var info = 0, warning = 0, error = 0;
    for (final line in logs) {
      final upper = line.toUpperCase();
      if (upper.contains('ERROR') || upper.contains('CRITICAL')) {
        error++;
      } else if (upper.contains('WARNING')) {
        warning++;
      } else if (upper.contains('INFO')) {
        info++;
      }
    }
    return {
      LogLevelFilter.all: logs.length,
      LogLevelFilter.info: info,
      LogLevelFilter.warning: warning,
      LogLevelFilter.error: error,
    };
  }

  void setLevelFilter(LogLevelFilter value) => levelFilter.value = value;

  void setSearchText(String value) => searchText.value = value;

  void togglePause() {
    paused.value = !paused.value;
    if (!paused.value) {
      scrollLogs?.call(force: true, scrollOffset: -1);
    }
  }

  void _removeUIOldLogs() {
    // 非自动滚动状态下,且未溢出(已删除溢出部分),则不删除旧日志,使用户可以停留
    if (!autoScroll.value) return;
    // UI 限制：只保留最新 maxLines 行
    if (logs.length > maxLines) {
      logs.removeRange(0, logs.length - maxLines);
    }
  }

  void _updateUILogs() {
    // 根据 backlog 动态调整本次要处理多少条
    int backlog = _pendingLogs.length;
    int burst = backlog.clamp(minBurst, maxBurst);
    for (int i = 0; i < burst && _pendingLogs.isNotEmpty; i++) {
      logs.add(_pendingLogs.removeAt(0));
    }
  }

  void _clearOverflowLogs() {
    // 计算总大小
    int totalSize = logs.length + _pendingLogs.length;
    if (totalSize > maxBuffer) {
      int overflow = totalSize - maxBuffer;
      // 优先删除 logs 里最老的
      if (overflow > 0) {
        int removeFromLogs = min(overflow, logs.length);
        if (removeFromLogs > 0) {
          logs.removeRange(0, removeFromLogs);
          overflow -= removeFromLogs;
        }
      }
      // 如果还不够，就从 pending 里删除最老的
      if (overflow > 0 && _pendingLogs.isNotEmpty) {
        int removeFromPending = min(overflow, _pendingLogs.length);
        _pendingLogs.removeRange(0, removeFromPending);
      }
    }
  }

  void addLog(String log) {
    _pendingLogs.add(log);
  }

  void clearLog() {
    logs.clear();
    _pendingLogs.clear();
  }

  void copyLogs() {
    final allLogs = logs.join("");
    Clipboard.setData(ClipboardData(text: allLogs));
    Get.snackbar(I18n.tip.tr, I18n.copy_success.tr,
        duration: const Duration(seconds: 1));
  }

  /// 导出当前筛选结果到文件，排查问题时直接发给别人
  Future<void> exportLogs() async {
    try {
      final dir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      String two(int v) => v.toString().padLeft(2, '0');
      final name = 'oasx_log_${now.year}${two(now.month)}${two(now.day)}'
          '_${two(now.hour)}${two(now.minute)}${two(now.second)}.txt';
      final file = File('${dir.path}${Platform.pathSeparator}$name');
      final lines = filteredLogs;
      await file.writeAsString(
        '导出时间: ${now.toString()}\n'
        '筛选条件: ${levelFilter.value.name} / 关键字: ${searchText.value}\n'
        '行数: ${lines.length}\n'
        '${'-' * 40}\n'
        '${lines.join()}',
      );
      Get.snackbar('导出成功', file.path,
          duration: const Duration(seconds: 4));
    } catch (e) {
      Get.snackbar('导出失败', '$e', duration: const Duration(seconds: 4));
    }
  }

  void toggleAutoScroll() {
    autoScroll.value = !autoScroll.value;
    if (autoScroll.value) {
      scrollLogs?.call(force: true, scrollOffset: -1);
    }
  }

  void toggleCollapse() => collapseLog.value = !collapseLog.value;

  double get savedScrollOffsetVal => _savedScrollOffset;
  void saveScrollOffset(double offset) {
    _savedScrollOffset = offset;
  }
}
