import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/arcana_colors.dart';

/// Renderizador SVG-First oficial do ArcanaVTT.
/// Mantém fidelidade vetorial em qualquer DPI e proíbe emojis.
class SvgIconWidget extends StatelessWidget {
  final String assetPath;
  final double size;
  final Color? color;
  final bool preserveOriginalColors;

  const SvgIconWidget(
    this.assetPath, {
    super.key,
    this.size = 20,
    this.color,
    this.preserveOriginalColors = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.arcana;
    final tint = color ?? palette.goldPrimary;

    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: preserveOriginalColors
          ? null
          : ColorFilter.mode(tint, BlendMode.srcIn),
    );
  }
}

