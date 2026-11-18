import 'dart:math';

import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:styled_widget/styled_widget.dart';
import 'log_mixin.dart';

class LogWidget extends StatefulWidget {
  final LogMixin controller;
  final String title;
  final bool? enableCopy;
  final bool? enableAutoScroll;
  final bool? enableClear;
  final bool? enableCollapse;
  final Widget? topPanelBottomChild;

  const LogWidget({
    super.key,
    required this.controller,
    required this.title,
    this.enableCopy,
    this.enableAutoScroll,
    this.enableClear,
    this.enableCollapse,
    this.topPanelBottomChild,
  });

  @override
  State<StatefulWidget> createState() => _LogWidgetState();
}

class _LogWidgetState extends State<LogWidget> {
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController ??= ScrollController(
        initialScrollOffset: widget.controller.savedScrollOffsetVal);
    // 位置调整
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.controller.autoScroll.value) {
        // 自动滚动模式：强制滚动到底部
        _scrollLogs(force: true, scrollOffset: -1);
      } else if (widget.controller.savedScrollOffsetVal > 0) {
        // 非自动滚动模式：恢复到保存的位置
        _scrollLogs(
            force: true, scrollOffset: widget.controller.savedScrollOffsetVal);
      }
    });
    widget.controller.scrollLogs = _scrollLogs;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopLogPanel(
          title: widget.title,
          controller: widget.controller,
          enableCopy: widget.enableCopy,
          enableAutoScroll: widget.enableAutoScroll,
          enableClear: widget.enableClear,
          enableCollapse: widget.enableCollapse,
          bottomChild: widget.topPanelBottomChild,
        ),
        Obx(() => widget.controller.collapseLog.value
            ? const SizedBox.shrink()
            : LogContent(
                controller: widget.controller,
                scrollController: _scrollController!,
                onUserScroll: _handleUserScroll,
              ).expanded()),
      ],
    );
  }

  @override
  void deactivate() {
    if (_scrollController != null && _scrollController!.hasClients) {
      widget.controller.saveScrollOffset(_scrollController!.offset);
    }
    super.deactivate();
  }

  @override
  void dispose() {
    if (_scrollController != null && _scrollController!.hasClients) {
      widget.controller.saveScrollOffset(_scrollController!.offset);
    }
    _scrollController?.dispose();
    _scrollController = null;
    super.dispose();
  }

  void _scrollLogs({isJump = false, force = false, scrollOffset = -1}) {
    if (_scrollController == null || !_scrollController!.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController == null || !_scrollController!.hasClients) return;
      // 强制滚动或自动滚动才允许滚动
      if (!force && !widget.controller.autoScroll.value) return;
      final double targetPos = scrollOffset == -1
          ? _scrollController!.position.maxScrollExtent
          : scrollOffset;
      if (isJump) {
        _scrollController!.jumpTo(targetPos);
        return;
      }
      final double currentPos = _scrollController!.offset;
      final double distance = (targetPos - currentPos).abs();
      // 使用非线性函数计算动画时间
      // 1000px 约 300ms,10000px 约 1000ms
      int animateMs = (sqrt(distance) * 10).toInt();
      const int minAnimateMs = 100; // 最快速度
      const int maxAnimateMs = 1000; // 最慢速度
      // 限制范围
      animateMs = animateMs.clamp(minAnimateMs, maxAnimateMs);
      // 滚动
      _scrollController!
          .animateTo(targetPos,
              duration: Duration(milliseconds: animateMs),
              curve: Curves.easeOut)
          .whenComplete(() {
        if (_scrollController == null || !_scrollController!.hasClients) return;
        final latestExtent = _scrollController!.position.maxScrollExtent;
        // 矫正滚动位置(最底部或自动滚动且最新位置不同,跳转到新的最底部)
        if ((scrollOffset == -1 || widget.controller.autoScroll.value) &&
            latestExtent > targetPos) {
          _scrollController!.jumpTo(latestExtent);
        }
      });
    });
  }

  void _handleUserScroll() {
    if (_scrollController == null || !_scrollController!.hasClients) return;
    final maxExtent = _scrollController!.position.maxScrollExtent;
    final currentOffset = _scrollController!.offset;

    // 判断是否在底部（容差80像素）
    final isAtBottom = currentOffset >= (maxExtent - 80);

    // 更新自动滚动状态
    if (isAtBottom && !widget.controller.autoScroll.value) {
      // 用户滚动到底部，开启自动滚动
      widget.controller.autoScroll.value = true;
    } else if (!isAtBottom && widget.controller.autoScroll.value) {
      // 用户向上滚动超过80像素，关闭自动滚动
      widget.controller.autoScroll.value = false;
    }
  }
}

/// 日志顶部操作栏
class TopLogPanel extends StatelessWidget {
  final LogMixin controller;
  final String title;
  final bool? enableCopy;
  final bool? enableAutoScroll;
  final bool? enableClear;
  final bool? enableCollapse;
  final Widget? bottomChild;

