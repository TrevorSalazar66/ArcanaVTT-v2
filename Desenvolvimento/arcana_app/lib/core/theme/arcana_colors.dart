import 'package:flutter/material.dart';

/// Os 3 Temas Oficiais definidos no Guia Geral de Estética.
enum ArcanaThemeMode {
  escuroHeraldico,
  oled,
  altoContrasteSolar;

  String get labelPtBr {
    switch (this) {
      case ArcanaThemeMode.escuroHeraldico:
        return 'Modo Escuro Heráldico';
      case ArcanaThemeMode.oled:
        return 'Modo OLED (#000000)';
      case ArcanaThemeMode.altoContrasteSolar:
        return 'Alto Contraste Solar';
    }
  }

  String get wireKey {
    switch (this) {
      case ArcanaThemeMode.escuroHeraldico:
        return 'escuro_heraldico';
      case ArcanaThemeMode.oled:
        return 'oled';
      case ArcanaThemeMode.altoContrasteSolar:
        return 'alto_contraste_solar';
    }
  }
}

@immutable
class ArcanaPalette extends ThemeExtension<ArcanaPalette> {
  final Color voidBg;
  final Color obsidianBg;
  final Color surfaceElevated;
  final Color subtleBorder;
  final Color goldPrimary;
  final Color goldBorder;
  final Color goldHighlight;
  final Color textPrimary;
  final Color textSecondary;
  final Color emerald;
  final Color crimson;
  final Color infoBlue;
  final Color bubbleIncoming;
  final Color bubbleOutgoing;
  final Brightness brightness;

  const ArcanaPalette({
    required this.voidBg,
    required this.obsidianBg,
    required this.surfaceElevated,
    required this.subtleBorder,
    required this.goldPrimary,
    required this.goldBorder,
    required this.goldHighlight,
    required this.textPrimary,
    required this.textSecondary,
    required this.emerald,
    required this.crimson,
    required this.infoBlue,
    required this.bubbleIncoming,
    required this.bubbleOutgoing,
    required this.brightness,
  });

  static const escuroHeraldico = ArcanaPalette(
    voidBg: Color(0xFF080811),
    obsidianBg: Color(0xFF131322),
    surfaceElevated: Color(0xFF1C1C32),
    subtleBorder: Color(0xFF2A2A4A),
    goldPrimary: Color(0xFFE5B758),
    goldBorder: Color(0xFFC89D42),
    goldHighlight: Color(0xFFF3CE7A),
    textPrimary: Color(0xFFF4EFE6),
    textSecondary: Color(0xFFA39E93),
    emerald: Color(0xFF10B981),
    crimson: Color(0xFFEF4444),
    infoBlue: Color(0xFF2EC4B6),
    bubbleIncoming: Color(0xFF18182C),
    bubbleOutgoing: Color(0xFF1B2B29),
    brightness: Brightness.dark,
  );

  static const oled = ArcanaPalette(
    voidBg: Color(0xFF000000),
    obsidianBg: Color(0xFF090910),
    surfaceElevated: Color(0xFF12121F),
    subtleBorder: Color(0xFF24243D),
    goldPrimary: Color(0xFFE5B758),
    goldBorder: Color(0xFFC89D42),
    goldHighlight: Color(0xFFF7D88C),
    textPrimary: Color(0xFFF8F4EC),
    textSecondary: Color(0xFF9C978B),
    emerald: Color(0xFF10B981),
    crimson: Color(0xFFEF4444),
    infoBlue: Color(0xFF2EC4B6),
    bubbleIncoming: Color(0xFF11111D),
    bubbleOutgoing: Color(0xFF112622),
    brightness: Brightness.dark,
  );

  static const altoContrasteSolar = ArcanaPalette(
    voidBg: Color(0xFFF7F3E8),
    obsidianBg: Color(0xFFEFE9D8),
    surfaceElevated: Color(0xFFE5DEC9),
    subtleBorder: Color(0xFFC7B894),
    goldPrimary: Color(0xFFB57C14),
    goldBorder: Color(0xFF8C5D08),
    goldHighlight: Color(0xFFD69A28),
    textPrimary: Color(0xFF181510),
    textSecondary: Color(0xFF4F4639),
    emerald: Color(0xFF047857),
    crimson: Color(0xFFB91C1C),
    infoBlue: Color(0xFF0F766E),
    bubbleIncoming: Color(0xFFEAE3D0),
    bubbleOutgoing: Color(0xFFD8EBE7),
    brightness: Brightness.light,
  );

  static ArcanaPalette forMode(ArcanaThemeMode mode) {
    switch (mode) {
      case ArcanaThemeMode.escuroHeraldico:
        return escuroHeraldico;
      case ArcanaThemeMode.oled:
        return oled;
      case ArcanaThemeMode.altoContrasteSolar:
        return altoContrasteSolar;
    }
  }

  @override
  ArcanaPalette copyWith({
    Color? voidBg,
    Color? obsidianBg,
    Color? surfaceElevated,
    Color? subtleBorder,
    Color? goldPrimary,
    Color? goldBorder,
    Color? goldHighlight,
    Color? textPrimary,
    Color? textSecondary,
    Color? emerald,
    Color? crimson,
    Color? infoBlue,
    Color? bubbleIncoming,
    Color? bubbleOutgoing,
    Brightness? brightness,
  }) {
    return ArcanaPalette(
      voidBg: voidBg ?? this.voidBg,
      obsidianBg: obsidianBg ?? this.obsidianBg,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      subtleBorder: subtleBorder ?? this.subtleBorder,
      goldPrimary: goldPrimary ?? this.goldPrimary,
      goldBorder: goldBorder ?? this.goldBorder,
      goldHighlight: goldHighlight ?? this.goldHighlight,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      emerald: emerald ?? this.emerald,
      crimson: crimson ?? this.crimson,
      infoBlue: infoBlue ?? this.infoBlue,
      bubbleIncoming: bubbleIncoming ?? this.bubbleIncoming,
      bubbleOutgoing: bubbleOutgoing ?? this.bubbleOutgoing,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  ArcanaPalette lerp(ThemeExtension<ArcanaPalette>? other, double t) {
    if (other is! ArcanaPalette) return this;
    return ArcanaPalette(
      voidBg: Color.lerp(voidBg, other.voidBg, t)!,
      obsidianBg: Color.lerp(obsidianBg, other.obsidianBg, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      subtleBorder: Color.lerp(subtleBorder, other.subtleBorder, t)!,
      goldPrimary: Color.lerp(goldPrimary, other.goldPrimary, t)!,
      goldBorder: Color.lerp(goldBorder, other.goldBorder, t)!,
      goldHighlight: Color.lerp(goldHighlight, other.goldHighlight, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      emerald: Color.lerp(emerald, other.emerald, t)!,
      crimson: Color.lerp(crimson, other.crimson, t)!,
      infoBlue: Color.lerp(infoBlue, other.infoBlue, t)!,
      bubbleIncoming: Color.lerp(bubbleIncoming, other.bubbleIncoming, t)!,
      bubbleOutgoing: Color.lerp(bubbleOutgoing, other.bubbleOutgoing, t)!,
      brightness: t < 0.5 ? brightness : other.brightness,
    );
  }
}

extension ArcanaThemeContext on BuildContext {
  ArcanaPalette get arcana =>
      Theme.of(this).extension<ArcanaPalette>() ?? ArcanaPalette.escuroHeraldico;
}

