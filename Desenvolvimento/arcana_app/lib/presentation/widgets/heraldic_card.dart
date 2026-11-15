import 'package:flutter/material.dart';
import '../../core/theme/arcana_colors.dart';

/// Card base Dark Fantasy Heráldico com borda sutil ou dourada.
class HeraldicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool goldAccent;
  final Color? borderColor;
  final Color? backgroundColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const HeraldicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.goldAccent = false,
    this.borderColor,
    this.backgroundColor,
    this.borderRadius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final effectiveBorder =
        borderColor ?? (goldAccent ? p.goldBorder : p.subtleBorder);
    final effectiveBg = backgroundColor ?? p.obsidianBg;

    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorder,
          width: goldAccent ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return container;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: container,
      ),
    );
  }
}

