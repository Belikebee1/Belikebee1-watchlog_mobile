import 'package:flutter/material.dart';

/// Color palette matched to watchlog dashboard (api.watchlog.pl).
class AppColors {
  static const bg = Color(0xFF0F172A);
  static const bgElevated = Color(0xFF1E293B);
  static const bgCard = Color(0xFF334155);
  static const fg = Color(0xFFF1F5F9);
  static const fgMuted = Color(0xFF94A3B8);
  static const accent = Color(0xFF22D3EE);
  static const accentHover = Color(0xFF06B6D4);
  static const green = Color(0xFF34D399);
  static const yellow = Color(0xFFFBBF24);
  static const red = Color(0xFFF87171);
  static const border = Color(0xFF475569);
  static const codeBg = Color(0xFF020617);
}

ThemeData buildTheme() {
  const seed = AppColors.accent;
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
    surface: AppColors.bg,
    primary: AppColors.accent,
    onPrimary: AppColors.bg,
    secondary: AppColors.green,
    error: AppColors.red,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.fg,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.fg,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.bgElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.bg,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.bgElevated,
      contentTextStyle: TextStyle(color: AppColors.fg),
      behavior: SnackBarBehavior.floating,
    ),
    dividerColor: AppColors.border,
  );
}

Color severityColor(String severity) {
  switch (severity) {
    case 'OK':
      return AppColors.green;
    case 'INFO':
      return AppColors.accent;
    case 'WARN':
      return AppColors.yellow;
    case 'CRITICAL':
      return AppColors.red;
    default:
      return AppColors.fgMuted;
  }
}

String severityEmoji(String severity) {
  switch (severity) {
    case 'OK':
      return '✅';
    case 'INFO':
      return 'ℹ️';
    case 'WARN':
      return '⚠️';
    case 'CRITICAL':
      return '🔴';
    default:
      return '?';
  }
}
