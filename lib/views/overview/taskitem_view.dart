part of overview;

class TaskItemView extends StatelessWidget {
  final TaskItemModel model;
  final bool showDivider;
  const TaskItemView(this.model, {super.key, this.showDivider = false});

  @override
  Widget build(BuildContext context) {
    if (model.isAllEmpty()) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.nightlight_round,
                  size: 16, color: Colors.grey.withValues(alpha: 0.28)),
              const SizedBox(width: 7),
              Text(
                '空闲中',
                style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 0.3,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final row = <Widget>[
      _name(context),
      _action(context),
    ]
        .toRow(mainAxisAlignment: MainAxisAlignment.spaceBetween)
        .padding(bottom: 8);
    return showDivider
        ? Column(children: [row, const ThinDivider(indent: 0, endIndent: 0)])
        : row;
  }

  Widget _name(BuildContext context) {
    return <Widget>[
      Text(model.taskName.tr,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(fontSize: 12.5, fontWeight: FontWeight.w500)),
      const SizedBox(height: 2),
      Text(model.nextRun,
          style: TextStyle(
              fontSize: 10.5, color: Colors.grey.withValues(alpha: 0.8)))
    ].toColumn(crossAxisAlignment: CrossAxisAlignment.start);
  }

  /// 次级按钮：浅色底胶囊，hover 变深
  Widget _action(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F4F8),
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.find<NavCtrl>().switchContent(model.taskName),
        hoverColor: const Color(0xFFE6E8F0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Text(
            I18n.task_setting.tr,
            style: const TextStyle(fontSize: 11, color: AppColors.textSub),
          ),
        ),
      ),
    );
  }
}
