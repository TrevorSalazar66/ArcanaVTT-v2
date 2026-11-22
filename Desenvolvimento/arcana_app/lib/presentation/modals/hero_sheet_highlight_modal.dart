import 'package:flutter/material.dart';
import '../../../controllers/app_controller.dart';
import '../../../core/constants/svg_icons.dart';
import '../../../core/theme/arcana_colors.dart';
import '../../../domain/entities/arcana_entities.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/heraldic_card.dart';
import 'modal_shell.dart';
import 'universal_report_modal.dart';

class HeroSheetHighlightModal extends StatefulWidget {
  final AppController controller;
  final String? initialCampaignId;

  const HeroSheetHighlightModal({
    super.key,
    required this.controller,
    this.initialCampaignId,
  });

  @override
  State<HeroSheetHighlightModal> createState() => _HeroSheetHighlightModalState();
}

class _HeroSheetHighlightModalState extends State<HeroSheetHighlightModal> {
  String? _selectedCampaignId;
  late TextEditingController _nameCtrl;
  late TextEditingController _classCtrl;
  late TextEditingController _slotsCtrl;
  late TextEditingController _specsCtrl;
  late TextEditingController _powersCtrl;
  late TextEditingController _contactsCtrl;
  late TextEditingController _loreCtrl;
  late TextEditingController _formulaCtrl;

  int _level = 1;
  int _corpo = 2;
  int _mente = 2;
  int _espirito = 2;
  int _hpCur = 20;
  int _hpMax = 20;
  int _animaCur = 10;
  int _animaMax = 10;
  int _exhaustion = 0;
  int _silver = 25;
  int _xp = 0;
  Map<String, String> _equipped = {};
  bool _saving = false;

  static const _paperdollSlots = [
    'Cabeca',
    'Tronco',
    'Costas',
    'Mao 1',
    'Mao 2',
    'Pernas',
    'Pes',
    'Acessorio 1',
    'Acessorio 2',
  ];

  @override
  void initState() {
    super.initState();
    final memberCampaigns = widget.controller.campaigns
        .where((c) => c.userRelation != CampaignSegment.explorar)
        .toList();
    _selectedCampaignId = widget.initialCampaignId ??
        widget.controller.hero?.campaignId ??
        (memberCampaigns.isNotEmpty ? memberCampaigns.first.id : null);

    _nameCtrl = TextEditingController();
    _classCtrl = TextEditingController();
    _slotsCtrl = TextEditingController();
    _specsCtrl = TextEditingController();
    _powersCtrl = TextEditingController();
    _contactsCtrl = TextEditingController();
    _loreCtrl = TextEditingController();
    _formulaCtrl = TextEditingController(text: '3d6');
    _loadForSelectedCampaign();
  }

