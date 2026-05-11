import 'package:flutter/material.dart';

/// Static color tokens kept for backwards compatibility.
///
/// These resolve to the *dark* palette values regardless of theme. New
/// code should prefer [BuildContext.surfaces] for surface tokens (bg,
/// fg, border) so light mode works. Brand and severity colors stay
/// here — they intentionally don't flip between themes (you don't want
/// "yellow means warning" to invert when the user toggles appearance).
class AppColors {
  // Surface tokens — dark palette. Migrate call sites to
  // `context.surfaces.X` to make them theme-aware.
  static const bg = Color(0xFF0F172A);
  static const bgElevated = Color(0xFF1E293B);
  static const bgCard = Color(0xFF334155);
  static const fg = Color(0xFFF1F5F9);
  static const fgMuted = Color(0xFF94A3B8);
  static const border = Color(0xFF475569);
  static const codeBg = Color(0xFF020617);

  // Brand + severity — stable across themes.
  static const accent = Color(0xFF22D3EE);
  static const accentHover = Color(0xFF06B6D4);
  static const green = Color(0xFF34D399);
  static const yellow = Color(0xFFFBBF24);
  static const red = Color(0xFFF87171);
}

/// Theme-aware surface palette. Registered as a Material 3 ThemeExtension
/// on every ThemeData (dark + light), so it lerps smoothly when the user
/// toggles appearance and the Theme inspector lists every token.
@immutable
class WatchlogSurfaces extends ThemeExtension<WatchlogSurfaces> {
  final Color bg;
  final Color bgElevated;
  final Color bgCard;
  final Color fg;
  final Color fgMuted;
  final Color border;
  final Color codeBg;

  const WatchlogSurfaces({
    required this.bg,
    required this.bgElevated,
    required this.bgCard,
    required this.fg,
    required this.fgMuted,
    required this.border,
    required this.codeBg,
  });

  @override
  WatchlogSurfaces copyWith({
    Color? bg,
    Color? bgElevated,
    Color? bgCard,
    Color? fg,
    Color? fgMuted,
    Color? border,
    Color? codeBg,
  }) =>
      WatchlogSurfaces(
        bg: bg ?? this.bg,
        bgElevated: bgElevated ?? this.bgElevated,
        bgCard: bgCard ?? this.bgCard,
        fg: fg ?? this.fg,
        fgMuted: fgMuted ?? this.fgMuted,
        border: border ?? this.border,
        codeBg: codeBg ?? this.codeBg,
      );

  @override
  WatchlogSurfaces lerp(ThemeExtension<WatchlogSurfaces>? other, double t) {
    if (other is! WatchlogSurfaces) return this;
    return WatchlogSurfaces(
      bg: Color.lerp(bg, other.bg, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      fg: Color.lerp(fg, other.fg, t)!,
      fgMuted: Color.lerp(fgMuted, other.fgMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      codeBg: Color.lerp(codeBg, other.codeBg, t)!,
    );
  }

  static const dark = WatchlogSurfaces(
    bg: Color(0xFF0F172A),
    bgElevated: Color(0xFF1E293B),
    bgCard: Color(0xFF334155),
    fg: Color(0xFFF1F5F9),
    fgMuted: Color(0xFF94A3B8),
    border: Color(0xFF475569),
    codeBg: Color(0xFF020617),
  );

  static const light = WatchlogSurfaces(
    bg: Color(0xFFF8FAFC),
    bgElevated: Color(0xFFFFFFFF),
    bgCard: Color(0xFFE2E8F0),
    fg: Color(0xFF0F172A),
    fgMuted: Color(0xFF64748B),
    border: Color(0xFFCBD5E1),
    codeBg: Color(0xFFF1F5F9),
  );
}

extension WatchlogContextColors on BuildContext {
  WatchlogSurfaces get surfaces =>
      Theme.of(this).extension<WatchlogSurfaces>() ?? WatchlogSurfaces.dark;
}

ThemeData buildDarkTheme() => _buildTheme(
      brightness: Brightness.dark,
      surfaces: WatchlogSurfaces.dark,
    );

ThemeData buildLightTheme() => _buildTheme(
      brightness: Brightness.light,
      surfaces: WatchlogSurfaces.light,
    );

/// Backwards-compat: existing code calls `buildTheme()` from main.dart.
/// Returns the dark variant so existing builds keep their look.
ThemeData buildTheme() => buildDarkTheme();

ThemeData _buildTheme({
  required Brightness brightness,
  required WatchlogSurfaces surfaces,
}) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: brightness,
    surface: surfaces.bg,
    primary: AppColors.accent,
    onPrimary: isDark ? surfaces.bg : Colors.white,
    secondary: AppColors.green,
    error: AppColors.red,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: surfaces.bg,
    extensions: [surfaces],
    // Consistent Material 3 shared-axis transitions on every platform.
    // (Default Cupertino slide on iOS would visually mismatch our
    // dark-elevation surfaces.) Reduced-motion users automatically
    // get linear no-op transitions via Flutter's MediaQuery handling.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surfaces.bg,
      foregroundColor: surfaces.fg,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: surfaces.fg,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaces.bgElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: surfaces.border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaces.bgElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: surfaces.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: surfaces.border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: isDark ? surfaces.bg : Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaces.bgElevated,
      contentTextStyle: TextStyle(color: surfaces.fg),
      behavior: SnackBarBehavior.floating,
    ),
    dividerColor: surfaces.border,
    dialogTheme: DialogThemeData(
      backgroundColor: surfaces.bgElevated,
    ),
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
