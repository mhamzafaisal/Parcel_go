import 'package:flutter/material.dart';

/// Wo rang jo dono mode mein ek jaise rehte hain
/// (cream aur white "hare par likhai" ke liye hain, surface ke liye nahi).
class AppColors {
  static const green = Color(0xFF4F7F36);
  static const cream = Color(0xFFF7F4EC);
  static const white = Color(0xFFFFFFFF);
  static const danger = Color(0xFFC0492F);
  static const shadow = Color(0x14000000);
}

/// Wo rang jo mode ke hisaab se badalte hain
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background; // screen ka background
  final Color surface; // card, nav bar, bottom sheet
  final Color chip; // chhote tags
  final Color ink; // mukhya likhai
  final Color muted; // halki likhai
  final Color line; // lakeerein aur border

  const AppPalette({
    required this.background,
    required this.surface,
    required this.chip,
    required this.ink,
    required this.muted,
    required this.line,
  });

  static const light = AppPalette(
    background: Color(0xFFF7F4EC),
    surface: Color(0xFFFFFFFF),
    chip: Color(0xFFF7F4EC),
    ink: Color(0xFF1E2A1A),
    muted: Color(0xFF6B7566),
    line: Color(0xFFE6E2D6),
  );

  static const dark = AppPalette(
    background: Color(0xFF111611),
    surface: Color(0xFF1B221B),
    chip: Color(0xFF263026),
    ink: Color(0xFFEDF1E6),
    muted: Color(0xFFA0AA9A),
    line: Color(0xFF333D33),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? chip,
    Color? ink,
    Color? muted,
    Color? line,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      chip: chip ?? this.chip,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      line: line ?? this.line,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
    );
  }
}

/// context.surface, context.ink waghera
extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  Color get background => palette.background;
  Color get surface => palette.surface;
  Color get chip => palette.chip;
  Color get ink => palette.ink;
  Color get muted => palette.muted;
  Color get line => palette.line;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

class AppTheme {
  static ThemeData get light => _build(Brightness.light, AppPalette.light);
  static ThemeData get dark => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: brightness,
    ).copyWith(surface: p.surface, onSurface: p.ink);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      dividerColor: p.line,
      extensions: [p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: p.ink,
        centerTitle: false,
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: p.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: p.ink,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: p.muted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
      ),
    );
  }
}
