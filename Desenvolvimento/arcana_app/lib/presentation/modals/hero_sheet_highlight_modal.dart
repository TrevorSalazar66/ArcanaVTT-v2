import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/svg_icons.dart';
import '../../core/theme/arcana_colors.dart';
import '../../domain/entities/arcana_entities.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/heraldic_card.dart';
import '../widgets/heraldic_section_divider.dart';
import '../widgets/svg_icon_widget.dart';
import 'modal_shell.dart';

/// Modal de Ficha Rápida e Criação/Edição do Herói vinculada a uma Campanha (AlphaD6 Core: 3d6 e 12 Slots).
class HeroSheetHighlightModal extends StatefulWidget {
  final AppController controller;
  final Campaign? boundCampaign;

  const HeroSheetHighlightModal({
    super.key,
    required this.controller,
    this.boundCampaign,
  });

  @override
  State<HeroSheetHighlightModal> createState() =>
      _HeroSheetHighlightModalState();
}

class _HeroSheetHighlightModalState extends State<HeroSheetHighlightModal> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _classCtrl;
  late final TextEditingController _slotsCtrl;

  int _level = 1;
  int _corpo = 2;
  int _mente = 2;
  int _espirito = 2;
  bool _editing = false;
  bool _saving = false;
  String? _formError;

  HeroCharacter? _resolveTargetHero() {
    final bound = widget.boundCampaign;
    if (bound != null) {
      return widget.controller.characterForCampaign(bound.id);
    }
    return widget.controller.hero;
  }

  @override
  void initState() {
    super.initState();
    final h = _resolveTargetHero();
    _nameCtrl = TextEditingController(text: h?.name ?? '');
    _classCtrl = TextEditingController(text: h?.heroClass ?? '');
    _slotsCtrl = TextEditingController(
      text: h != null ? h.slots.join(', ') : '',
    );
    _level = h?.level ?? 1;
    _corpo = h?.corpo ?? 2;
    _mente = h?.mente ?? 2;
    _espirito = h?.espirito ?? 2;
    _editing = h == null && widget.boundCampaign != null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _classCtrl.dispose();
    _slotsCtrl.dispose();
    super.dispose();
  }

  void _openEditor(HeroCharacter h) {
    setState(() {
      _nameCtrl.text = h.name;
      _classCtrl.text = h.heroClass;
      _slotsCtrl.text = h.slots.join(', ');
      _level = h.level;
      _corpo = h.corpo;
      _mente = h.mente;
      _espirito = h.espirito;
      _formError = null;
      _editing = true;
    });
  }

  Future<void> _saveHero() async {
    final currentHero = _resolveTargetHero();
    final targetCampaignId =
        widget.boundCampaign?.id ?? currentHero?.campaignId ?? '';
    final targetCampaignTitle =
        widget.boundCampaign?.title ?? currentHero?.campaignTitle ?? '';
    if (targetCampaignId.trim().isEmpty) {
      setState(() {
        _formError =
            'Fichas de herói precisam estar vinculadas a uma campanha ativa.';
      });
      return;
    }

    final name = _nameCtrl.text.trim();
    if (name.length < 2) {
      setState(() {
        _formError = 'Informe um nome de herói com pelo menos 2 caracteres.';
      });
      return;
    }
    final heroClass = _classCtrl.text.trim().isEmpty
        ? 'Aventureiro'
        : _classCtrl.text.trim();
    final slots = _slotsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(12)
        .toList();

    setState(() {
      _saving = true;
      _formError = null;
    });

    final ok = await widget.controller.saveHeroCharacter(
      campaignId: targetCampaignId,
      name: name,
      heroClass: heroClass,
      campaignTitle: targetCampaignTitle,
      level: _level,
      corpo: _corpo,
      mente: _mente,
      espirito: _espirito,
      slots: slots,
    );

    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) {
        _editing = false;
      } else {
        _formError = widget.controller.lastSyncError ??
            'Falha ao sincronizar ficha com o Cloudflare D1.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final h = _resolveTargetHero();
        final lastRoll = widget.controller.lastHeroRoll;

        if (h == null && widget.boundCampaign == null) {
          return ArcanaModalScaffold(
            svgIcon: ArcanaSvgIcons.swords,
            title: 'FICHAS DE HERÓI',
            subtitle: 'Regra Oficial de Vínculo com Campanha',
            badgeLabel: 'ALPHAD6',
            badgeColor: p.infoBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HeraldicCard(
                  borderColor: p.infoBlue,
                  child: Text(
                    'Suas fichas de herói só podem ser criadas dentro da aba "Personagens" de uma campanha em que você já seja membro ativo (ou aprovado pelo Mestre).',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryGoldPillButton(
                  label: 'Entendi • Explorar Campanhas',
                  svgIcon: ArcanaSvgIcons.scroll,
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.controller.setTabIndex(1);
                  },
                ),
              ],
            ),
          );
        }

        if (_editing || h == null) {
          final resolvedTitle =
              widget.boundCampaign?.title ?? h?.campaignTitle ?? 'Campanha';
          return ArcanaModalScaffold(
            svgIcon: ArcanaSvgIcons.swords,
            title: h == null ? 'FORJAR FICHA NA MESA' : 'EDITAR FICHA',
            subtitle: '$resolvedTitle • Sistema AlphaD6 Core (3d6 • 12 Slots)',
            badgeLabel: 'ALPHAD6',
            badgeColor: p.goldPrimary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HeraldicCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      SvgIconWidget(
                        ArcanaSvgIcons.scroll,
                        size: 16,
                        color: p.goldPrimary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mesa vinculada: $resolvedTitle',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: p.goldPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Herói',
                    hintText: 'Ex: Kaelen Silvaris',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _classCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Classe / Arquétipo',
                    hintText: 'Ex: Lâmina Arcana',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _stepperCard(
                      context,
                      'Nível',
                      _level,
                      1,
                      20,
                      (v) => setState(() => _level = v),
                      p,
                    ),
                    const SizedBox(width: 8),
                    _stepperCard(
                      context,
                      'Corpo',
                      _corpo,
                      0,
                      6,
                      (v) => setState(() => _corpo = v),
                      p,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _stepperCard(
                      context,
                      'Mente',
                      _mente,
                      0,
                      6,
                      (v) => setState(() => _mente = v),
                      p,
                    ),
                    const SizedBox(width: 8),
                    _stepperCard(
                      context,
                      'Espírito',
                      _espirito,
                      0,
                      6,
                      (v) => setState(() => _espirito = v),
                      p,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _slotsCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Equipamentos / Mochila (separados por vírgula)',
                    hintText: 'Ex: Espada Curta, Tocha, Cantil, Corda 10m',
                  ),
                ),
                if (_formError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _formError!,
                    style: TextStyle(color: p.crimson, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 14),
                PrimaryGoldPillButton(
                  label: _saving
                      ? 'Salvando Ficha na Nuvem...'
                      : 'Salvar Ficha AlphaD6',
                  svgIcon: ArcanaSvgIcons.check,
                  onPressed: _saving ? null : _saveHero,
                ),
                if (h != null) ...[
                  const SizedBox(height: 8),
                  SecondaryHeraldicButton(
                    label: 'Cancelar Edição',
                    expand: true,
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                              _editing = false;
                              _formError = null;
                            }),
                  ),
                ],
              ],
            ),
          );
        }

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
                  _attrCard(context, 'Corpo', h.corpo, p, widget.controller),
                  const SizedBox(width: 8),
                  _attrCard(context, 'Mente', h.mente, p, widget.controller),
                  const SizedBox(width: 8),
                  _attrCard(
                      context, 'Espírito', h.espirito, p, widget.controller),
                ],
              ),
              const SizedBox(height: 12),
              HeraldicCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _barRow('Vitalidade', h.hpCurrent, h.hpMax, p.emerald),
                    const SizedBox(height: 8),
                    _barRow('Reserva de Ânima', h.animaCurrent, h.animaMax,
                        p.infoBlue),
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
                          color:
                              lastRoll.successes > 0 ? p.emerald : p.crimson,
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
              if (h.slots.isEmpty)
                HeraldicCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    'Nenhum equipamento na mochila ainda.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                ...h.slots.map(
                  (slot) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: HeraldicCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child:
                          Text(slot, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              PrimaryGoldPillButton(
                label: 'Executar Teste de Espírito (3d6)',
                svgIcon: ArcanaSvgIcons.dices,
                onPressed: () =>
                    widget.controller.rollHeroAttributeTest('ESPÍRITO'),
              ),
              const SizedBox(height: 8),
              SecondaryHeraldicButton(
                label: 'Editar Ficha de Herói',
                svgIcon: ArcanaSvgIcons.feather,
                borderColor: p.goldBorder,
                expand: true,
                onPressed: () => _openEditor(h),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _stepperCard(
    BuildContext context,
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
    ArcanaPalette p,
  ) {
    return Expanded(
      child: HeraldicCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    '$value',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: p.goldPrimary),
                  ),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Text('−', style: TextStyle(fontSize: 18)),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Text('+', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
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
          value: (max <= 0 ? 0.0 : cur / max).clamp(0.0, 1.0),
          minHeight: 7,
          borderRadius: BorderRadius.circular(99),
          color: barColor,
          backgroundColor: barColor.withValues(alpha: 0.18),
        ),
      ],
    );
  }
}

