part of overview;

class OverviewController extends GetxController with LogMixin {
  String name;
  final scriptService = Get.find<ScriptService>();
  late final scriptModel = scriptService.findScriptModel(name)!;

  OverviewController({required this.name});

  @override
  void onInit() {
    super.onInit();
  }

  @override
  Future<void> onClose() async {
    // close log
    super.onClose();
  }

  Future<void> toggleScript() async {
    if (scriptModel.state.value != ScriptState.running) {
      scriptService.startScript(name);
      clearLog();
    } else {
      scriptService.stopScript(name);
    }
  }

  /// 重启脚本：先停止，等状态真的变成非 running，再启动。
  /// 不加等待直接 start 的话，后端会收到「停止中又来启动」，经常起不来。
  Future<void> restartScript() async {
    if (_restarting) return;
    _restarting = true;
    try {
      if (scriptModel.state.value == ScriptState.running) {
        scriptService.stopScript(name);
        final deadline = DateTime.now().add(const Duration(seconds: 15));
        while (scriptModel.state.value == ScriptState.running &&
            DateTime.now().isBefore(deadline)) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
        if (scriptModel.state.value == ScriptState.running) {
          // 15 秒还没停下来，放弃这次重启，避免点一下就卡死在中间态
          return;
        }
      }
      scriptService.startScript(name);
      clearLog();
    } finally {
      _restarting = false;
    }
  }

  bool _restarting = false;
}
