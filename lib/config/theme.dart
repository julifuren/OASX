import 'package:flutter/material.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:oasx/config/ui.dart';

/// 用枚举太麻烦了
enum ColorSeed {
  baseColor('M3 Baseline', AppColors.primary),
  indigo('Indigo', Colors.indigo),
  blue('Blue', Colors.blue),
  teal('Teal', Colors.teal),
  green('Green', Colors.green),
  yellow('Yellow', Colors.yellow),
  orange('Orange', Colors.orange),
  deepOrange('Deep Orange', Colors.deepOrange),
  pink('Pink', Colors.pink);

  const ColorSeed(this.label, this.color);
  final String label;
  final Color color;
}

const Map<String, Color> colorSeedMap = {
  'M3 Baseline': AppColors.primary,
  'Indigo': Colors.indigo,
  'Blue': Colors.blue,
  'Teal': Colors.teal,
  'Green': Colors.green,
  'Yellow': Colors.yellow,
  'Orange': Colors.orange,
  'Deep Orange': Colors.deepOrange,
  'Pink': Colors.pink
};

ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    surface: AppColors.card,
    surfaceTint: Colors.transparent,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(),
    bodyMedium: TextStyle(),
    bodySmall: TextStyle(),
    labelLarge: TextStyle(),
    labelMedium: TextStyle(),
    labelSmall: TextStyle(),
    titleLarge: TextStyle(fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontWeight: FontWeight.w500),
  ).apply(fontFamily: 'LatoLato').useSystemChineseFont(Brightness.light),
  scaffoldBackgroundColor: AppColors.bg,
  // 白卡片 + 极柔阴影 + 无边框
  cardTheme: CardTheme(
    color: AppColors.card,
    elevation: 2,
    shadowColor: Colors.black.withValues(alpha: 0.07),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpec.radiusCard),
      side: const BorderSide(color: AppColors.cardBorder),
    ),
    margin: EdgeInsets.zero,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.divider,
    thickness: 1,
    space: 1,
  ),
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: Colors.transparent,
    indicatorColor: AppColors.primarySoft,
    selectedIconTheme: IconThemeData(color: AppColors.primary, size: 22),
    unselectedIconTheme: IconThemeData(color: AppColors.textSub, size: 22),
    selectedLabelTextStyle: TextStyle(
        color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
    unselectedLabelTextStyle:
        TextStyle(color: AppColors.textSub, fontSize: 11),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: AppColors.textSub,
      highlightColor: AppColors.primarySoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpec.radiusControl),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    isDense: true,
    filled: true,
    fillColor: const Color(0xFFF7F8FA),
    hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 12),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpec.radiusControl),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpec.radiusControl),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpec.radiusControl),
      borderSide: const BorderSide(color: AppColors.primaryDim, width: 1),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.textMain,
    contentTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: AppColors.textSub,
    textColor: AppColors.textMain,
  ),
);

ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.primaryDim,
    surface: AppColors.darkCard,
    surfaceTint: Colors.transparent,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(),
    bodyMedium: TextStyle(),
    bodySmall: TextStyle(),
    labelLarge: TextStyle(),
    labelMedium: TextStyle(),
    labelSmall: TextStyle(),
    titleLarge: TextStyle(fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontWeight: FontWeight.w500),
  ).apply(fontFamily: 'LatoLato').useSystemChineseFont(Brightness.dark),
  scaffoldBackgroundColor: AppColors.darkBg,
  cardTheme: CardTheme(
    color: AppColors.darkCard,
    elevation: 0,
    shadowColor: Colors.black.withValues(alpha: 0.30),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpec.radiusCard),
      side: const BorderSide(color: AppColors.darkDivider),
    ),
    margin: EdgeInsets.zero,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.darkDivider,
    thickness: 1,
    space: 1,
  ),
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: Colors.transparent,
    indicatorColor: Color(0xFF2A2B45),
    selectedIconTheme: IconThemeData(color: AppColors.primaryDim, size: 22),
    unselectedIconTheme: IconThemeData(color: AppColors.textFaint, size: 22),
    selectedLabelTextStyle: TextStyle(
        color: AppColors.primaryDim, fontSize: 11, fontWeight: FontWeight.w600),
    unselectedLabelTextStyle:
        TextStyle(color: AppColors.textFaint, fontSize: 11),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: AppColors.textFaint,
      highlightColor: const Color(0xFF2A2B45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpec.radiusControl),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryDim,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    isDense: true,
    filled: true,
    fillColor: const Color(0xFF26272E),
    hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 12),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpec.radiusControl),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpec.radiusControl),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpec.radiusControl),
      borderSide: const BorderSide(color: AppColors.primary, width: 1),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF2E3038),
    contentTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: AppColors.textFaint,
    textColor: Colors.white,
  ),
);
