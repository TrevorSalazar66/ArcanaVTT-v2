import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/svg_icons.dart';
import '../../core/theme/arcana_colors.dart';
import '../../domain/entities/arcana_entities.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/heraldic_card.dart';
import '../widgets/heraldic_section_divider.dart';
import 'modal_shell.dart';
import 'universal_report_modal.dart';

/// Modal Geral da Campanha exibindo suas 7 Sub-abas planejadas e informações da mesa.
class CampaignGeneralModal extends StatefulWidget {
  final AppController controller;
  final Campaign campaign;

  const CampaignGeneralModal({
    super.key,
    required this.controller,
    required this.campaign,
  });

  @override
  State<CampaignGeneralModal> createState() => _CampaignGeneralModalState();
}

class _CampaignGeneralModalState extends State<CampaignGeneralModal> {
  int _subTabIndex = 0;

  static const _subTabs = [
    'Resumo',
    'Mesa',
    'Fichas',
    'Compêndio',
    'Diário',
    'Membros',
    'Oficina',
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final c = widget.campaign;

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.scroll,
      title: c.title.toUpperCase(),
      subtitle: '${c.systemName} • Código ${c.quickJoinCode}',
      badgeLabel: c.modeBadge,
      badgeColor: c.mode == CampaignMode.aoVivo ? p.emerald : p.goldPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_subTabs.length, (idx) {
                final active = idx == _subTabIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(_subTabs[idx]),
                    selected: active,
                    onSelected: (_) => setState(() => _subTabIndex = idx),
                    selectedColor: p.surfaceElevated,
                    side: BorderSide(
                      color: active ? p.goldBorder : p.subtleBorder,
                    ),
                    labelStyle: TextStyle(
                      color: active ? p.goldPrimary : p.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          HeraldicCard(
            goldAccent: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sub-aba: ${_subTabs[_subTabIndex]}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: p.goldPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  _subTabIndex == 0
                      ? '${c.synopsis}\n\nCapítulo atual: ${c.chapterTitle}'
                      : _subTabIndex == 1
                          ? 'Topologia P2P ativa: Eleição Dinâmica de Líder pronta para conectar a ${c.masterHandle} com sincronia de deltas JSON.'
                          : _subTabIndex == 3
                              ? 'Compêndio acoplado ao sistema ${c.systemName} com ocultação automática de categorias vazias.'
                              : 'Módulo "${_subTabs[_subTabIndex]}" da campanha ${c.title} preparado e sincronizado.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    HeraldicChipPill(
                      label: '${c.occupiedSlots}/${c.maxSlots} Vagas',
                      svgIcon: ArcanaSvgIcons.users,
                      color: p.infoBlue,
                    ),
                    const SizedBox(width: 8),
                    HeraldicChipPill(
                      label: c.masterHandle,
                      svgIcon: ArcanaSvgIcons.crown,
                      color: p.goldPrimary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PrimaryGoldPillButton(
                  label: 'Sincronizar Sessão',
                  svgIcon: ArcanaSvgIcons.wifi,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Presença P2P registrada em ${c.title} (${c.quickJoinCode}).',
                        ),
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(width: 8),
              SecondaryHeraldicButton(
                label: 'Denunciar',
                svgIcon: ArcanaSvgIcons.flag,
                borderColor: p.crimson,
                textColor: p.crimson,
                onPressed: () => showArcanaModal(
                  context,
                  builder: (_) => UniversalReportModal(
                    controller: widget.controller,
                    originType: 'campanha',
                    originId: c.id,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Wizard Funcional de 4 Etapas para Criação / Forja de Campanha.
class CreateCampaignWizardModal extends StatefulWidget {
  final AppController controller;

  const CreateCampaignWizardModal({super.key, required this.controller});

  @override
  State<CreateCampaignWizardModal> createState() =>
      _CreateCampaignWizardModalState();
}

class _CreateCampaignWizardModalState extends State<CreateCampaignWizardModal> {
  int _step = 0;
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _synopsisCtrl = TextEditingController();
  final TextEditingController _scheduleCtrl =
      TextEditingController(text: 'Sáb 21h');
  late String _selectedSystemId;
  CampaignMode _mode = CampaignMode.aoVivo;
  int _maxSlots = 5;
  bool _isPublic = true;

  @override
  void initState() {
    super.initState();
    _selectedSystemId = widget.controller.systems.first.id;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _synopsisCtrl.dispose();
    _scheduleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.wand2,
      title: 'FORJAR CAMPANHA',
      subtitle: 'Etapa ${_step + 1} de 4 — Setup Modular',
      badgeLabel: '${_step + 1}/4',
      badgeColor: p.goldPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (_step + 1) / 4,
            minHeight: 6,
            borderRadius: BorderRadius.circular(99),
            color: p.goldPrimary,
            backgroundColor: p.surfaceElevated,
          ),
          const SizedBox(height: 14),
          if (_step == 0) ...[
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Título da Campanha',
                hintText: 'Ex: Os Ecos da Cidadela Partida',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _synopsisCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Sinopse Inicial',
                hintText: 'Contextualize a premissa para os aventureiros...',
              ),
            ),
          ] else if (_step == 1) ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedSystemId,
              decoration: const InputDecoration(labelText: 'Sistema Base'),
              items: widget.controller.systems
                  .map(
                    (s) => DropdownMenuItem(
                      value: s.id,
                      child: Text('${s.name} (${s.version})'),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSystemId = val);
              },
            ),
            const SizedBox(height: 12),
            HeraldicCard(
              child: Text(
                'O compêndio do sistema escolhido será acoplado automaticamente e categorias vazias serão ocultadas da mesa.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ] else if (_step == 2) ...[
            DropdownButtonFormField<CampaignMode>(
              initialValue: _mode,
              decoration: const InputDecoration(labelText: 'Ritmo da Mesa'),
              items: const [
                DropdownMenuItem(value: CampaignMode.aoVivo, child: Text('Ao Vivo')),
                DropdownMenuItem(
                  value: CampaignMode.tempoLivre,
                  child: Text('Tempo Livre (Assíncrona)'),
                ),
                DropdownMenuItem(
                  value: CampaignMode.agendada,
                  child: Text('Agendada Semanal'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _mode = val);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _scheduleCtrl,
              decoration: const InputDecoration(labelText: 'Horário / Periodicidade'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Vagas máximas: $_maxSlots jogadores'),
                Row(
                  children: [
                    IconButton(
                      onPressed: _maxSlots > 2
                          ? () => setState(() => _maxSlots -= 1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    IconButton(
                      onPressed: _maxSlots < 10
                          ? () => setState(() => _maxSlots += 1)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mesa Pública para Exploração'),
              value: _isPublic,
              activeTrackColor: p.emerald,
              onChanged: (v) => setState(() => _isPublic = v),
            ),
          ] else ...[
            HeraldicCard(
              goldAccent: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleCtrl.text.trim().isEmpty
                        ? 'Nova Crônica Heráldica'
                        : _titleCtrl.text.trim(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: p.goldPrimary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _synopsisCtrl.text.trim().isEmpty
                        ? 'Campanha recém-forjada no sistema oficial.'
                        : _synopsisCtrl.text.trim(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text('Vagas: $_maxSlots • ${_isPublic ? 'Pública' : 'Privada'}'),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              if (_step > 0) ...[
                Expanded(
                  child: SecondaryHeraldicButton(
                    label: 'Voltar',
                    onPressed: () => setState(() => _step -= 1),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                flex: 2,
                child: PrimaryGoldPillButton(
                  label: _step < 3 ? 'Próxima Etapa' : 'Forjar Campanha',
                  onPressed: () {
                    if (_step < 3) {
                      setState(() => _step += 1);
                      return;
                    }
                    widget.controller.createCampaign(
                      title: _titleCtrl.text.trim().isEmpty
                          ? 'Nova Crônica Heráldica'
                          : _titleCtrl.text.trim(),
                      synopsis: _synopsisCtrl.text.trim().isEmpty
                          ? 'Campanha forjada pelo wizard modular de 4 etapas.'
                          : _synopsisCtrl.text.trim(),
                      systemId: _selectedSystemId,
                      mode: _mode,
                      scheduleText: _scheduleCtrl.text.trim(),
                      maxSlots: _maxSlots,
                      isPublic: _isPublic,
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Modal de Candidatura do Jogador a uma Campanha Pública.
class CampaignApplicationModal extends StatefulWidget {
  final Campaign campaign;

  const CampaignApplicationModal({super.key, required this.campaign});

  @override
  State<CampaignApplicationModal> createState() =>
      _CampaignApplicationModalState();
}

class _CampaignApplicationModalState extends State<CampaignApplicationModal> {
  final TextEditingController _pitchCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _pitchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.feather,
      title: 'CANDIDATURA À MESA',
      subtitle: '${widget.campaign.title} (${widget.campaign.masterHandle})',
      child: _sent
          ? HeraldicCard(
              borderColor: p.emerald,
              child: Text(
                'Sua candidatura foi enviada ao mestre ${widget.campaign.masterHandle}! Você receberá notificação assim que aprovada.',
                style: TextStyle(color: p.emerald, fontWeight: FontWeight.w600),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _pitchCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Apresentação & Conceito de Personagem',
                    hintText: 'Conte seu estilo de jogo e ideia de herói...',
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryGoldPillButton(
                  label: 'Enviar Candidatura',
                  svgIcon: ArcanaSvgIcons.check,
                  onPressed: () => setState(() => _sent = true),
                ),
              ],
            ),
    );
  }
}

/// Modal de Filtros Avançados de Campanhas.
class CampaignFiltersModal extends StatelessWidget {
  final String currentModeFilter;
  final ValueChanged<String> onApplyFilter;

  const CampaignFiltersModal({
    super.key,
    required this.currentModeFilter,
    required this.onApplyFilter,
  });

  @override
  Widget build(BuildContext context) {
    final options = ['Todas', 'Ao Vivo', 'Tempo Livre', 'Agendada'];
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.filter,
      title: 'FILTROS DE CAMPANHAS',
      subtitle: 'Refine mesas por ritmo de jogo e disponibilidade',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HeraldicSectionDivider(
            svgIcon: ArcanaSvgIcons.clock,
            title: 'RITMO DA MESA',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              return ChoiceChip(
                label: Text(opt),
                selected: currentModeFilter == opt,
                onSelected: (_) {
                  onApplyFilter(opt);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

