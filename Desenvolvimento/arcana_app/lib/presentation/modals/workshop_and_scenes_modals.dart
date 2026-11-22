import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../controllers/app_controller.dart';
import '../../../core/constants/svg_icons.dart';
import '../../../core/theme/arcana_colors.dart';
import '../../../domain/entities/arcana_entities.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/heraldic_card.dart';
import '../widgets/svg_icon_widget.dart';
import 'modal_shell.dart';

// =============================================================================
// 1. OFICINA DO MESTRE — MODULO 1: GESTAO DE CENAS (LIMITE 18 + NO-CODE BUILDER)
// =============================================================================

class OficinaCenasModuleModal extends StatefulWidget {
  final AppController controller;
  final Campaign campaign;

  const OficinaCenasModuleModal({
    super.key,
    required this.controller,
    required this.campaign,
  });

  @override
  State<OficinaCenasModuleModal> createState() => _OficinaCenasModuleModalState();
}

class _OficinaCenasModuleModalState extends State<OficinaCenasModuleModal> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  SceneModelType _modelType = SceneModelType.grid2d;
  bool _isActive = true;
  bool _loading = true;

  // Construtor No-Code [QUANDO] -> [SE] -> [ENTAO] + Capturar Alvo
  String _triggerType = 'tile_step';
  String _conditionType = 'always';
  String _effectType = 'show_toast';
  String _capturedTargetCoord = '3,3';
  final _effectParamCtrl = TextEditingController(text: 'Voce pisou numa runa arcana!');

  @override
  void initState() {
    super.initState();
    widget.controller.fetchCampaignScenes(widget.campaign.id).whenComplete(() {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _effectParamCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final ctrl = widget.controller;
    final scenes = ctrl.campaignScenesMap[widget.campaign.id] ?? const [];

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.map,
      title: 'Oficina: Cenas & Gatilhos (${scenes.length}/18)',
      subtitle: '6 Modelos Interativos + Construtor No-Code [QUANDO]->[SE]->[ENTAO]',
      badgeLabel: '${scenes.length}/18',
      badgeColor: scenes.length >= 18 ? p.crimson : p.emerald,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final s in scenes) ...[
                  HeraldicCard(
                    goldAccent: s.isActive,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            HeraldicChipPill(
                              label: s.isActive ? 'ATIVA (VISIVEL)' : 'RASCUNHO',
                              color: s.isActive ? p.emerald : p.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                s.modelType.labelPtBr,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: p.goldPrimary),
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await ctrl.deleteCampaignScene(widget.campaign.id, s.id);
                                if (mounted) setState(() {});
                              },
                              icon: SvgIconWidget(ArcanaSvgIcons.trash, size: 16, color: p.crimson),
                            ),
                          ],
                        ),
                        Text(
                          s.name,
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                          ),
                        ),
                        Text(
                          '${s.rulesData.length} regra(s) No-Code · Max ${s.maxPlayers} jogadores',
                          style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryHeraldicButton(
                                label: 'Testar Cena',
                                svgIcon: ArcanaSvgIcons.dices,
                                onPressed: () => showArcanaModal(context,
                                  builder: (_) => InteractiveSceneStageModal(
                                    controller: ctrl,
                                    campaign: widget.campaign,
                                    scene: s,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SecondaryHeraldicButton(
                              label: s.isActive ? 'Ocultar' : 'Ativar',
                              onPressed: () async {
                                await ctrl.upsertCampaignScene(
                                  id: s.id,
                                  campaignId: widget.campaign.id,
                                  name: s.name,
                                  description: s.description,
                                  modelType: s.modelType,
                                  isActive: !s.isActive,
                                  maxPlayers: s.maxPlayers,
                                  modelData: s.modelData,
                                  rulesData: s.rulesData,
                                  stateData: s.stateData,
                                );
                                if (mounted) setState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 10),
                HeraldicCard(
                  goldAccent: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Forjar Nova Cena (${scenes.length}/18)',
                        style: TextStyle(
                          fontFamily: 'Cinzel',
                          fontWeight: FontWeight.w700,
                          color: p.goldHighlight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Nome da Cena'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(labelText: 'Descricao Ambiental'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<SceneModelType>(
                        initialValue: _modelType,
                        decoration: const InputDecoration(labelText: 'Modelo Interativo (1 a 6)'),
                        items: SceneModelType.values
                            .map((m) => DropdownMenuItem(value: m, child: Text(m.labelPtBr)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _modelType = v);
                        },
                      ),
                      SwitchListTile(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        title: const Text('Liberar visibilidade imediata aos Jogadores'),
                      ),
                      Divider(color: p.subtleBorder),
                      Text(
                        'Construtor No-Code: [QUANDO] -> [SE] -> [ENTAO]',
                        style: TextStyle(fontWeight: FontWeight.w700, color: p.goldPrimary),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _triggerType,
                        decoration: const InputDecoration(labelText: '[QUANDO] Evento Gatilho'),
                        items: const [
                          DropdownMenuItem(value: 'tile_step', child: Text('Pisar em Celula (Grid 2D)')),
                          DropdownMenuItem(value: 'token_click', child: Text('Interagir com Token/Alavanca')),
                          DropdownMenuItem(value: 'password_solved', child: Text('Decifrar Senha/Cofre')),
                          DropdownMenuItem(value: 'dialog_choice', child: Text('Escolher Opcao em Dialogo')),
                          DropdownMenuItem(value: 'turn_start', child: Text('Inicio de Turno JRPG')),
                          DropdownMenuItem(value: 'terminal_cmd', child: Text('Comando no Terminal CRT')),
                        ],
                        onChanged: (v) => setState(() => _triggerType = v ?? 'tile_step'),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Alvo Capturado: ($_capturedTargetCoord)',
                              style: TextStyle(fontSize: 12, color: p.emerald),
                            ),
                          ),
                          SecondaryHeraldicButton(
                            label: 'Capturar Alvo',
                            svgIcon: ArcanaSvgIcons.map,
                            onPressed: () async {
                              final picked = await _openTargetCaptureDialog(context);
                              if (picked != null && mounted) {
                                setState(() => _capturedTargetCoord = picked);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _conditionType,
                        decoration: const InputDecoration(labelText: '[SE] Condicao'),
                        items: const [
                          DropdownMenuItem(value: 'always', child: Text('Sempre Verdadeiro')),
                          DropdownMenuItem(value: 'has_item', child: Text('Possuir Item na Mochila')),
                          DropdownMenuItem(value: 'attribute_gte', child: Text('Atributo >= 2')),
                          DropdownMenuItem(value: 'faction_gte', child: Text('Reputacao de Faccao >= 10')),
                        ],
                        onChanged: (v) => setState(() => _conditionType = v ?? 'always'),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _effectType,
                        decoration: const InputDecoration(labelText: '[ENTAO] Efeito Autoritativo'),
                        items: const [
                          DropdownMenuItem(value: 'show_toast', child: Text('Exibir Alerta Narrativo')),
                          DropdownMenuItem(value: 'log_diary', child: Text('Gravar no Diario da Campanha')),
                          DropdownMenuItem(value: 'award_item', child: Text('Conceder Reliquia/Item na Ficha')),
                          DropdownMenuItem(value: 'apply_damage', child: Text('Causar Dano de Anima (-2)')),
                          DropdownMenuItem(value: 'heal_anima', child: Text('Restaurar Anima (+2)')),
                        ],
                        onChanged: (v) => setState(() => _effectType = v ?? 'show_toast'),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _effectParamCtrl,
                        decoration: const InputDecoration(labelText: 'Mensagem / Item / Parametro'),
                      ),
                      const SizedBox(height: 12),
                      PrimaryGoldPillButton(
                        label: 'Salvar Cena na Campanha',
                        svgIcon: ArcanaSvgIcons.check,
                        expand: true,
                        onPressed: scenes.length >= 18
                            ? null
                            : () async {
                                if (_nameCtrl.text.trim().length < 2) return;
                                final messenger = ScaffoldMessenger.of(context);
                                final created = await ctrl.upsertCampaignScene(
                                  campaignId: widget.campaign.id,
                                  name: _nameCtrl.text,
                                  description: _descCtrl.text,
                                  modelType: _modelType,
                                  isActive: _isActive,
                                  modelData: {
                                    'captured_target': _capturedTargetCoord,
                                    'grid_size': 7,
                                    'code': 'ARC4',
                                    'digits': 4,
                                  },
                                  rulesData: [
                                    {
                                      'trigger': {
                                        'type': _triggerType,
                                        'coord': _capturedTargetCoord,
                                      },
                                      'conditions': [
                                        if (_conditionType != 'always')
                                          {'type': _conditionType, 'value': 2, 'item_name': 'Chave'},
                                      ],
                                      'effects': [
                                        {
                                          'type': _effectType,
                                          'params': {
                                            'message': _effectParamCtrl.text.trim(),
                                            'text': _effectParamCtrl.text.trim(),
                                            'item_name': _effectParamCtrl.text.trim(),
                                            'amount': 2,
                                          },
                                        },
                                      ],
                                    },
                                  ],
                                );
                                if (mounted) {
                                  if (created != null) {
                                    _nameCtrl.clear();
                                    _descCtrl.clear();
                                    setState(() {});
                                  } else {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(ctrl.lastSyncError ?? 'Erro ao salvar.'),
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<String?> _openTargetCaptureDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Capturar Coordenada do Tabuleiro (7x7)'),
        content: SizedBox(
          width: 260,
          height: 260,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
            ),
            itemCount: 49,
            itemBuilder: (_, idx) {
              final x = idx % 7;
              final y = idx ~/ 7;
              return InkWell(
                onTap: () => Navigator.pop(ctx, '$x,$y'),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: '$x,$y' == _capturedTargetCoord
                        ? context.arcana.goldPrimary
                        : context.arcana.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('$x,$y', style: const TextStyle(fontSize: 9)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 2. OFICINA DO MESTRE — MODULO 2: COMPENDIO DELTA DA CAMPANHA
// =============================================================================

class OficinaCompendioModuleModal extends StatelessWidget {
  final AppController controller;
  final Campaign campaign;

  const OficinaCompendioModuleModal({
    super.key,
    required this.controller,
    required this.campaign,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final items = controller.compendiumItems
        .where((i) => i.campaignId == campaign.id || i.systemId == campaign.systemId)
        .toList();

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.scroll,
      title: 'Oficina: Compendio Delta da Mesa',
      subtitle: 'Itens, Equipamentos, Seres, Poderes e Pistas com Blocos RoleGate',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Itens ativos disponiveis para esta mesa (${items.length}):',
            style: TextStyle(fontWeight: FontWeight.w700, color: p.goldHighlight),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            HeraldicCard(
              child: Text(
                'Nenhum item especifico nesta campanha ainda. Voce pode forjar homebrews diretamente na aba Sistemas -> Compendio.',
                style: TextStyle(fontSize: 12.5, color: p.textSecondary),
              ),
            )
          else
            for (final it in items) ...[
              HeraldicCard(
                borderColor: it.isAllHidden ? p.crimson : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        HeraldicChipPill(label: it.category.labelPtBr, color: p.infoBlue),
                        if (it.isAllHidden) ...[
                          const SizedBox(width: 6),
                          HeraldicChipPill(label: 'SEGREDO GM', color: p.crimson),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(it.name,
                        style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
                    Text(it.description,
                        style: TextStyle(fontSize: 12, color: p.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

// =============================================================================
// 3. OFICINA DO MESTRE — MODULO 3: MUNDO, OVERWORLD 25 MAPAS, RELOGIO & FACCOES
// =============================================================================

class OficinaMundoModuleModal extends StatefulWidget {
  final AppController controller;
  final Campaign campaign;

  const OficinaMundoModuleModal({
    super.key,
    required this.controller,
    required this.campaign,
  });

  @override
  State<OficinaMundoModuleModal> createState() => _OficinaMundoModuleModalState();
}

class _OficinaMundoModuleModalState extends State<OficinaMundoModuleModal> {
  final _mapNameCtrl = TextEditingController();
  final _factionNameCtrl = TextEditingController();
  int _selectedMapIdx = 0;

  @override
  void dispose() {
    _mapNameCtrl.dispose();
    _factionNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final ctrl = widget.controller;
    final cmp = ctrl.campaigns.firstWhere(
      (c) => c.id == widget.campaign.id,
      orElse: () => widget.campaign,
    );
    final clock = cmp.worldClock;

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.clock,
      title: 'Oficina: Mundo, Overworld & Relogio',
      subtitle: 'Ate 25 Mapas Globais · Calendario Procedural · Faccoes (-100 a +100)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Relogio & Calendario Procedural
          HeraldicCard(
            goldAccent: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Relogio Procedural (${clock.season})',
                      style: TextStyle(fontWeight: FontWeight.w700, color: p.goldHighlight),
                    ),
                    HeraldicChipPill(
                      label: clock.isDaylight ? 'DIA / LUZ' : 'NOITE / SOMBRA',
                      color: clock.isDaylight ? p.goldPrimary : p.infoBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Ano ${clock.year} · ${clock.monthName} · Dia ${clock.day} — ${clock.hour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final h in [1, 4, 8, 24])
                      SecondaryHeraldicButton(
                        label: '+${h}h',
                        onPressed: () async {
                          final next = clock.advanceHours(h);
                          await ctrl.updateCampaignSettings(
                            campaignId: cmp.id,
                            statePatch: {'world_clock': next.toJson()},
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Overworld Maps (limite 25)
          HeraldicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overworld Hex Atlas (${cmp.worldMaps.length}/25 Mapas)',
                  style: TextStyle(fontWeight: FontWeight.w700, color: p.goldHighlight),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _mapNameCtrl,
                        decoration: const InputDecoration(hintText: 'Nome do Mapa / Regiao'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PrimaryGoldPillButton(
                      label: 'Criar Mapa',
                      onPressed: cmp.worldMaps.length >= 25
                          ? null
                          : () async {
                              if (_mapNameCtrl.text.trim().length < 2) return;
                              final nextMaps = [
                                ...cmp.worldMaps.map((m) => m.toJson()),
                                WorldMapEntry(
                                  id: 'wmap_${DateTime.now().millisecondsSinceEpoch}',
                                  name: _mapNameCtrl.text.trim(),
                                  pins: const [
                                    {'q': 2, 'r': 2, 'title': 'Cidade Inicial'},
                                  ],
                                ).toJson(),
                              ];
                              _mapNameCtrl.clear();
                              await ctrl.updateCampaignSettings(
                                campaignId: cmp.id,
                                statePatch: {'world_maps': nextMaps},
                              );
                              if (mounted) setState(() {});
                            },
                    ),
                  ],
                ),
                if (cmp.worldMaps.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (var i = 0; i < cmp.worldMaps.length; i++)
                        ChoiceChip(
                          label: Text(cmp.worldMaps[i].name),
                          selected: _selectedMapIdx == i,
                          onSelected: (_) => setState(() => _selectedMapIdx = i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildHexGridPreview(
                    p,
                    cmp.worldMaps[_selectedMapIdx.clamp(0, cmp.worldMaps.length - 1)],
                    (q, r) async {
                      final activeMap =
                          cmp.worldMaps[_selectedMapIdx.clamp(0, cmp.worldMaps.length - 1)];
                      final nextPins = [
                        ...activeMap.pins,
                        {'q': q, 'r': r, 'title': 'Marco ($q,$r)'},
                      ];
                      final updatedMaps = [
                        for (var i = 0; i < cmp.worldMaps.length; i++)
                          i == _selectedMapIdx
                              ? WorldMapEntry(
                                  id: activeMap.id,
                                  name: activeMap.name,
                                  pins: nextPins,
                                ).toJson()
                              : cmp.worldMaps[i].toJson(),
                      ];
                      await ctrl.updateCampaignSettings(
                        campaignId: cmp.id,
                        statePatch: {'world_maps': updatedMaps},
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Faccoes (-100 a +100)
          HeraldicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Matriz de Faccoes (-100 a +100)',
                  style: TextStyle(fontWeight: FontWeight.w700, color: p.goldHighlight),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _factionNameCtrl,
                        decoration: const InputDecoration(hintText: 'Nome da Faccao / Reino'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SecondaryHeraldicButton(
                      label: 'Adicionar',
                      onPressed: () async {
                        if (_factionNameCtrl.text.trim().length < 2) return;
                        final next = [
                          ...cmp.factions.map((f) => f.toJson()),
                          FactionEntry(
                            id: 'fac_${DateTime.now().millisecondsSinceEpoch}',
                            name: _factionNameCtrl.text.trim(),
                            reputation: 0,
                          ).toJson(),
                        ];
                        _factionNameCtrl.clear();
                        await ctrl.updateCampaignSettings(
                          campaignId: cmp.id,
                          statePatch: {'factions': next},
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
                for (final f in cmp.factions) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(f.name, style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
                      Text(
                        '${f.reputation > 0 ? "+" : ""}${f.reputation}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: f.reputation >= 20
                              ? p.emerald
                              : f.reputation <= -20
                                  ? p.crimson
                                  : p.goldPrimary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: f.reputation.toDouble(),
                    min: -100,
                    max: 100,
                    divisions: 40,
                    onChanged: (val) async {
                      final next = cmp.factions
                          .map((item) => item.id == f.id
                              ? FactionEntry(
                                  id: item.id,
                                  name: item.name,
                                  reputation: val.round(),
                                ).toJson()
                              : item.toJson())
                          .toList();
                      await ctrl.updateCampaignSettings(
                        campaignId: cmp.id,
                        statePatch: {'factions': next},
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHexGridPreview(
    ArcanaPalette p,
    WorldMapEntry map,
    void Function(int q, int r) onTapCell,
  ) {
    return SizedBox(
      height: 180,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: 24,
        itemBuilder: (_, idx) {
          final q = idx % 6;
          final r = idx ~/ 6;
          final hasPin = map.pins.any((pin) => pin['q'] == q && pin['r'] == r);
          return InkWell(
            onTap: () => onTapCell(q, r),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hasPin ? p.goldPrimary.withValues(alpha: 0.25) : p.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: hasPin ? p.goldPrimary : p.subtleBorder),
              ),
              child: Text(
                hasPin ? 'PIN' : '$q,$r',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: hasPin ? FontWeight.w700 : FontWeight.w400,
                  color: hasPin ? p.goldHighlight : p.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// 4. PALCO JOGAVEL DOS 6 MODELOS DE CENA INTERATIVA
// =============================================================================

class InteractiveSceneStageModal extends StatefulWidget {
  final AppController controller;
  final Campaign campaign;
  final CampaignScene scene;

  const InteractiveSceneStageModal({
    super.key,
    required this.controller,
    required this.campaign,
    required this.scene,
  });

  @override
  State<InteractiveSceneStageModal> createState() =>
      _InteractiveSceneStageModalState();
}

class _InteractiveSceneStageModalState extends State<InteractiveSceneStageModal> {
  // 1) Grid 2D State
  int _heroX = 1;
  int _heroY = 1;
  final int _npcX = 5;
  final int _npcY = 4;
  final Set<String> _walls = {'3,1', '3,2', '2,4'};
  bool _enableFog = true;

  // 2) Mahjong & Minas State
  late List<Map<String, dynamic>> _mahjongTiles;
  int? _firstPickIdx;
  bool _firstPairRevealed = false;
  int _minesLogCount = 0;

  // 3) Senha & Cofre State
  final _vaultCtrl = TextEditingController();
  String _vaultCharset = 'Numeros'; // Numeros | Letras | Runas
  int _vaultHints = 0;
  String? _vaultFeedback;

  // 4) Dialogos State
  int _dialogNode = 0;

  // 5) Combate JRPG State
  int _enemyHp = 30;
  int _heroPa = 3;
  final List<String> _combatLog = ['Turno 1: Sentinelas bloqueiam a passagem!'];

  // 6) Terminal CRT State
  final _termCtrl = TextEditingController();
  String _termFont = 'Padrao'; // Padrao | Runico | Hex | Binario
  final List<String> _termLines = ['ARCANA_OS v2.0 ONLINE. Digite HELP ou ACCESS_CORE.'];

  String? _lastToast;

  @override
  void initState() {
    super.initState();
    _initMahjong();
  }

  void _initMahjong() {
    const syms = ['SOL', 'LUA', 'SOL', 'LUA', 'BOMBA', 'CHAVE', 'CHAVE', 'BOMBA', 'RUNA', 'RUNA', 'ESCUDO', 'ESCUDO'];
    _mahjongTiles = List.generate(12, (i) {
      return {
        'id': i,
        'sym': syms[i],
        'revealed': i == 0, // Primeira peca visivel ate primeiro par encontrado
        'matched': false,
        'isBomb': syms[i] == 'BOMBA',
      };
    });
  }

  @override
  void dispose() {
    _vaultCtrl.dispose();
    _termCtrl.dispose();
    super.dispose();
  }

  Future<void> _fireTrigger(String triggerType, [Map<String, dynamic> params = const {}]) async {
    final res = await widget.controller.triggerSceneAction(
      campaignId: widget.campaign.id,
      sceneId: widget.scene.id,
      triggerType: triggerType,
      params: params,
    );
    if (!mounted) return;
    final toasts = (res?['toasts'] as List<dynamic>?) ?? const [];
    if (toasts.isNotEmpty) {
      setState(() => _lastToast = toasts.first.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final isSpectator = widget.controller.ghostSpectatorActive &&
        widget.campaign.userRelation == CampaignSegment.explorar;

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.dices,
      title: widget.scene.name,
      subtitle: widget.scene.modelType.labelPtBr,
      badgeLabel: isSpectator ? 'ESPECTADOR FANTASMA' : 'AO VIVO',
      badgeColor: isSpectator ? p.crimson : p.emerald,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_lastToast != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: p.emerald.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.emerald),
              ),
              child: Text(
                'Gatilho Autoritativo: $_lastToast',
                style: TextStyle(fontWeight: FontWeight.w700, color: p.emerald),
              ),
            ),
            const SizedBox(height: 10),
          ],
          switch (widget.scene.modelType) {
            SceneModelType.grid2d => _buildGrid2D(p, isSpectator),
            SceneModelType.mahjong => _buildMahjong(p),
            SceneModelType.password => _buildPasswordVault(p),
            SceneModelType.dialogue => _buildDialogueTree(p),
            SceneModelType.jrpgCombat => _buildJrpgCombat(p),
            SceneModelType.terminal => _buildCrtTerminal(p),
          },
        ],
      ),
    );
  }

  Widget _buildGrid2D(ArcanaPalette p, bool isSpectator) {
    return Column(
      children: [
        SwitchListTile(
          value: _enableFog,
          onChanged: (v) => setState(() => _enableFog = v),
          title: const Text('Fog of War / Raycasting Dinamico'),
        ),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.goldBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LayoutBuilder(
                builder: (ctx, box) {
                  return GestureDetector(
                    onTapUp: isSpectator
                        ? null
                        : (details) {
                            final cellW = box.maxWidth / 7;
                            final tx = (details.localPosition.dx ~/ cellW).clamp(0, 6);
                            final ty = (details.localPosition.dy ~/ cellW).clamp(0, 6);
                            _moveHeroTo(tx, ty);
                          },
                    child: CustomPaint(
                      painter: _Grid2DPainter(
                        heroX: _heroX,
                        heroY: _heroY,
                        npcX: _npcX,
                        npcY: _npcY,
                        walls: _walls,
                        fogEnabled: _enableFog,
                        palette: p,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!isSpectator)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _moveHeroTo(_heroX - 1, _heroY),
                icon: const Icon(Icons.arrow_back),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: () => _moveHeroTo(_heroX, _heroY - 1),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  Text('($_heroX, $_heroY)', style: TextStyle(color: p.goldPrimary)),
                  IconButton(
                    onPressed: () => _moveHeroTo(_heroX, _heroY + 1),
                    icon: const Icon(Icons.arrow_downward),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _moveHeroTo(_heroX + 1, _heroY),
                icon: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
      ],
    );
  }

  void _moveHeroTo(int nx, int ny) {
    final boundedX = nx.clamp(0, 6);
    final boundedY = ny.clamp(0, 6);
    if (_walls.contains('$boundedX,$boundedY')) return;
    if (boundedX == _npcX && boundedY == _npcY) {
      _fireTrigger('token_click', {'npc': 'guardiao'});
      return;
    }
    setState(() {
      _heroX = boundedX;
      _heroY = boundedY;
    });
    if ('$_heroX,$_heroY' ==
        (widget.scene.modelData['captured_target']?.toString() ?? '3,3')) {
      _fireTrigger('tile_step', {'x': _heroX, 'y': _heroY});
    }
  }

  Widget _buildMahjong(ArcanaPalette p) {
    return Column(
      children: [
        Text(
          'Combine pares iguais. Cuidado com as Bombas Ocultas! Bombas detonadas: $_minesLogCount',
          style: TextStyle(fontSize: 12, color: p.textSecondary),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _mahjongTiles.length,
          itemBuilder: (ctx, i) {
            final t = _mahjongTiles[i];
            final shown = (t['matched'] as bool) ||
                (t['revealed'] as bool) ||
                _firstPickIdx == i;
            final neighborBombs = _adjacentBombs(i);
            return InkWell(
              onTap: (t['matched'] as bool) ? null : () => _tapMahjongTile(i),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (t['matched'] as bool)
                      ? p.emerald.withValues(alpha: 0.2)
                      : (t['isBomb'] as bool && shown)
                          ? p.crimson.withValues(alpha: 0.25)
                          : p.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: shown ? p.goldHighlight : p.subtleBorder,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      shown ? t['sym'].toString() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: shown ? p.textPrimary : p.goldPrimary,
                      ),
                    ),
                    Text(
                      'M:$neighborBombs',
                      style: TextStyle(fontSize: 9, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  int _adjacentBombs(int idx) {
    final row = idx ~/ 4;
    final col = idx % 4;
    var count = 0;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = row + dr;
        final nc = col + dc;
        if (nr >= 0 && nr < 3 && nc >= 0 && nc < 4) {
          final nIdx = nr * 4 + nc;
          if (_mahjongTiles[nIdx]['isBomb'] == true) count++;
        }
      }
    }
    return count;
  }

  void _tapMahjongTile(int idx) {
    final tile = _mahjongTiles[idx];
    if (tile['isBomb'] == true) {
      setState(() {
        tile['revealed'] = true;
        _minesLogCount += 1;
      });
      _fireTrigger('apply_damage', {'bomb': idx});
      return;
    }
    if (_firstPickIdx == null) {
      setState(() => _firstPickIdx = idx);
      return;
    }
    if (_firstPickIdx == idx) return;

    final first = _mahjongTiles[_firstPickIdx!];
    if (first['sym'] == tile['sym']) {
      setState(() {
        first['matched'] = true;
        tile['matched'] = true;
        if (!_firstPairRevealed) {
          _mahjongTiles[0]['revealed'] = false; // Oculta inicial apos primeiro par!
          _firstPairRevealed = true;
        }
        _firstPickIdx = null;
      });
    } else {
      setState(() => _firstPickIdx = null);
    }
  }

  Widget _buildPasswordVault(ArcanaPalette p) {
    final expected = (widget.scene.modelData['code']?.toString() ?? 'ARC4').toUpperCase();
    final attempt = _vaultCtrl.text.trim().toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          children: ['Numeros', 'Letras', 'Runas'].map((t) {
            return ChoiceChip(
              label: Text(t),
              selected: _vaultCharset == t,
              onSelected: (_) => setState(() => _vaultCharset = t),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(expected.length.clamp(1, 50), (i) {
            final ch = i < attempt.length ? attempt[i] : '_';
            final exact = i < attempt.length && attempt[i] == expected[i];
            final inWord = !exact && i < attempt.length && expected.contains(attempt[i]);
            final slotColor = exact
                ? p.emerald
                : inWord
                    ? p.goldPrimary
                    : p.crimson;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 42,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: attempt.isEmpty ? p.subtleBorder : slotColor,
                  width: 2,
                ),
              ),
              child: Text(
                ch,
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _vaultCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Digite a Combinacao (${expected.length} slots · Modo $_vaultCharset)',
          ),
        ),
        if (_vaultHints > 0) ...[
          const SizedBox(height: 8),
          HeraldicCard(
            child: Text(
              _vaultHints == 1
                  ? 'Pista Nv.1: Comeca com "${expected[0]}"'
                  : _vaultHints == 2
                      ? 'Pista Nv.2: Contem os simbolos ${expected.split('').reversed.join('-')}'
                      : 'Pista Nv.3 (Revelacao): A combinacao mestra e $expected',
              style: TextStyle(color: p.goldHighlight, fontSize: 12.5),
            ),
          ),
        ],
        if (_vaultFeedback != null) ...[
          const SizedBox(height: 6),
          Text(_vaultFeedback!, style: TextStyle(color: p.emerald, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PrimaryGoldPillButton(
                label: 'Testar Cofre',
                svgIcon: ArcanaSvgIcons.key,
                onPressed: () {
                  if (attempt == expected) {
                    setState(() => _vaultFeedback = 'Cofre Destravado!');
                    _fireTrigger('password_solved', {'code': attempt});
                  } else {
                    setState(() => _vaultFeedback = 'Combinacao Incorreta. Verifique cores das bordas.');
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            SecondaryHeraldicButton(
              label: 'Pista ($_vaultHints/3)',
              onPressed: () => setState(() => _vaultHints = (_vaultHints + 1).clamp(1, 3)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDialogueTree(ArcanaPalette p) {
    final nodes = [
      (
        speaker: 'Guardiao da Porta de Bronze',
        text: 'Somente portadores do selo ou viajantes sabios atravessam estas muralhas.',
        choices: [('Apresentar Salvo-Conduto', 1), ('Tentar Persuasao', 2)],
      ),
      (
        speaker: 'Guardiao (Respeitoso)',
        text: 'As correntes cedem diante da Ordem. Bem-vindos ao santuario interno.',
        choices: [('Avancar ao Interior', 0)],
      ),
      (
        speaker: 'Guardiao (Desconfiado)',
        text: 'Palavras vazias nao abrem portoes antigos. Provoque seu valor!',
        choices: [('Voltar', 0)],
      ),
    ];
    final cur = nodes[_dialogNode.clamp(0, nodes.length - 1)];

    return HeraldicCard(
      goldAccent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(cur.speaker,
              style: TextStyle(
                  fontFamily: 'Cinzel', fontWeight: FontWeight.w700, color: p.goldHighlight)),
          const SizedBox(height: 8),
          Text(cur.text, style: TextStyle(fontSize: 13.5, color: p.textPrimary)),
          const SizedBox(height: 14),
          for (final c in cur.choices) ...[
            SecondaryHeraldicButton(
              label: c.$1,
              expand: true,
              onPressed: () {
                setState(() => _dialogNode = c.$2);
                _fireTrigger('dialog_choice', {'choice': c.$1});
              },
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildJrpgCombat(ArcanaPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeraldicCard(
          borderColor: p.crimson,
          child: Row(
            children: [
              SvgIconWidget(ArcanaSvgIcons.skull, size: 28, color: p.crimson),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sentinela Espectral',
                        style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
                    Text('PV Inimigo: $_enemyHp/30 · PA do Heroi: $_heroPa/3',
                        style: TextStyle(fontSize: 12, color: p.goldHighlight)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PrimaryGoldPillButton(
                label: 'Atacar (1d8+2)',
                svgIcon: ArcanaSvgIcons.sword,
                onPressed: _enemyHp <= 0
                    ? null
                    : () async {
                        final roll = await widget.controller
                            .rollUniversal('1d8+2', label: 'GOLPE JRPG');
                        final dmg = roll?.total ?? 4;
                        if (mounted) {
                          setState(() {
                            _enemyHp = (_enemyHp - dmg).clamp(0, 30);
                            _heroPa = (_heroPa - 1).clamp(0, 3);
                            _combatLog.insert(0, 'Heroi causou $dmg de dano! (Resta $_enemyHp PV)');
                            if (_heroPa == 0 && _enemyHp > 0) {
                              _heroPa = 3;
                              _combatLog.insert(0, 'IA Inimiga contra-ataca! Novo Turno.');
                            }
                          });
                        }
                      },
              ),
            ),
            const SizedBox(width: 8),
            SecondaryHeraldicButton(
              label: 'Proximo Turno',
              onPressed: () {
                setState(() {
                  _heroPa = 3;
                  _combatLog.insert(0, 'Turno avancado!');
                });
                _fireTrigger('turn_start');
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final line in _combatLog.take(4))
          Text('• $line', style: TextStyle(fontSize: 12, color: p.textSecondary)),
      ],
    );
  }

  Widget _buildCrtTerminal(ArcanaPalette p) {
    final fontStyle = _termFont == 'Hex'
        ? const TextStyle(fontFamily: 'monospace', color: Color(0xFF4ADE80), fontSize: 12)
        : const TextStyle(color: Color(0xFF4ADE80), fontSize: 12.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          children: ['Padrao', 'Runico', 'Hex', 'Binario'].map((f) {
            return ChoiceChip(
              label: Text(f),
              selected: _termFont == f,
              onSelected: (_) => setState(() => _termFont = f),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Container(
          height: 190,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF040A06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF4ADE80)),
          ),
          child: ListView(
            children: _termLines.map((l) {
              final rendered = _termFont == 'Binario'
                  ? l.codeUnits.take(12).map((c) => c.toRadixString(2)).join(' ')
                  : _termFont == 'Hex'
                      ? l.codeUnits.take(16).map((c) => c.toRadixString(16)).join(' ')
                      : l;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('> $rendered', style: fontStyle),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _termCtrl,
                decoration: const InputDecoration(hintText: 'ACCESS_CORE / STATUS / HELP'),
              ),
            ),
            const SizedBox(width: 8),
            PrimaryGoldPillButton(
              label: 'Exec',
              onPressed: () {
                final cmd = _termCtrl.text.trim();
                if (cmd.isEmpty) return;
                _termCtrl.clear();
                setState(() {
                  _termLines.add(cmd);
                  if (cmd.toUpperCase() == 'HELP') {
                    _termLines.add('COMANDOS: STATUS, ACCESS_CORE, CLEAR');
                  } else if (cmd.toUpperCase() == 'ACCESS_CORE') {
                    _termLines.add('IF KEY == VALID THEN GRANT CORE_ACCESS!');
                    _fireTrigger('terminal_cmd', {'cmd': cmd});
                  } else {
                    _termLines.add('EXECUTADO: $cmd');
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _Grid2DPainter extends CustomPainter {
  final int heroX;
  final int heroY;
  final int npcX;
  final int npcY;
  final Set<String> walls;
  final bool fogEnabled;
  final ArcanaPalette palette;

  const _Grid2DPainter({
    required this.heroX,
    required this.heroY,
    required this.npcX,
    required this.npcY,
    required this.walls,
    required this.fogEnabled,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 7;
    final bgPaint = Paint()..color = palette.obsidianBg;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final linePaint = Paint()
      ..color = palette.subtleBorder
      ..strokeWidth = 1;

    for (var y = 0; y < 7; y++) {
      for (var x = 0; x < 7; x++) {
        final rect = Rect.fromLTWH(x * cell, y * cell, cell, cell);
        final dist = math.sqrt(math.pow(x - heroX, 2) + math.pow(y - heroY, 2));
        final inVision = !fogEnabled || dist <= 2.6;

        if (!inVision) {
          canvas.drawRect(rect, Paint()..color = Colors.black.withValues(alpha: 0.85));
        } else if (walls.contains('$x,$y')) {
          canvas.drawRect(rect, Paint()..color = palette.goldBorder.withValues(alpha: 0.55));
        }
        canvas.drawRect(rect, linePaint..style = PaintingStyle.stroke);
      }
    }

    // NPC Token
    final npcDist = math.sqrt(math.pow(npcX - heroX, 2) + math.pow(npcY - heroY, 2));
    if (!fogEnabled || npcDist <= 2.6) {
      canvas.drawCircle(
        Offset((npcX + 0.5) * cell, (npcY + 0.5) * cell),
        cell * 0.32,
        Paint()..color = palette.crimson,
      );
    }

    // Hero Token
    canvas.drawCircle(
      Offset((heroX + 0.5) * cell, (heroY + 0.5) * cell),
      cell * 0.36,
      Paint()..color = palette.goldHighlight,
    );
  }

  @override
  bool shouldRepaint(covariant _Grid2DPainter oldDelegate) =>
      heroX != oldDelegate.heroX ||
      heroY != oldDelegate.heroY ||
      fogEnabled != oldDelegate.fogEnabled;
}
