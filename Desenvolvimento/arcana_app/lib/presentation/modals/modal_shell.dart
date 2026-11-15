import 'package:flutter/material.dart';
import '../../core/constants/svg_icons.dart';
import '../../core/theme/arcana_colors.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/svg_icon_widget.dart';

/// Moldura padrão mobile-first para abertura confortável de qualquer Modal Primário.
Future<T?> showArcanaModal<T>(
  BuildContext context, {
  required Widget Function(BuildContext ctx) builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: builder(ctx),
    ),
  );
}

class ArcanaModalScaffold extends StatelessWidget {
  final String svgIcon;
  final String title;
  final String subtitle;
  final String? badgeLabel;
  final Color? badgeColor;
  final Widget child;

  const ArcanaModalScaffold({
    super.key,
    required this.svgIcon,
    required this.title,
    required this.subtitle,
    this.badgeLabel,
    this.badgeColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: p.voidBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: p.goldBorder.withValues(alpha: 0.7)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: p.subtleBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: p.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.goldBorder),
                  ),
                  alignment: Alignment.center,
                  child: SvgIconWidget(svgIcon, size: 20, color: p.goldPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: p.goldPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          if (badgeLabel != null) ...[
                            const SizedBox(width: 8),
                            HeraldicChipPill(
                              label: badgeLabel!,
                              color: badgeColor ?? p.emerald,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: SvgIconWidget(
                    ArcanaSvgIcons.close,
                    size: 20,
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: p.goldBorder.withValues(alpha: 0.3), height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

