part of nav;

/// 自绘二级树：
/// - 一级项左缩进 8，二级项在 24（8 + 16px 固定缩进），箭头/文字/选中底色整体右移
/// - 选中态使用统一主色的淡底 + 主色文字
class SimpleTree extends StatefulWidget {
  const SimpleTree({
    super.key,
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final Map<String, List<String>> data;
  final String selected;
  final void Function(String name) onTap;

  @override
  State<SimpleTree> createState() => _SimpleTreeState();
}

class _SimpleTreeState extends State<SimpleTree> {
  /// 展开的一级项
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    // 默认展开包含当前选中项的一级节点
    for (final entry in widget.data.entries) {
      if (entry.value.contains(widget.selected)) {
        _expanded.add(entry.key);
      }
    }
  }

  @override
  void didUpdateWidget(covariant SimpleTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 选中项变化时，自动展开其父节点（但不要自动收起用户手动展开的）
    for (final entry in widget.data.entries) {
      if (entry.value.contains(widget.selected)) {
        _expanded.add(entry.key);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 6),
      children: [
        for (final entry in widget.data.entries) ...[
          if (entry.value.isEmpty || entry.value.length == 1)
            // 没有子项的组，直接当一级项
            _row(
              context,
              dark: dark,
              name: entry.key,
              depth: 0,
              selected: widget.selected == entry.key,
              onTap: () => widget.onTap(entry.key),
            )
          else ...[
            _row(
              context,
              dark: dark,
              name: entry.key,
              depth: 0,
              selected: false,
              expandable: true,
              expanded: _expanded.contains(entry.key),
              onTap: () => setState(() {
                _expanded.contains(entry.key)
                    ? _expanded.remove(entry.key)
                    : _expanded.add(entry.key);
              }),
            ),
            if (_expanded.contains(entry.key))
              for (final child in entry.value)
                _row(
                  context,
                  dark: dark,
                  name: child,
                  depth: 1,
                  selected: widget.selected == child,
                  onTap: () => widget.onTap(child),
                ),
          ],
        ],
      ],
    );
  }

  Widget _row(
    BuildContext context, {
    required bool dark,
    required String name,
    required int depth,
    required bool selected,
    required VoidCallback onTap,
    bool expandable = false,
    bool expanded = false,
  }) {
    // 一级 8px，二级再固定缩进 16px —— 箭头、文字、选中块一起右移
    final double left = depth == 0 ? 8 : 8 + 16;
    final Color textColor = selected
        ? (dark ? AppColors.primaryDim : AppColors.navSelectedText)
        : (dark ? Colors.white70 : AppColors.textSub);

    return Padding(
      padding: EdgeInsets.only(left: left, right: 8, bottom: 1),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        hoverColor: dark ? const Color(0xFF26272E) : const Color(0xFFF3F4F6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? (dark ? const Color(0xFF2A2B45) : AppColors.navSelectedBg)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (expandable)
                AnimatedRotation(
                  turns: expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 140),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 15,
                      color: expanded
                          ? (dark ? AppColors.primaryDim : AppColors.primary)
                          : AppColors.textFaint),
                )
              else
                const SizedBox(width: 15),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  name.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: depth == 0 ? 12.5 : 12,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
