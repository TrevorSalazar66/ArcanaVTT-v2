import 'package:flutter/material.dart';
import '../../core/security/rbac_guard.dart';
import '../../core/theme/arcana_colors.dart';
import 'svg_icon_widget.dart';

/// Botão primário pill dourado metálico (CTA principal).
class PrimaryGoldPillButton extends StatelessWidget {
  final String label;
  final String? svgIcon;
  final VoidCallback? onPressed;
  final bool expand;

  const PrimaryGoldPillButton({
    super.key,
    required this.label,
    this.svgIcon,
    required this.onPressed,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final button = InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onPressed,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: onPressed != null
              ? LinearGradient(
                  colors: [p.goldHighlight, p.goldPrimary, p.goldBorder],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: onPressed == null ? p.subtleBorder : null,
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: p.goldPrimary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (svgIcon != null) ...[
              SvgIconWidget(
                svgIcon!,
                size: 18,
                color: const Color(0xFF0A0A12),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF0A0A12),
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}

/// Botão secundário heráldico com fundo elevado e borda sutil ou dourada.
class SecondaryHeraldicButton extends StatelessWidget {
  final String label;
  final String? svgIcon;
  final VoidCallback? onPressed;
  final Color? borderColor;
  final Color? textColor;
  final bool expand;

  const SecondaryHeraldicButton({
    super.key,
    required this.label,
    this.svgIcon,
    required this.onPressed,
    this.borderColor,
    this.textColor,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final effectiveText = textColor ?? p.textPrimary;
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: p.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor ?? p.subtleBorder),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (svgIcon != null) ...[
                SvgIconWidget(svgIcon!, size: 17, color: effectiveText),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: effectiveText,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Pill compacta de status ou tag.
class HeraldicChipPill extends StatelessWidget {
  final String label;
  final Color? color;
  final String? svgIcon;

  const HeraldicChipPill({
    super.key,
    required this.label,
    this.color,
    this.svgIcon,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final accent = color ?? p.goldPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (svgIcon != null) ...[
            SvgIconWidget(svgIcon!, size: 12, color: accent),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge oficial de cargo Zero-Trust (MESTRE, ADMIN, JOGADOR).
class RoleBadgeWidget extends StatelessWidget {
  final UserRole role;

  const RoleBadgeWidget({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    Color badgeColor;
    switch (role) {
      case UserRole.superadmin:
      case UserRole.admin:
        badgeColor = p.crimson;
      case UserRole.mestre:
        badgeColor = p.goldPrimary;
      case UserRole.assistenteMestre:
        badgeColor = p.infoBlue;
      case UserRole.jogador:
        badgeColor = p.emerald;
    }
    return HeraldicChipPill(label: role.badgeLabel, color: badgeColor);
  }
}

/// Barra segmentada heráldica de até 4 opções sem overflow em celulares estreitos.
class HeraldicSegmentBar extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const HeraldicSegmentBar({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.obsidianBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.subtleBorder),
      ),
      child: Row(
        children: List.generate(segments.length, (idx) {
          final active = idx == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                decoration: BoxDecoration(
                  color: active ? p.surfaceElevated : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active ? p.goldBorder : Colors.transparent,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  segments[idx],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? p.goldPrimary : p.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

