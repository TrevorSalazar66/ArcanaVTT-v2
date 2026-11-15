import 'package:flutter/material.dart';
import '../../core/theme/arcana_colors.dart';
import 'svg_icon_widget.dart';

/// Divisor heráldico com ícone SVG, título em caixa alta espaçada e linha com losango dourado.
class HeraldicSectionDivider extends StatelessWidget {
  final String svgIcon;
  final String title;
  final Widget? trailing;

  const HeraldicSectionDivider({
    super.key,
    required this.svgIcon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SvgIconWidget(svgIcon, size: 18, color: p.goldPrimary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1.2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    p.goldBorder,
                    p.goldBorder.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.785398, // 45 graus para o losango heráldico
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: p.voidBg,
                border: Border.all(color: p.goldBorder, width: 1.2),
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

