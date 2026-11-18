import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/config/ui.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/views/nav/view_nav.dart';

/// 内容区顶部标题栏：左标题 + 副标题，右侧当前脚本状态卡
class PageHeader extends StatelessWidget {
  const PageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GetX<NavCtrl>(builder: (nav) {
      final script = nav.selectedScript.value;
      final menu = nav.selectedMenu.value;
      final isHome = script == 'Home';

      String stateText = '未连接';
      Color stateColor = AppColors.textFaint;
      if (!isHome) {
        try {
          final state =
              Get.find<ScriptService>().scriptModelMap[script]?.state.value;
          switch (state) {
            case ScriptState.running:
              stateText = '运行中';
              stateColor = AppColors.success;
            case ScriptState.warning:
              stateText = '异常';
              stateColor = AppColors.warning;
            case ScriptState.updating:
              stateText = '更新中';
              stateColor = AppColors.primary;
            case ScriptState.inactive:
              stateText = '已停止';
              stateColor = AppColors.textFaint;
            case null:
              stateText = '未连接';
              stateColor = AppColors.textFaint;
          }
        } catch (_) {}
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isHome ? '主页'.tr : menu.tr,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: dark ? Colors.white : AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isHome
                        ? '查看 OAS 项目文档与工具'
                        : '$script · ${_menuHint(menu)}',
                    style: TextStyle(
                        fontSize: 11.5, color: AppColors.textFaint),
                  ),
                ],
              ),
            ),
            if (!isHome)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: dark
                          ? AppColors.darkDivider
                          : AppColors.cardBorder),
                  boxShadow: AppSpec.softShadow(
                      dark ? Brightness.dark : Brightness.light),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusDot(color: stateColor, size: 7),
                    const SizedBox(width: 7),
                    Text(
                      script,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: dark ? Colors.white : AppColors.textMain,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      stateText,
                      style: TextStyle(fontSize: 11, color: stateColor),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  String _menuHint(String menu) {
    switch (menu) {
      case 'Overview':
        return '任务调度与实时日志';
      case 'Tasks':
        return '配置要执行的日常任务';
      default:
        return '参数配置';
    }
  }
}
