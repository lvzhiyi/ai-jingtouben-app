import 'package:flutter/material.dart';

/// 共享布局尺寸；颜色和字体通过 Theme.of(context) 读取。
abstract final class AppUi {
  static const pagePadding = 16.0;
  static const cardRadius = 14.0;
  static const fieldRadius = 12.0;

  /// Web 和平板上内容区的最大宽度，避免卡片被拉得过宽。
  static const contentMaxWidth = 760.0;
}

abstract final class AppTheme {
  /// 场记板橙。
  static const seed = Color(0xFFFF8A3D);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(centerTitle: false, scrolledUnderElevation: 0),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppUi.cardRadius)),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUi.fieldRadius),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
