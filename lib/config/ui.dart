import 'package:flutter/material.dart';

/// 全局视觉规范：颜色、圆角、阴影
/// 风格参考 Vercel / Linear —— 冷灰背景 + 纯白卡片 + 极柔阴影，不使用硬边框
class AppColors {
  AppColors._();

  /// 页面底色，不用纯白
  static const bg = Color(0xFFF3F4F6);

  /// 渐变侧栏的起止色（比底色略深一点点，做出层次）
  static const railTop = Color(0xFFFBFBFD);
  static const railBottom = Color(0xFFF0F1F5);

  /// 卡片
  static const card = Color(0xFFFFFFFF);

  /// 主色（靛紫）
  static const primary = Color(0xFF6366F1);
  static const primarySoft = Color(0xFFEEF0FF);
  static const primaryDim = Color(0xFFB9BBF9);

  /// 文字
  static const textMain = Color(0xFF111827);
  static const textSub = Color(0xFF6B7280);
  static const textFaint = Color(0xFF9CA3AF);

  /// 极淡分隔线
  static const divider = Color(0xFFEFF1F4);

  /// 卡片细边框（gray-200，取代重阴影）
  static const cardBorder = Color(0xFFE5E7EB);

  /// 导航选中：indigo-50 底 + indigo-700 字
  static const navSelectedBg = Color(0xFFEEF2FF);
  static const navSelectedText = Color(0xFF4338CA);

  /// 状态色
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);

  /// 深色模式
  static const darkBg = Color(0xFF17181C);
  static const darkCard = Color(0xFF1F2026);
  static const darkRailTop = Color(0xFF1B1C21);
  static const darkRailBottom = Color(0xFF15161A);
  static const darkDivider = Color(0xFF2A2C33);
}

class AppSpec {
  AppSpec._();

  static const double radiusCard = 14;
  static const double radiusControl = 8;
  static const double gap = 12;

  /// 卡片柔和投影：0 4px 20px rgba(0,0,0,0.05)
  static List<BoxShadow> softShadow(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.22 : 0.03),
        blurRadius: 16,
        offset: const Offset(0, 3),
      ),
    ];
  }

  /// hover 时阴影加深
  static List<BoxShadow> hoverShadow(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.45 : 0.10),
        blurRadius: 36,
        offset: const Offset(0, 12),
      ),
    ];
  }
}

/// 柔和阴影卡片，替代默认 Card（无边框、圆角、可 hover 抬升）
class SoftCard extends StatefulWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.margin,
    this.padding = const EdgeInsets.all(12),
    this.radius = AppSpec.radiusCard,
    this.hoverable = true,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final bool hoverable;
  final Color? color;
  final VoidCallback? onTap;

  @override
  State<SoftCard> createState() => _SoftCardState();
}

class _SoftCardState extends State<SoftCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bg = widget.color ??
        (brightness == Brightness.dark ? AppColors.darkCard : AppColors.card);

    return MouseRegion(
      onEnter: (_) {
        if (widget.hoverable && !_hover) setState(() => _hover = true);
      },
      onExit: (_) {
        if (widget.hoverable && _hover) setState(() => _hover = false);
      },
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        margin: widget.margin,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(
            color: brightness == Brightness.dark
                ? AppColors.darkDivider
                : AppColors.cardBorder,
          ),
          boxShadow: _hover && widget.hoverable
              ? AppSpec.hoverShadow(brightness)
              : AppSpec.softShadow(brightness),
        ),
        child: widget.child,
      ),
    );
  }
}

/// 带发光效果的状态点
class StatusDot extends StatelessWidget {
  const StatusDot({
    super.key,
    required this.color,
    this.size = 8,
    this.glow = true,
  });

  final Color color;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

/// 极简分隔线（用于列表行之间，替代封闭边框）
class ThinDivider extends StatelessWidget {
  const ThinDivider({super.key, this.indent = 12, this.endIndent = 12});

  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      endIndent: endIndent,
      color: dark ? AppColors.darkDivider : AppColors.divider,
    );
  }
}


/// 让任意 widget 能链式变成柔和阴影卡片
extension SoftCardX on Widget {
  Widget softCard({
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    bool hoverable = true,
  }) {
    return SoftCard(
      margin: margin,
      padding: padding,
      hoverable: hoverable,
      child: this,
    );
  }
}