  const TopLogPanel({
    super.key,
    required this.controller,
    required this.title,
    this.enableCopy,
    this.enableAutoScroll,
    this.enableClear,
    this.enableCollapse,
    this.bottomChild,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部按钮控制面板
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(title,
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              if (enableAutoScroll ?? true) _autoScrollButton(),
              if (enableCopy ?? true) _copyButton(),
              if (enableClear ?? true) _deleteButton(),
              if (enableCollapse ?? true) _collapseButton(),
            ],
          ).padding(horizontal: 12).constrained(height: 44),
          // 搜索 + 级别筛选 + 暂停 + 导出
          _LogFilterBar(controller: controller),
          // 底部
          if (bottomChild != null) ...[
            const Divider(height: 1),
            bottomChild!,
          ],
        ],
      ),
    );
  }

  Widget _copyButton() {
    return _compactIconButton(
      icon: Icons.content_copy_rounded,
      onPressed: () => controller.copyLogs(),
      tooltip: '复制全部日志',
    );
  }

  /// 统一的紧凑图标按钮：32x32 命中区，图标居中，避免与搜索框不对齐
  Widget _compactIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? color,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        alignment: Alignment.center,
        visualDensity: VisualDensity.compact,
        splashRadius: 16,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        iconSize: 18,
        onPressed: onPressed,
        icon: Icon(icon, color: color),
      ),
    );
  }

  Widget _autoScrollButton() {
    return Obx(() => _compactIconButton(
          icon: controller.autoScroll.value
              ? Icons.flash_on_rounded
              : Icons.flash_off_rounded,
          color: controller.autoScroll.value
              ? Get.context!.theme.colorScheme.primary
              : null,
          onPressed: controller.toggleAutoScroll,
          tooltip: controller.autoScroll.value ? '关闭自动滚动' : '开启自动滚动',
        ));
  }

  Widget _deleteButton() {
    return _compactIconButton(
      icon: Icons.delete_outline_rounded,
      onPressed: () => controller.clearLog(),
      tooltip: '清空日志',
    );
  }

  Widget _collapseButton() {
    return Obx(() => _compactIconButton(
          icon: controller.collapseLog.value
              ? Icons.expand_more_rounded
              : Icons.expand_less_rounded,
          onPressed: () => controller.toggleCollapse(),
          tooltip: controller.collapseLog.value ? '展开日志' : '收起日志',
        ));
  }
}

/// 日志筛选栏：搜索关键字、按级别过滤、暂停、导出
class _LogFilterBar extends StatefulWidget {
  final LogMixin controller;

  const _LogFilterBar({required this.controller});

  @override
  State<_LogFilterBar> createState() => _LogFilterBarState();
}

class _LogFilterBarState extends State<_LogFilterBar> {
  late final TextEditingController _text =
      TextEditingController(text: widget.controller.searchText.value);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String _label(LogLevelFilter level) => switch (level) {
        LogLevelFilter.all => '全部',
        LogLevelFilter.info => 'INFO',
        LogLevelFilter.warning => 'WARNING',
        LogLevelFilter.error => 'ERROR',
      };

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final dividerColor = Theme.of(context).dividerColor;

