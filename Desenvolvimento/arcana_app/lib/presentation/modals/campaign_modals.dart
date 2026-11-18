import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/svg_icons.dart';
import '../../core/security/rbac_guard.dart';
import '../../core/theme/arcana_colors.dart';
import '../../domain/entities/arcana_entities.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/heraldic_card.dart';
import '../widgets/heraldic_section_divider.dart';
import '../widgets/svg_icon_widget.dart';
import 'hero_sheet_highlight_modal.dart';
import 'modal_shell.dart';
import 'universal_report_modal.dart';

/// Modal Geral da Campanha exibindo suas 7 Sub-abas oficiais e governança da mesa.
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
  String _activeTab = 'Geral';
  List<CampaignMemberSummary> _members = [];
  bool _loadingMembers = false;
  bool _updatingMember = false;
  String? _memberActionError;

  bool get _canManageTable => RbacGuard.canManageCampaignTable(
        isTableMaster: widget.campaign.userRelation == CampaignSegment.mestre,
        globalRole: widget.controller.currentUser.role,
      );

  List<String> get _visibleTabs => [
        'Geral',
        'Chats',
        'Cenas',
        'Diário',
        if (_canManageTable) 'Oficina',
        'Personagens',
        if (_canManageTable) 'Configs',
      ];

  @override
  void initState() {
    super.initState();
    if (_canManageTable) {
      _loadMembers();
    }
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loadingMembers = true;
      _memberActionError = null;
    });
    final list = await widget.controller.fetchCampaignMembers(widget.campaign.id);
    if (!mounted) return;
    setState(() {
      _loadingMembers = false;
      _members = list;
    });
  }

  Future<void> _updateMember({
    required String targetUserId,
    String? status,
    String? tableRole,
  }) async {
    setState(() {
      _updatingMember = true;
      _memberActionError = null;
    });
    final updated = await widget.controller.manageCampaignMember(
      campaignId: widget.campaign.id,
      targetUserId: targetUserId,
      status: status,
      tableRole: tableRole,
    );
    if (!mounted) return;
    setState(() {
      _updatingMember = false;
      if (updated != null) {
        _members = updated;
      } else {
        _memberActionError = widget.controller.lastSyncError ??
            'Não foi possível atualizar o participante.';
      }
    });
  }

  Widget _buildTabContent(BuildContext context, ArcanaPalette p, Campaign c) {
    switch (_activeTab) {
      case 'Personagens':
        return ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final cmpHero = widget.controller.characterForCampaign(c.id);
            final isMember = c.userRelation != CampaignSegment.explorar;
            if (!isMember && cmpHero == null) {
              return HeraldicCard(
                borderColor: p.infoBlue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personagens da Mesa',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: p.infoBlue),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'A criação de ficha nesta campanha é liberada automaticamente após o Mestre aprovar sua candidatura.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }
            if (cmpHero == null) {
              return HeraldicCard(
                goldAccent: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Forje seu Herói para ${c.title}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: p.goldPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Você já é participante ativo desta mesa. Crie agora sua ficha AlphaD6 (3d6 e 12 slots) vinculada a esta campanha.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    PrimaryGoldPillButton(
                      label: 'Criar Ficha nesta Mesa',
                      svgIcon: ArcanaSvgIcons.swords,
                      onPressed: () => showArcanaModal(
                        context,
                        builder: (_) => HeroSheetHighlightModal(
                          controller: widget.controller,
                          boundCampaign: c,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return HeraldicCard(
              goldAccent: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${cmpHero.name} — Nv. ${cmpHero.level}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: p.goldPrimary),
                        ),
                      ),
                      HeraldicChipPill(
                        label: cmpHero.heroClass,
                        color: p.emerald,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Corpo +${cmpHero.corpo} • Mente +${cmpHero.mente} • Espírito +${cmpHero.espirito} • ${cmpHero.slots.length}/12 Slots',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  PrimaryGoldPillButton(
                    label: 'Abrir / Editar Ficha da Mesa',
                    svgIcon: ArcanaSvgIcons.feather,
                    onPressed: () => showArcanaModal(
                      context,
                      builder: (_) => HeroSheetHighlightModal(
                        controller: widget.controller,
                        boundCampaign: c,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      case 'Configs':
        final pending =
            _members.where((m) => m.status == 'pending').toList();
        final active =
            _members.where((m) => m.status == 'active').toList();
        return HeraldicCard(
          goldAccent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Candidaturas & Cargos Locais',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: p.goldPrimary),
                  ),
                  IconButton(
                    onPressed: _loadingMembers ? null : _loadMembers,
                    icon: SvgIconWidget(
                      ArcanaSvgIcons.sparkles,
                      size: 16,
                      color: p.goldPrimary,
                    ),
                  ),
                ],
              ),
              if (_memberActionError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _memberActionError!,
                  style: TextStyle(color: p.crimson, fontSize: 12),
                ),
              ],
              if (_loadingMembers)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                const SizedBox(height: 8),
                Text(
                  'CANDIDATURAS PENDENTES (${pending.length})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: p.goldPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                if (pending.isEmpty)
                  Text(
                    'Nenhuma solicitação pendente no momento.',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  ...pending.map(
                    (cand) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: HeraldicCard(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${cand.displayName} (@${cand.username})',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            if (cand.applicationPitch.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                cand.applicationPitch,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: SecondaryHeraldicButton(
                                    label: 'Aprovar',
                                    borderColor: p.emerald,
                                    textColor: p.emerald,
                                    onPressed: _updatingMember
                                        ? null
                                        : () => _updateMember(
                                              targetUserId: cand.userId,
                                              status: 'active',
                                            ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SecondaryHeraldicButton(
                                    label: 'Recusar',
                                    borderColor: p.crimson,
                                    textColor: p.crimson,
                                    onPressed: _updatingMember
                                        ? null
                                        : () => _updateMember(
                                              targetUserId: cand.userId,
                                              status: 'rejected',
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'PARTICIPANTES ATIVOS (${active.length})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: p.infoBlue,
                  ),
                ),
                const SizedBox(height: 6),
                if (active.isEmpty)
                  Text(
                    'Nenhum participante sincronizado ainda.',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  ...active.map(
                    (mem) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: HeraldicCard(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${mem.displayName} (@${mem.username})',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    mem.tableRole == 'mestre'
                                        ? 'MESTRE DA MESA'
                                        : mem.tableRole == 'assistente_mestre'
                                            ? 'AUXILIAR LOCAL'
                                            : 'JOGADOR',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: p.goldPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (mem.tableRole != 'mestre')
                              SecondaryHeraldicButton(
                                label: mem.tableRole == 'assistente_mestre'
                                    ? 'Tornar Jogador'
                                    : 'Tornar Auxiliar',
                                borderColor: p.goldBorder,
                                onPressed: _updatingMember
                                    ? null
                                    : () => _updateMember(
                                          targetUserId: mem.userId,
                                          tableRole:
                                              mem.tableRole == 'assistente_mestre'
                                                  ? 'jogador'
                                                  : 'assistente_mestre',
                                        ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      case 'Oficina':
        return HeraldicCard(
          goldAccent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Oficina de Cenas (Exclusiva do Mestre)',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: p.goldPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                '6 modelos interativos: Grid Tático 2D, Lousa Livre, Cartas & Tabuleiro, Mahjong, Cofre com Senha e Terminal Hacker.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      default:
        final description = switch (_activeTab) {
          'Geral' =>
            '${c.synopsis}\n\nCapítulo atual: ${c.chapterTitle}\nRelação na mesa: ${c.userRelation == CampaignSegment.mestre ? 'Mestre da Mesa' : c.userRelation == CampaignSegment.auxiliar ? 'Auxiliar Local' : c.userRelation == CampaignSegment.jogando ? 'Jogador Ativo' : 'Visitante / Explorando'}',
          'Chats' =>
            'Canal de comunicação híbrido e rolador 3d6 privado da mesa ${c.title}, pronto para deltas JSON.',
          'Cenas' =>
            'Palco visual da cena atual sincronizado por Eleição Dinâmica de Líder P2P com ${c.masterHandle}.',
          'Diário' =>
            'Crônica compartilhada de sessões, pistas e notas de ${c.title}.',
          _ => '${c.synopsis}\n\nCapítulo atual: ${c.chapterTitle}',
        };
        return HeraldicCard(
          goldAccent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sub-aba: $_activeTab',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: p.goldPrimary,
                    ),
              ),
              const SizedBox(height: 6),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
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
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final c = widget.campaign;
    final tabs = _visibleTabs;

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
              children: tabs.map((tabName) {
                final active = tabName == _activeTab;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(tabName),
                    selected: active,
                    onSelected: (_) {
                      setState(() => _activeTab = tabName);
                      if (tabName == 'Configs' && _members.isEmpty) {
                        _loadMembers();
                      }
                    },
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
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          _buildTabContent(context, p, c),
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
                  onPressed: () async {
                    if (_step < 3) {
                      setState(() => _step += 1);
                      return;
                    }
                    await widget.controller.createCampaign(
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
                    if (context.mounted) Navigator.of(context).pop();
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

/// Modal de Candidatura do Jogador a uma Campanha Pública (sem ficha prévia).
class CampaignApplicationModal extends StatefulWidget {
  final AppController controller;
  final Campaign campaign;

  const CampaignApplicationModal({
    super.key,
    required this.controller,
    required this.campaign,
  });

  @override
  State<CampaignApplicationModal> createState() =>
      _CampaignApplicationModalState();
}

class _CampaignApplicationModalState extends State<CampaignApplicationModal> {
  final TextEditingController _pitchCtrl = TextEditingController();
  bool _submitting = false;
  bool _sent = false;
  String? _errorMsg;

  @override
  void dispose() {
    _pitchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final c = widget.campaign;
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.feather,
      title: 'CANDIDATURA À MESA',
      subtitle: '${c.title} (${c.masterHandle})',
      child: _sent
          ? HeraldicCard(
              borderColor: p.emerald,
              child: Text(
                'Sua candidatura foi enviada ao mestre ${c.masterHandle}! Você receberá notificação assim que aprovada para forjar sua ficha na aba Personagens da mesa.',
                style: TextStyle(color: p.emerald, fontWeight: FontWeight.w600),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HeraldicCard(
                  goldAccent: true,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              c.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          HeraldicChipPill(
                            label: '${c.occupiedSlots}/${c.maxSlots} Vagas',
                            color: p.goldPrimary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${c.systemName} • Mestre ${c.masterHandle}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                HeraldicCard(
                  borderColor: p.infoBlue,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SvgIconWidget(
                        ArcanaSvgIcons.shield,
                        size: 18,
                        color: p.infoBlue,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REGRA OFICIAL DE CRIAÇÃO DE FICHA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: p.infoBlue,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'A ficha do seu herói será liberada automaticamente assim que o Mestre aprovar sua candidatura na mesa.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pitchCtrl,
                  maxLength: 200,
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Apresentação ao Mestre',
                    hintText:
                        'Conte brevemente seu estilo de jogo (5 a 200 caracteres)...',
                    helperText: '${_pitchCtrl.text.length} / 200 caracteres',
                  ),
                ),
                if (_errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMsg!,
                    style: TextStyle(color: p.crimson, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 14),
                PrimaryGoldPillButton(
                  label: _submitting
                      ? 'Enviando Candidatura...'
                      : 'Enviar Candidatura',
                  svgIcon: ArcanaSvgIcons.check,
                  onPressed: _submitting
                      ? null
                      : () async {
                          final pitch = _pitchCtrl.text.trim();
                          if (pitch.length < 5) {
                            setState(() {
                              _errorMsg =
                                  'Escreva pelo menos 5 caracteres na apresentação ao Mestre.';
                            });
                            return;
                          }
                          setState(() {
                            _submitting = true;
                            _errorMsg = null;
                          });
                          final ok = await widget.controller.applyToCampaign(
                            campaignId: widget.campaign.id,
                            pitch: pitch,
                          );
                          if (!mounted) return;
                          setState(() {
                            _submitting = false;
                            if (ok) {
                              _sent = true;
                            } else {
                              _errorMsg = widget.controller.lastSyncError ??
                                  'Não foi possível registrar candidatura no servidor.';
                            }
                          });
                        },
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

