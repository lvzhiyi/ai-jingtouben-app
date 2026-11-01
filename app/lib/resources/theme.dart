import 'package:flutter/material.dart';

/// 页面与组件共享的尺寸。
abstract final class AppUi {
  static const pagePadding = 24.0;
  static const cardRadius = 28.0;
  static const fieldRadius = 20.0;
  static const contentMaxWidth = 760.0;
}

abstract final class AppTheme {
  static const seed = Color(0xFFB74364);
  static const pink = Color(0xFFFF8EAB);
  static const ink = Color(0xFF242326);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness).copyWith(
      surface: dark ? const Color(0xFF201C20) : const Color(0xFFFFFCF8),
      onSurface: dark ? const Color(0xFFF8EEF1) : ink,
      surfaceContainerLow: dark ? const Color(0xFF2C252B) : Colors.white,
      surfaceContainerHighest: dark ? const Color(0xFF382E35) : const Color(0xFFF8F3F1),
      primaryContainer: dark ? const Color(0xFF603448) : const Color(0xFFFFE0E8),
      onPrimaryContainer: dark ? const Color(0xFFFFDEE8) : const Color(0xFF763247),
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.65),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.55),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppUi.cardRadius)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: dark ? const Color(0xFFF6E9ED) : ink,
          foregroundColor: dark ? ink : Colors.white,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: dark ? const Color(0xFFF6E9ED) : ink,
        foregroundColor: dark ? ink : Colors.white,
        shape: const StadiumBorder(),
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUi.fieldRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUi.fieldRadius),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
