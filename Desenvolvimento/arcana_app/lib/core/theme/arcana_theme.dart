import 'package:flutter/material.dart';
import 'arcana_colors.dart';

/// Builder oficial de ThemeData aplicando o Tema Escuro Heráldico / OLED / Solar
/// e a escala tipográfica dinâmica de 80% a 150%.
class ArcanaThemeBuilder {
  ArcanaThemeBuilder._();

  static ThemeData build(ArcanaThemeMode mode, double fontScale) {
    final p = ArcanaPalette.forMode(mode);
    final clampedScale = fontScale.clamp(0.8, 1.5);
    final baseTextColor = p.textPrimary;

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      scaffoldBackgroundColor: p.voidBg,
      canvasColor: p.obsidianBg,
      colorScheme: ColorScheme(
        brightness: p.brightness,
        primary: p.goldPrimary,
        onPrimary: const Color(0xFF0A0A12),
        secondary: p.infoBlue,
        onSecondary: const Color(0xFF0A0A12),
        error: p.crimson,
        onError: Colors.white,
        surface: p.obsidianBg,
        onSurface: baseTextColor,
      ),
      extensions: [p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.obsidianBg,
        foregroundColor: p.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontSize: 22 * clampedScale,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: baseTextColor,
        ),
        titleLarge: TextStyle(
          fontSize: 18 * clampedScale,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: baseTextColor,
        ),
        titleMedium: TextStyle(
          fontSize: 15 * clampedScale,
          fontWeight: FontWeight.w600,
          color: baseTextColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14 * clampedScale,
          height: 1.4,
          color: baseTextColor,
        ),
        bodySmall: TextStyle(
          fontSize: 12 * clampedScale,
          height: 1.35,
          color: p.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14 * clampedScale,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceElevated,
        hintStyle: TextStyle(
          color: p.textSecondary,
          fontSize: 14 * clampedScale,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.subtleBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.subtleBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.goldPrimary, width: 1.5),
        ),
      ),
    );
  }
}