  void _loadForSelectedCampaign() {
    final existing = _selectedCampaignId != null
        ? widget.controller.characterForCampaign(_selectedCampaignId!)
        : null;
    if (existing != null) {
      _nameCtrl.text = existing.name;
      _classCtrl.text = existing.heroClass;
      _slotsCtrl.text = existing.slots.join(', ');
      _specsCtrl.text = existing.specializations.join(', ');
      _powersCtrl.text = existing.powers.join(', ');
      _contactsCtrl.text = existing.contacts.join(', ');
      _loreCtrl.text = existing.lore;
      _level = existing.level;
      _corpo = existing.corpo;
      _mente = existing.mente;
      _espirito = existing.espirito;
      _hpCur = existing.hpCurrent;
      _hpMax = existing.hpMax;
      _animaCur = existing.animaCurrent;
      _animaMax = existing.animaMax;
      _exhaustion = existing.exhaustion;
      _silver = existing.silverCoins;
      _xp = existing.xpCurrent;
      _equipped = Map<String, String>.from(existing.equippedSlotsMap);
    } else {
      _nameCtrl.text = '';
      _classCtrl.text = 'Aventureiro';
      _slotsCtrl.text = 'Cantil, Tocha';
      _specsCtrl.text = '';
      _powersCtrl.text = '';
      _contactsCtrl.text = '';
      _loreCtrl.text = '';
      _level = 1;
      _corpo = 2;
      _mente = 2;
      _espirito = 2;
      _hpCur = 20;
      _hpMax = 20;
      _animaCur = 10;
      _animaMax = 10;
      _exhaustion = 0;
      _silver = 25;
      _xp = 0;
      _equipped = {};
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _classCtrl.dispose();
    _slotsCtrl.dispose();
    _specsCtrl.dispose();
    _powersCtrl.dispose();
    _contactsCtrl.dispose();
    _loreCtrl.dispose();
    _formulaCtrl.dispose();
    super.dispose();
  }

  String _wealthTierForSilver(int s) {
    if (s >= 1000) return 'Nobreza';
    if (s >= 250) return 'Prospero';
    if (s >= 40) return 'Comum';
    return 'Escasso';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final ctrl = widget.controller;
    final memberCampaigns = ctrl.campaigns
        .where((c) => c.userRelation != CampaignSegment.explorar)
        .toList();

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.sword,
      title: 'Ficha do Heroi',
      subtitle: 'Estritamente 1 ficha por jogador em cada campanha ativa',
      badgeLabel: _selectedCampaignId != null ? 'NV.$_level' : 'BLOQUEADO',
      badgeColor: _selectedCampaignId != null ? p.goldPrimary : p.crimson,
      child: memberCampaigns.isEmpty
          ? HeraldicCard(
              child: Column(
                children: [
                  Icon(Icons.lock_outline, size: 36, color: p.crimson),
                  const SizedBox(height: 10),
                  Text(
                    'Personagens nao podem ser criados fora de uma campanha',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Entre em uma mesa via Quick Join, convite direto ou Explore a Taverna primeiro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedCampaignId,
                  decoration: const InputDecoration(labelText: 'Campanha Vinculada'),
                  items: memberCampaigns
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.title)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedCampaignId = v;
                      _loadForSelectedCampaign();
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome do Heroi'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _classCtrl,
                        decoration: const InputDecoration(labelText: 'Classe / Arquetipo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 105,
                      child: DropdownButtonFormField<int>(
                        initialValue: _level,
                        decoration: const InputDecoration(labelText: 'Nivel'),
                        items: List.generate(20, (i) => i + 1)
                            .map((n) => DropdownMenuItem(value: n, child: Text('Nv.$n')))
                            .toList(),
                        onChanged: (v) => setState(() => _level = v ?? 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Rolagem Universal / Atributos Dinamicos
                HeraldicCard(
                  goldAccent: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atributos & Rolador Universal',
                        style: TextStyle(fontWeight: FontWeight.w700, color: p.goldHighlight),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _statStepper('Corpo', _corpo, (v) => setState(() => _corpo = v)),
                          const SizedBox(width: 8),
                          _statStepper('Mente', _mente, (v) => setState(() => _mente = v)),
                          const SizedBox(width: 8),
                          _statStepper('Espirito', _espirito, (v) => setState(() => _espirito = v)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _formulaCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Formula (ex: 3d6, 2d20kh1, 4d6>=4)',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SecondaryHeraldicButton(
                            label: 'Rolar',
                            svgIcon: ArcanaSvgIcons.dices,
                            onPressed: () async {
                              await ctrl.rollUniversal(
                                _formulaCtrl.text.trim(),
                                label: '${_nameCtrl.text.isEmpty ? "HEROI" : _nameCtrl.text.toUpperCase()} TESTE',
                              );
                              if (mounted) setState(() {});
                            },
                          ),
                        ],
                      ),
                      if (ctrl.lastHeroRoll != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${ctrl.lastHeroRoll!.label}: ${ctrl.lastHeroRoll!.dice} -> ${ctrl.lastHeroRoll!.outcome}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: p.emerald,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Recursos Vitais & Economia Prata
                HeraldicCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recursos & Economia (${_wealthTierForSilver(_silver)})',
                        style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _statStepper('PV', _hpCur, (v) => setState(() => _hpCur = v)),
                          const SizedBox(width: 8),
                          _statStepper('Anima', _animaCur, (v) => setState(() => _animaCur = v)),
                          const SizedBox(width: 8),
                          _statStepper('Exaustao', _exhaustion, (v) => setState(() => _exhaustion = v)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _statStepper('Prata', _silver, (v) => setState(() => _silver = v), step: 10),
                          const SizedBox(width: 8),
                          _statStepper('XP', _xp, (v) => setState(() => _xp = v), step: 50),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Paperdoll 9 Slots Equipaveis
                HeraldicCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Equipamentos (9 Slots Corporais)',
                        style: TextStyle(fontWeight: FontWeight.w700, color: p.goldHighlight),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _paperdollSlots.map((slotName) {
                          final val = _equipped[slotName] ?? 'Vazio';
                          return ActionChip(
                            label: Text('$slotName: $val', style: const TextStyle(fontSize: 11.5)),
                            onPressed: () async {
                              final editCtrl = TextEditingController(
                                text: _equipped[slotName] ?? '',
                              );
                              final res = await showDialog<String>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Slot: $slotName'),
                                  content: TextField(
                                    controller: editCtrl,
                                    decoration: const InputDecoration(
                                      hintText: 'Nome do equipamento...',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, editCtrl.text.trim()),
                                      child: const Text('Equipar'),
                                    ),
                                  ],
                                ),
                              );
                              if (res != null && mounted) {
                                setState(() {
                                  if (res.isEmpty) {
                                    _equipped.remove(slotName);
                                  } else {
                                    _equipped[slotName] = res;
                                  }
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _slotsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mochila Geral (itens separados por virgula, max 24)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _specsCtrl,
                  decoration: const InputDecoration(labelText: 'Especializacoes & Pericias'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _powersCtrl,
                  decoration: const InputDecoration(labelText: 'Poderes, Magias & Talentos'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _contactsCtrl,
                  decoration: const InputDecoration(labelText: 'Contatos / Aliados em Cenario'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _loreCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Historia / Lore Pessoal'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryGoldPillButton(
                        label: _saving ? 'Salvando...' : 'Salvar Ficha na Mesa',
                        svgIcon: ArcanaSvgIcons.check,
                        expand: true,
                        onPressed: _saving
                            ? null
                            : () async {
                                if (_selectedCampaignId == null ||
                                    _nameCtrl.text.trim().length < 2) {
                                  return;
                                }
                                setState(() => _saving = true);
                                final messenger = ScaffoldMessenger.of(context);
                                final cmp = memberCampaigns.firstWhere(
                                  (c) => c.id == _selectedCampaignId,
                                  orElse: () => memberCampaigns.first,
                                );
                                final ok = await ctrl.saveHeroCharacter(
                                  campaignId: _selectedCampaignId!,
                                  systemId: cmp.systemId,
                                  name: _nameCtrl.text,
                                  heroClass: _classCtrl.text,
                                  level: _level,
                                  corpo: _corpo,
                                  mente: _mente,
                                  espirito: _espirito,
                                  hpCurrent: _hpCur,
                                  hpMax: _hpMax,
                                  animaCurrent: _animaCur,
                                  animaMax: _animaMax,
                                  exhaustion: _exhaustion,
                                  slots: _slotsCtrl.text
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList(),
                                  equippedSlotsMap: _equipped,
                                  specializations: _specsCtrl.text
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList(),
                                  powers: _powersCtrl.text
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList(),
                                  contacts: _contactsCtrl.text
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList(),
                                  silverCoins: _silver,
                                  wealthTier: _wealthTierForSilver(_silver),
                                  lore: _loreCtrl.text.trim(),
                                  xpCurrent: _xp,
                                );
                                if (mounted) {
                                  setState(() => _saving = false);
                                  if (ok) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Ficha salva com sucesso na mesa!'),
                                      ),
                                    );
                                  } else {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(ctrl.lastSyncError ?? 'Erro.'),
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SecondaryHeraldicButton(
                      label: 'Denunciar',
                      svgIcon: ArcanaSvgIcons.flag,
                      borderColor: p.crimson,
                      textColor: p.crimson,
                      onPressed: () {
                        final cur = ctrl.characterForCampaign(_selectedCampaignId!);
                        showArcanaModal(context,
                          builder: (_) => UniversalReportModal(
                            controller: ctrl,
                            originType: 'ficha_personagem',
                            originId: cur?.id ?? (_selectedCampaignId ?? 'ficha'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _statStepper(
    String label,
    int value,
    ValueChanged<int> onChanged, {
    int step = 1,
  }) {
    final p = context.arcana;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: p.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: p.subtleBorder),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10.5, color: p.textSecondary)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => onChanged((value - step).clamp(0, 9999)),
                  child: const Icon(Icons.remove, size: 16),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '$value',
                    style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary),
                  ),
                ),
                InkWell(
                  onTap: () => onChanged((value + step).clamp(0, 9999)),
                  child: const Icon(Icons.add, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
