import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/svg_icons.dart';
import '../../core/theme/arcana_colors.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/heraldic_card.dart';
import '../widgets/heraldic_section_divider.dart';
import 'modal_shell.dart';

/// Modal de Ficha Rápida do Herói em Destaque (AlphaD6 Core: 3d6 e 12 Slots).
class HeroSheetHighlightModal extends StatelessWidget {
  final AppController controller;

  const HeroSheetHighlightModal({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final h = controller.hero;
        final lastRoll = controller.lastHeroRoll;

        return ArcanaModalScaffold(
          svgIcon: ArcanaSvgIcons.swords,
          title: h.name.toUpperCase(),
          subtitle: '${h.heroClass} • Nível ${h.level} • ${h.campaignTitle}',
          badgeLabel: 'ALPHAD6',
          badgeColor: p.goldPrimary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _attrCard(context, 'Corpo', h.corpo, p, controller),
                  const SizedBox(width: 8),
                  _attrCard(context, 'Mente', h.mente, p, controller),
                  const SizedBox(width: 8),
                  _attrCard(context, 'Espírito', h.espirito, p, controller),
                ],
              ),
              const SizedBox(height: 12),
              HeraldicCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _barRow('Vitalidade', h.hpCurrent, h.hpMax, p.emerald),
                    const SizedBox(height: 8),
                    _barRow('Reserva de Ânima', h.animaCurrent, h.animaMax, p.infoBlue),
                    const SizedBox(height: 8),
                    Text(
                      'Exaustão Atual: ${h.exhaustion} nível • Peso em Mochila: ${h.slots.length}/12 Slots',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (lastRoll != null) ...[
                const SizedBox(height: 12),
                HeraldicCard(
                  goldAccent: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lastRoll.label,
                        style: TextStyle(
                          color: p.goldPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dados: [${lastRoll.dice.join(', ')}] -> ${lastRoll.outcome}',
                        style: TextStyle(
                          color: lastRoll.successes > 0 ? p.emerald : p.crimson,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const HeraldicSectionDivider(
                svgIcon: ArcanaSvgIcons.shield,
                title: 'INVENTÁRIO (12 SLOTS)',
              ),
              ...h.slots.map(
                (slot) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: HeraldicCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(slot, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              PrimaryGoldPillButton(
                label: 'Executar Teste de Espírito (3d6)',
                svgIcon: ArcanaSvgIcons.dices,
                onPressed: () => controller.rollHeroAttributeTest('ESPÍRITO'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _attrCard(
    BuildContext context,
    String name,
    int value,
    ArcanaPalette p,
    AppController ctrl,
  ) {
    return Expanded(
      child: HeraldicCard(
        goldAccent: true,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        onTap: () => ctrl.rollHeroAttributeTest(name),
        child: Column(
          children: [
            Text(name.toUpperCase(), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              '+$value',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: p.goldPrimary,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              'Toque 3d6',
              style: TextStyle(fontSize: 10, color: p.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barRow(String label, int cur, int max, Color barColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('$cur / $max', style: TextStyle(fontSize: 12, color: barColor)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: (cur / max).clamp(0.0, 1.0),
          minHeight: 7,
          borderRadius: BorderRadius.circular(99),
          color: barColor,
          backgroundColor: barColor.withValues(alpha: 0.18),
        ),
      ],
    );
  }
}