    Widget levelMenu() {
      return Obx(() {
        final level = controller.levelFilter.value;
        final counts = controller.levelCounts;
        final active = level != LogLevelFilter.all;
        return PopupMenuButton<LogLevelFilter>(
          tooltip: '按级别筛选',
          onSelected: controller.setLevelFilter,
          itemBuilder: (_) => [
            for (final item in [
              (LogLevelFilter.all, '全部', Icons.list_alt, Colors.grey),
              (LogLevelFilter.info, 'INFO', Icons.info_outline, Colors.blueGrey),
              (LogLevelFilter.warning, 'WARNING', Icons.warning_amber_rounded,
                  Colors.orange),
              (LogLevelFilter.error, 'ERROR', Icons.error_outline, Colors.red),
            ])
              PopupMenuItem<LogLevelFilter>(
                value: item.$1,
                child: Row(
                  children: [
                    Icon(item.$3, size: 16, color: item.$4),
                    const SizedBox(width: 6),
                    Text(item.$2, style: const TextStyle(fontSize: 12)),
                    const Spacer(),
                    Text('${counts[item.$1] ?? 0}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
          ],
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: active && level == LogLevelFilter.error
                      ? Colors.red
                      : dividerColor),
              color: active ? Colors.orange.withValues(alpha: 0.12) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_alt_outlined,
                    size: 15,
                    color: level == LogLevelFilter.error ? Colors.red : null),
                const SizedBox(width: 3),
                Text(_label(level), style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        );
      });
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 32,
              child: TextField(
                controller: _text,
                onChanged: controller.setSearchText,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '搜索日志关键字',
                  hintStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 15),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 26, minHeight: 26),
                  suffixIcon: Obx(() => controller.searchText.value.isEmpty
                      ? const SizedBox.shrink()
                      : InkWell(
                          onTap: () {
                            _text.clear();
                            controller.setSearchText('');
                          },
                          child: const Icon(Icons.close, size: 13),
                        )),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 22, minHeight: 22),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          levelMenu(),
          // 暂停：冻结界面滚动，方便盯住当前几行
          Obx(() => SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  tooltip: controller.paused.value ? '继续刷新' : '暂停刷新',
                  padding: EdgeInsets.zero,
                  alignment: Alignment.center,
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: controller.togglePause,
                  icon: Icon(
                    controller.paused.value
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    color: controller.paused.value ? Colors.orange : null,
                  ),
                ),
              )),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              tooltip: '导出当前筛选结果',
              padding: EdgeInsets.zero,
              alignment: Alignment.center,
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: controller.exportLogs,
              icon: const Icon(Icons.download_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

/// 日志内容区
class LogContent extends StatelessWidget {
  final LogMixin controller;
  final ScrollController scrollController;
  final Function() onUserScroll;

  const LogContent({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.onUserScroll,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          onUserScroll();
          return false;
        },
        child: Obx(() {
          final lines = controller.filteredLogs;
          if (lines.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    controller.logs.isEmpty
                        ? Icons.subtitles_off_outlined
                        : Icons.search_off_rounded,
                    size: 42,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    controller.logs.isEmpty ? '暂无日志' : '当前筛选条件下没有匹配的日志',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.withValues(alpha: 0.75)),
                  ),
                  if (controller.logs.isEmpty) ...[
                    const SizedBox(height: 4),
                    Text('启动脚本后这里会实时滚动输出',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.withValues(alpha: 0.55))),
                  ],
                ],
              ),
            );
          }
          return ListView.builder(
            controller: scrollController,
            itemCount: lines.length,
            itemBuilder: (context, index) {
              final line = lines[index];
              final upper = line.toUpperCase();
              final isError =
                  upper.contains('ERROR') || upper.contains('CRITICAL');
              final isWarning = upper.contains('WARNING');
              return Container(
                color: isError
                    ? Colors.red.withValues(alpha: 0.10)
                    : isWarning
                        ? Colors.orange.withValues(alpha: 0.08)
                        : null,
                padding:
                    const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                child: EasyRichText(
                  line,
                  patternList: _buildPatterns(),
                  selectable: true,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  defaultStyle: _selectStyle(context),
                ),
              );
            },
          ).paddingAll(10);
        }),
      ),
    ).constrained(width: double.infinity, height: double.infinity);
  }

  List<EasyRichTextPattern> _buildPatterns() {
    final keyword = controller.searchText.value.trim();
    return [
      // 搜索命中高亮（放在最前面，优先级最高）
      if (keyword.isNotEmpty)
        EasyRichTextPattern(
          targetString: RegExp(RegExp.escape(keyword), caseSensitive: false),
          style: const TextStyle(
            backgroundColor: Color(0xFFffe082),
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      const EasyRichTextPattern(
        targetString: 'INFO',
        style: TextStyle(
          color: Color.fromARGB(255, 55, 109, 136),
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        suffixInlineSpan: TextSpan(
          style: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
          text: '      ',
        ),
      ),
      const EasyRichTextPattern(
        targetString: 'WARNING',
        style: TextStyle(
          color: Colors.yellow,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      const EasyRichTextPattern(
        targetString: 'ERROR',
        style: TextStyle(
          color: Colors.red,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        suffixInlineSpan: TextSpan(
          style: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
          text: '    ',
        ),
      ),
      const EasyRichTextPattern(
        targetString: 'CRITICAL',
        style: TextStyle(
          color: Colors.red,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        suffixInlineSpan: TextSpan(text: '   '),
      ),
      const EasyRichTextPattern(
        targetString: r'(\d{2}:\d{2}:\d{2}\.\d{3})',
        style: TextStyle(
          color: Colors.cyan,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      const EasyRichTextPattern(
        targetString: r'[\{\[\(\)\]\}]',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const EasyRichTextPattern(
          targetString: 'True', style: TextStyle(color: Colors.lightGreen)),
      const EasyRichTextPattern(
          targetString: 'False', style: TextStyle(color: Colors.red)),
      const EasyRichTextPattern(
          targetString: 'None', style: TextStyle(color: Colors.purple)),
      const EasyRichTextPattern(
        targetString: r'(══*══)|(──*──)',
        style: TextStyle(color: Colors.lightGreen),
      )
    ];
  }

  TextStyle _selectStyle(BuildContext context) {
    final base = context.mediaQuery.orientation == Orientation.portrait
        ? Theme.of(context).textTheme.bodySmall!
        : Theme.of(context).textTheme.titleSmall!;
    // 日志用等宽字体，列对齐更好读
    return base.copyWith(
      fontFamily: 'Consolas',
      fontFamilyFallback: const ['Menlo', 'JetBrains Mono', 'Courier New'],
      fontSize: 12,
      height: 1.55,
    );
  }
}
