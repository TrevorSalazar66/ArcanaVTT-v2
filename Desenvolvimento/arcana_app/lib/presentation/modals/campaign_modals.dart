import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../controllers/app_controller.dart';
import '../../../core/constants/svg_icons.dart';
import '../../../core/security/rbac_guard.dart';
import '../../../core/theme/arcana_colors.dart';
import '../../../domain/entities/arcana_entities.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/heraldic_card.dart';
import '../widgets/svg_icon_widget.dart';
import 'community_chat_modal.dart';
import 'hero_sheet_highlight_modal.dart';
import 'modal_shell.dart';
import 'profile_and_nav_modals.dart';
import 'universal_report_modal.dart';
import 'workshop_and_scenes_modals.dart';

// =============================================================================
// 1. HUB DA CAMPANHA (7 SUB-ABAS COMPLETAS)
// =============================================================================

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
  int _subTab = 0; // 0: Geral | 1: Chats | 2: Cenas | 3: Diario | 4: Oficina | 5: Personagens | 6: Configs
  List<CampaignMemberSummary> _members = [];
  List<HeroCharacter> _partyChars = [];
  bool _loading = true;
  final _diaryTitleCtrl = TextEditingController();
  final _diaryBodyCtrl = TextEditingController();
  String _diaryScope = 'cronica';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      widget.controller.fetchCampaignMembers(widget.campaign.id),
      widget.controller.fetchCampaignCharacters(widget.campaign.id),
      widget.controller.fetchCampaignScenes(widget.campaign.id),
      widget.controller.fetchGmBannedPlayers(),
    ]);
    if (!mounted) return;
    setState(() {
      _members = results[0] as List<CampaignMemberSummary>;
      _partyChars = results[1] as List<HeroCharacter>;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _diaryTitleCtrl.dispose();
    _diaryBodyCtrl.dispose();
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
    final canManageTable = RbacGuard.canManageCampaignTable(
      globalRole: ctrl.currentUser.role,
      relation: cmp.userRelation,
    );

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.scroll,
      title: cmp.title,
      subtitle: '${cmp.systemName} · Codigo ${cmp.quickJoinCode} · ${cmp.ageRating}',
      badgeLabel: cmp.modeBadge,
      badgeColor: cmp.mode == CampaignMode.aoVivo ? p.emerald : p.infoBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final t in [
                  (0, 'Geral'),
                  (1, 'Chats (3)'),
                  (2, 'Cenas'),
                  (3, 'Diario'),
                  if (canManageTable) (4, 'Oficina'),
                  (5, 'Personagens'),
                  if (canManageTable) (6, 'Configs'),
                ]) ...[
                  ChoiceChip(
                    label: Text(t.$2),
                    selected: _subTab == t.$1,
                    onSelected: (_) => setState(() => _subTab = t.$1),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else ...[
            if (_subTab == 0) _buildGeralTab(context, p, ctrl, cmp, canManageTable),
            if (_subTab == 1) _buildChatsTab(context, p, ctrl, cmp, canManageTable),
            if (_subTab == 2) _buildCenasTab(context, p, ctrl, cmp),
            if (_subTab == 3) _buildDiarioTab(context, p, ctrl, cmp, canManageTable),
            if (_subTab == 4 && canManageTable) _buildOficinaTab(context, p, ctrl, cmp),
            if (_subTab == 5) _buildPersonagensTab(context, p, ctrl, cmp),
            if (_subTab == 6 && canManageTable) _buildConfigsTab(context, p, ctrl, cmp),
          ],
        ],
      ),
    );
  }

  Widget _buildGeralTab(
    BuildContext context,
    ArcanaPalette p,
    AppController ctrl,
    Campaign cmp,
    bool canManage,
  ) {
    final activeMembers = _members.where((m) => m.status == 'active').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeraldicCard(
          goldAccent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Mural da Mesa',
                      style: TextStyle(fontWeight: FontWeight.w700, color: p.goldHighlight)),
                  IconButton(
                    tooltip: 'Copiar Codigo Quick Join',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: cmp.quickJoinCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Codigo ${cmp.quickJoinCode} copiado!')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                  ),
                ],
              ),
              Text(cmp.noticeBoard, style: TextStyle(fontSize: 13, color: p.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Capitulo: ${cmp.chapterTitle} · Agenda: ${cmp.scheduleText} · Sessoes: ${cmp.sessionsCount}',
                style: TextStyle(fontSize: 11.5, color: p.textSecondary),
              ),
              if (cmp.discordVoiceUrl.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Canal Voz Discord: ${cmp.discordVoiceUrl}',
                  style: TextStyle(fontSize: 11.5, color: p.infoBlue),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Elenco Ativo (${activeMembers.length}/${cmp.maxSlots}):',
          style: TextStyle(fontWeight: FontWeight.w700, color: p.goldHighlight),
        ),
        const SizedBox(height: 8),
        for (final m in activeMembers)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: HeraldicCard(
              onTap: () => showArcanaModal(context,
                builder: (_) => SocialProfileModal(
                  controller: ctrl,
                  targetUserId: m.userId,
                  targetUsername: m.username,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${m.displayName} (@${m.username})',
                      style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary),
                    ),
                  ),
                  HeraldicChipPill(
                    label: m.tableRole.toUpperCase(),
                    color: m.tableRole == 'mestre' ? p.goldPrimary : p.infoBlue,
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (cmp.userRelation != CampaignSegment.mestre &&
                cmp.userRelation != CampaignSegment.explorar)
              Expanded(
                child: SecondaryHeraldicButton(
                  label: 'Sair da Campanha',
                  svgIcon: ArcanaSvgIcons.logOut,
                  borderColor: p.crimson,
                  textColor: p.crimson,
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    await ctrl.leaveCampaign(cmp.id);
                    if (nav.mounted) nav.pop();
                  },
                ),
              ),
            if (cmp.userRelation != CampaignSegment.mestre) const SizedBox(width: 8),
            Expanded(
              child: SecondaryHeraldicButton(
                label: 'Denunciar Mesa',
                svgIcon: ArcanaSvgIcons.flag,
                borderColor: p.crimson,
                textColor: p.crimson,
                onPressed: () => showArcanaModal(context,
                  builder: (_) => UniversalReportModal(
                    controller: ctrl,
                    originType: 'campanha',
                    originId: cmp.id,
                    targetUserId: cmp.ownerId,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChatsTab(
    BuildContext context,
    ArcanaPalette p,
    AppController ctrl,
    Campaign cmp,
    bool canManage,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final ch in cmp.channels) ...[
          HeraldicCard(
            onTap: () => showArcanaModal(context,
              builder: (_) => CommunityChatModal(
                controller: ctrl,
                channelId: '${cmp.id}_${ch.replaceAll('#', '')}',
                campaignId: cmp.id,
                tableRelation: cmp.userRelation,
              ),
            ),
            child: Row(
              children: [
                SvgIconWidget(ArcanaSvgIcons.hash, size: 18, color: p.goldPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(ch,
                      style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
                ),
                if (canManage)
                  IconButton(
                    tooltip: 'Limpar Canal',
                    onPressed: () => ctrl.clearChatChannel(
                      cmp.id,
                      '${cmp.id}_${ch.replaceAll('#', '')}',
                    ),
                    icon: SvgIconWidget(ArcanaSvgIcons.trash, size: 16, color: p.crimson),
                  ),
                SvgIconWidget(ArcanaSvgIcons.chevronRight, size: 16, color: p.goldPrimary),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildCenasTab(
    BuildContext context,
    ArcanaPalette p,
    AppController ctrl,
    Campaign cmp,
  ) {
    final scenes = ctrl.campaignScenesMap[cmp.id] ?? const [];
    if (scenes.isEmpty) {
      return HeraldicCard(
        child: Text(
          'Nenhuma cena liberada pelo Mestre nesta sessao ainda.',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        for (final s in scenes) ...[
          HeraldicCard(
            goldAccent: s.isActive,
            onTap: () => showArcanaModal(context,
              builder: (_) => InteractiveSceneStageModal(
                controller: ctrl,
                campaign: cmp,
                scene: s,
              ),
            ),
            child: Row(
              children: [
                SvgIconWidget(ArcanaSvgIcons.map, size: 22, color: p.goldHighlight),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name,
                          style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
                      Text(s.modelType.labelPtBr,
                          style: TextStyle(fontSize: 11.5, color: p.goldPrimary)),
                    ],
                  ),
                ),
                PrimaryGoldPillButton(
                  label: 'Entrar',
                  onPressed: () => showArcanaModal(context,
                    builder: (_) => InteractiveSceneStageModal(
                      controller: ctrl,
                      campaign: cmp,
                      scene: s,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildDiarioTab(
    BuildContext context,
    ArcanaPalette p,
    AppController ctrl,
    Campaign cmp,
    bool canManage,
  ) {
    final canSeeSecrets = RbacGuard.canViewSecretNotes(
      globalRole: ctrl.currentUser.role,
      relation: cmp.userRelation,
    );
    final entries = cmp.diaryEntries.where((e) {
      if (e.scope == 'segredo_gm' || !e.visibleToPlayers) return canSeeSecrets;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeraldicCard(
          goldAccent: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calendario: ${cmp.worldClock.monthName}, Dia ${cmp.worldClock.day}',
                style: TextStyle(fontWeight: FontWeight.w700, color: p.goldHighlight),
              ),
              Text('${cmp.worldClock.hour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(color: p.emerald, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (cmp.factions.isNotEmpty) ...[
          Text('Faccoes Conhecidas:',
              style: TextStyle(fontWeight: FontWeight.w700, color: p.goldPrimary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: cmp.factions
                .map((f) => HeraldicChipPill(
                      label: '${f.name}: ${f.reputation > 0 ? "+" : ""}${f.reputation}',
                      color: f.reputation >= 0 ? p.emerald : p.crimson,
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],
        if (canManage) ...[
          DropdownButtonFormField<String>(
            initialValue: _diaryScope,
            decoration: const InputDecoration(labelText: 'Aba do Diario / Escopo'),
            items: const [
              DropdownMenuItem(value: 'cronica', child: Text('Cronica Publica da Mesa')),
              DropdownMenuItem(value: 'pessoal', child: Text('Nota Pessoal')),
              DropdownMenuItem(value: 'segredo_gm', child: Text('Segredos do Mestre (Oculto)')),
              DropdownMenuItem(value: 'roteiro', child: Text('Roteiro da Sessao')),
            ],
            onChanged: (v) => setState(() => _diaryScope = v ?? 'cronica'),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _diaryTitleCtrl,
            decoration: const InputDecoration(labelText: 'Titulo do Registro'),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _diaryBodyCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Anotacao / Lore'),
          ),
          const SizedBox(height: 8),
          SecondaryHeraldicButton(
            label: 'Registrar no Diario',
            svgIcon: ArcanaSvgIcons.feather,
            expand: true,
            onPressed: () async {
              if (_diaryTitleCtrl.text.trim().isEmpty) return;
              final next = [
                DiaryEntry(
                  id: 'dia_${DateTime.now().millisecondsSinceEpoch}',
                  scope: _diaryScope,
                  title: _diaryTitleCtrl.text.trim(),
                  content: _diaryBodyCtrl.text.trim(),
                  visibleToPlayers: _diaryScope != 'segredo_gm',
                  authorId: ctrl.currentUser.id,
                  createdAt: DateTime.now().toIso8601String(),
                ).toJson(),
                ...cmp.diaryEntries.map((e) => e.toJson()),
              ];
              _diaryTitleCtrl.clear();
              _diaryBodyCtrl.clear();
              await ctrl.updateCampaignSettings(
                campaignId: cmp.id,
                statePatch: {'diary_entries': next},
              );
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 12),
        ],
        for (final d in entries) ...[
          HeraldicCard(
            borderColor: d.scope == 'segredo_gm' ? p.crimson : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeraldicChipPill(
                  label: d.scope.toUpperCase(),
                  color: d.scope == 'segredo_gm' ? p.crimson : p.goldPrimary,
                ),
                const SizedBox(height: 6),
                Text(d.title, style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
                Text(d.content, style: TextStyle(fontSize: 12.5, color: p.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildOficinaTab(
    BuildContext context,
    ArcanaPalette p,
    AppController ctrl,
    Campaign cmp,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeraldicCard(
          goldAccent: true,
          onTap: () => showArcanaModal(context,
            builder: (_) => OficinaCenasModuleModal(controller: ctrl, campaign: cmp),
          ),
          child: Row(
            children: [
              SvgIconWidget(ArcanaSvgIcons.map, size: 26, color: p.goldHighlight),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1. Gestao de Cenas (Ate 18)',
                        style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
                    Text('6 Modelos Interativos + Construtor No-Code + Capturar Alvo',
                        style: TextStyle(fontSize: 12, color: p.textSecondary)),
                  ],
                ),
              ),
              SvgIconWidget(ArcanaSvgIcons.chevronRight, size: 18, color: p.goldPrimary),
            ],
          ),
        ),
        const SizedBox(height: 10),
        HeraldicCard(
          onTap: () => showArcanaModal(context,
            builder: (_) => OficinaCompendioModuleModal(controller: ctrl, campaign: cmp),
          ),
          child: Row(
            children: [
              SvgIconWidget(ArcanaSvgIcons.scroll, size: 26, color: p.infoBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('2. Compendio Delta da Mesa',
                        style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
                    Text('Itens, Seres, Poderes e Blocos RoleGate',
                        style: TextStyle(fontSize: 12, color: p.textSecondary)),
                  ],
                ),
              ),
              SvgIconWidget(ArcanaSvgIcons.chevronRight, size: 18, color: p.goldPrimary),
            ],
          ),
        ),
        const SizedBox(height: 10),
        HeraldicCard(
          onTap: () => showArcanaModal(context,
            builder: (_) => OficinaMundoModuleModal(controller: ctrl, campaign: cmp),
          ),
          child: Row(
            children: [
              SvgIconWidget(ArcanaSvgIcons.clock, size: 26, color: p.emerald),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('3. Mundo, Overworld (25 Mapas) & Faccoes',
                        style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
                    Text('Calendario Procedural, Mapas Hex e Matriz -100..+100',
                        style: TextStyle(fontSize: 12, color: p.textSecondary)),
                  ],
                ),
              ),
              SvgIconWidget(ArcanaSvgIcons.chevronRight, size: 18, color: p.goldPrimary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonagensTab(
    BuildContext context,
    ArcanaPalette p,
    AppController ctrl,
    Campaign cmp,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryGoldPillButton(
          label: ctrl.characterForCampaign(cmp.id) != null
              ? 'Editar Minha Ficha Nesta Campanha'
              : 'Criar Minha Ficha (1 por Mesa)',
          svgIcon: ArcanaSvgIcons.sword,
          expand: true,
          onPressed: () => showArcanaModal(context,
            builder: (_) => HeroSheetHighlightModal(
              controller: ctrl,
              initialCampaignId: cmp.id,
            ),
          ).then((_) => _loadData()),
        ),
        const SizedBox(height: 12),
        Text(
          'Vitrine do Grupo (${_partyChars.length} fichas):',
          style: TextStyle(fontWeight: FontWeight.w700, color: p.goldHighlight),
        ),
        const SizedBox(height: 8),
        if (_partyChars.isEmpty)
          HeraldicCard(
            child: Text(
              'Nenhum heroi cadastrado nesta mesa ainda.',
              style: TextStyle(color: p.textSecondary),
            ),
          )
        else
          for (final ch in _partyChars) ...[
            HeraldicCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ch.name} (${ch.heroClass} Nv.${ch.level})',
                          style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary),
                        ),
                        Text(
                          'PV ${ch.hpCurrent}/${ch.hpMax} · Anima ${ch.animaCurrent}/${ch.animaMax} · ${ch.silverCoins} Prata',
                          style: TextStyle(fontSize: 12, color: p.emerald),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _buildConfigsTab(
    BuildContext context,
    ArcanaPalette p,
    AppController ctrl,
    Campaign cmp,
  ) {
    final pending = _members.where((m) => m.status == 'pending').toList();
    final active = _members.where((m) => m.status == 'active' && m.userId != cmp.ownerId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Candidaturas Pendentes (${pending.length}):',
            style: TextStyle(fontWeight: FontWeight.w700, color: p.goldHighlight)),
        const SizedBox(height: 6),
        for (final m in pending)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: HeraldicCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${m.displayName} (@${m.username})',
                      style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
                  Text(m.applicationPitch,
                      style: TextStyle(fontSize: 12, color: p.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryGoldPillButton(
                          label: 'Aprovar',
                          onPressed: () async {
                            await ctrl.manageCampaignMember(
                              campaignId: cmp.id,
                              targetUserId: m.userId,
                              status: 'active',
                            );
                            await _loadData();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SecondaryHeraldicButton(
                        label: 'Recusar',
                        borderColor: p.crimson,
                        textColor: p.crimson,
                        onPressed: () async {
                          await ctrl.manageCampaignMember(
                            campaignId: cmp.id,
                            targetUserId: m.userId,
                            status: 'rejected',
                          );
                          await _loadData();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        Text('Gestao Disciplinar & Auxiliares:',
            style: TextStyle(fontWeight: FontWeight.w700, color: p.goldHighlight)),
        const SizedBox(height: 6),
        for (final m in active)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: HeraldicCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${m.displayName} (${m.tableRole})',
                      style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      SecondaryHeraldicButton(
                        label: m.tableRole == 'assistente_mestre'
                            ? 'Rebaixar Jogador'
                            : 'Promover Auxiliar',
                        onPressed: () async {
                          await ctrl.manageCampaignMember(
                            campaignId: cmp.id,
                            targetUserId: m.userId,
                            tableRole: m.tableRole == 'assistente_mestre'
                                ? 'jogador'
                                : 'assistente_mestre',
                          );
                          await _loadData();
                        },
                      ),
                      SecondaryHeraldicButton(
                        label: 'Expulsar',
                        onPressed: () async {
                          await ctrl.manageCampaignMember(
                            campaignId: cmp.id,
                            targetUserId: m.userId,
                            status: 'kicked',
                          );
                          await _loadData();
                        },
                      ),
                      SecondaryHeraldicButton(
                        label: 'Banir (Nivel Mestre)',
                        borderColor: p.crimson,
                        textColor: p.crimson,
                        onPressed: () async {
                          await ctrl.manageCampaignMember(
                            campaignId: cmp.id,
                            targetUserId: m.userId,
                            status: 'banned',
                            banReason: 'Banido em todas as mesas do Mestre',
                          );
                          await _loadData();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (ctrl.gmBannedPlayers.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Jogadores Banidos por Voce (Master-Level):',
              style: TextStyle(fontWeight: FontWeight.w700, color: p.crimson)),
          for (final b in ctrl.gmBannedPlayers)
            HeraldicCard(
              child: Row(
                children: [
                  Expanded(child: Text('ID: ${b['player_id']} · ${b['ban_reason']}')),
                  TextButton(
                    onPressed: () async {
                      await ctrl.unbanGmPlayer(b['player_id'] ?? '');
                      if (mounted) setState(() {});
                    },
                    child: const Text('Desbanir'),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 10),
        SwitchListTile(
          value: cmp.autoApproveActions,
          onChanged: (v) async {
            await ctrl.updateCampaignSettings(
              campaignId: cmp.id,
              statePatch: {'auto_approve_actions': v},
            );
            if (mounted) setState(() {});
          },
          title: const Text('Auto-aprovar Descanso/Cura no Chat'),
        ),
        if (cmp.isInactiveArchived)
          PrimaryGoldPillButton(
            label: 'Reativar Mesa Arquivada (Ciclo 75 Dias)',
            expand: true,
            onPressed: () async {
              await ctrl.updateCampaignSettings(
                campaignId: cmp.id,
                reactivate75d: true,
              );
              if (mounted) setState(() {});
            },
          ),
      ],
    );
  }
}

// =============================================================================
// 2. WIZARD DE CRIACAO DE CAMPANHA EM 4 ETAPAS + PREVIEW AO VIVO
// =============================================================================

class CreateCampaignWizardModal extends StatefulWidget {
  final AppController controller;

  const CreateCampaignWizardModal({super.key, required this.controller});

  @override
  State<CreateCampaignWizardModal> createState() =>
      _CreateCampaignWizardModalState();
}

class _CreateCampaignWizardModalState extends State<CreateCampaignWizardModal> {
  int _step = 0; // 0..3
  final _titleCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController(text: 'Fantasia, Investigacao');
  final _synopsisCtrl = TextEditingController();
  final _scheduleCtrl = TextEditingController(text: 'Sabados 20h');
  String _iconName = 'swords';
  String _bannerPreset = 'cidadela_obsidiana';
  String _selectedSystemId = 'sys_universal';
  int _maxSlots = 5;
  String _ageRating = '16+';
  CampaignMode _mode = CampaignMode.aoVivo;
  bool _isPublic = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller.systems.isNotEmpty) {
      _selectedSystemId = widget.controller.systems.first.id;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _tagsCtrl.dispose();
    _synopsisCtrl.dispose();
    _scheduleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final ctrl = widget.controller;

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.wand2,
      title: 'Forjar Nova Campanha',
      subtitle: 'Wizard em 4 Etapas (${_step + 1}/4)',
      badgeLabel: 'ETAPA ${_step + 1}/4',
      badgeColor: p.goldPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (_step + 1) / 4,
            minHeight: 6,
            backgroundColor: p.surfaceElevated,
            valueColor: AlwaysStoppedAnimation<Color>(p.goldHighlight),
          ),
          const SizedBox(height: 14),
          if (_step == 0) ...[
            TextField(
              controller: _titleCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Titulo da Campanha'),
            ),
            const SizedBox(height: 10),
            Text('Icone Heraldico:', style: TextStyle(fontSize: 12, color: p.textSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: ['swords', 'shield', 'crown', 'skull', 'flame', 'scroll'].map((ic) {
                return ChoiceChip(
                  label: Text(ic.toUpperCase()),
                  selected: _iconName == ic,
                  onSelected: (_) => setState(() => _iconName = ic),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _bannerPreset,
              decoration: const InputDecoration(labelText: 'Tema Visual de Capa'),
              items: const [
                DropdownMenuItem(value: 'cidadela_obsidiana', child: Text('Cidadela de Obsidiana')),
                DropdownMenuItem(value: 'masmorra_esmeralda', child: Text('Masmorra Esmeralda')),
                DropdownMenuItem(value: 'deserto_dourado', child: Text('Deserto Dourado')),
              ],
              onChanged: (v) => setState(() => _bannerPreset = v ?? 'cidadela_obsidiana'),
            ),
            const SizedBox(height: 12),
            HeraldicCard(
              goldAccent: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PREVIEW DO CARD', style: TextStyle(fontSize: 10.5, color: p.goldPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    _titleCtrl.text.trim().isEmpty ? 'Titulo da Sua Mesa' : _titleCtrl.text.trim(),
                    style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary),
                  ),
                  Text('Icone: $_iconName · Capa: $_bannerPreset',
                      style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
                ],
              ),
            ),
          ],
          if (_step == 1) ...[
            DropdownButtonFormField<String>(
              initialValue: ctrl.systems.any((s) => s.id == _selectedSystemId)
                  ? _selectedSystemId
                  : 'sys_universal',
              decoration: const InputDecoration(labelText: 'Sistema Base da Mesa'),
              items: [
                const DropdownMenuItem(
                    value: 'sys_universal', child: Text('Motor Universal Livre (Agnostico)')),
                for (final s in ctrl.systems)
                  DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.diceEngine})')),
              ],
              onChanged: (v) => setState(() => _selectedSystemId = v ?? 'sys_universal'),
            ),
            const SizedBox(height: 10),
            Text('Limite de Vagas: $_maxSlots jogadores (1 a 12)'),
            Slider(
              value: _maxSlots.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              onChanged: (v) => setState(() => _maxSlots = v.round()),
            ),
            DropdownButtonFormField<String>(
              initialValue: _ageRating,
              decoration: const InputDecoration(labelText: 'Classificacao Indicativa'),
              items: const ['Livre', '14+', '16+', '18+']
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() => _ageRating = v ?? '16+'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _tagsCtrl,
              decoration: const InputDecoration(labelText: 'Tags (separadas por virgula)'),
            ),
          ],
          if (_step == 2) ...[
            TextField(
              controller: _synopsisCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Sinopse Completa (>= 10 caracteres)'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<CampaignMode>(
              initialValue: _mode,
              decoration: const InputDecoration(labelText: 'Ritmo da Campanha'),
              items: const [
                DropdownMenuItem(value: CampaignMode.aoVivo, child: Text('Ao Vivo (Sincrona)')),
                DropdownMenuItem(value: CampaignMode.tempoLivre, child: Text('Free Time (Assincrona)')),
                DropdownMenuItem(value: CampaignMode.agendada, child: Text('Agendada Semanal')),
              ],
              onChanged: (v) => setState(() => _mode = v ?? CampaignMode.aoVivo),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _scheduleCtrl,
              decoration: const InputDecoration(labelText: 'Horario / Frequencia'),
            ),
          ],
          if (_step == 3) ...[
            SwitchListTile(
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
              title: Text(_isPublic
                  ? 'Campanha Publica (Aparece em Explorar)'
                  : 'Campanha Privada (Apenas Codigo / Convite)'),
            ),
            HeraldicCard(
              goldAccent: true,
              child: Text(
                'Resumo Final:\n'
                'Titulo: ${_titleCtrl.text}\n'
                'Vagas: $_maxSlots · Faixa: $_ageRating\n'
                'Agenda: ${_scheduleCtrl.text}',
                style: TextStyle(fontSize: 13, color: p.textPrimary),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: SecondaryHeraldicButton(
                    label: 'Voltar',
                    onPressed: () => setState(() => _step -= 1),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 8),
              Expanded(
                child: PrimaryGoldPillButton(
                  label: _step < 3
                      ? 'Avancar'
                      : (_creating ? 'Forjando...' : 'Forjar Mesa'),
                  svgIcon: ArcanaSvgIcons.check,
                  expand: true,
                  onPressed: _creating
                      ? null
                      : () async {
                          if (_step < 3) {
                            setState(() => _step += 1);
                            return;
                          }
                          if (_titleCtrl.text.trim().length < 3 ||
                              _synopsisCtrl.text.trim().length < 10) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Titulo (>=3) e sinopse (>=10) obrigatorios.'),
                              ),
                            );
                            return;
                          }
                          setState(() => _creating = true);
                          final nav = Navigator.of(context);
                          final tags = _tagsCtrl.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .take(8)
                              .toList();
                          final created = await ctrl.createCampaign(
                            title: _titleCtrl.text,
                            synopsis: _synopsisCtrl.text,
                            systemId: _selectedSystemId,
                            mode: _mode,
                            scheduleText: _scheduleCtrl.text,
                            maxSlots: _maxSlots,
                            isPublic: _isPublic,
                            iconName: _iconName,
                            bannerPreset: _bannerPreset,
                            ageRating: _ageRating,
                            tags: tags,
                          );
                          if (created != null && nav.mounted) {
                            nav.pop();
                          } else if (mounted) {
                            setState(() => _creating = false);
                          }
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

// =============================================================================
// 3. CANDIDATURA & FILTROS AVANCADOS DE CAMPANHA
// =============================================================================

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
  final _pitchCtrl = TextEditingController();
  bool _sending = false;

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
      title: 'Candidatar-se: ${widget.campaign.title}',
      subtitle: 'Sem ficha previa! Aguarde aprovacao do Mestre (@${widget.campaign.masterHandle})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _pitchCtrl,
            maxLength: 200,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Apresentacao Breve (ate 200 caracteres)',
              hintText: 'Conte seu estilo de jogo e disponibilidade...',
            ),
          ),
          const SizedBox(height: 12),
          PrimaryGoldPillButton(
            label: _sending ? 'Enviando...' : 'Enviar Candidatura ao Mestre',
            svgIcon: ArcanaSvgIcons.check,
            expand: true,
            onPressed: _sending
                ? null
                : () async {
                    if (_pitchCtrl.text.trim().length < 5) return;
                    setState(() => _sending = true);
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await widget.controller.applyToCampaign(
                      campaignId: widget.campaign.id,
                      pitch: _pitchCtrl.text,
                    );
                    if (nav.mounted) {
                      if (ok) {
                        nav.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Candidatura enviada! Aguardando o Mestre.'),
                          ),
                        );
                      } else {
                        setState(() => _sending = false);
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: p.crimson,
                            content: Text(widget.controller.lastSyncError ?? 'Bloqueado.'),
                          ),
                        );
                      }
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class CampaignFiltersModal extends StatefulWidget {
  final CampaignMode? currentModeFilter;
  final String? currentSystemId;
  final String? currentAgeRating;
  final String? currentTag;
  final bool onlyOpenSlots;
  final List<RpgSystem> availableSystems;
  final void Function({
    CampaignMode? mode,
    String? systemId,
    String? ageRating,
    String? tag,
    bool openSlotsOnly,
  }) onApplyFilter;

  const CampaignFiltersModal({
    super.key,
    required this.currentModeFilter,
    this.currentSystemId,
    this.currentAgeRating,
    this.currentTag,
    this.onlyOpenSlots = false,
    this.availableSystems = const [],
    required this.onApplyFilter,
  });

  @override
  State<CampaignFiltersModal> createState() => _CampaignFiltersModalState();
}

class _CampaignFiltersModalState extends State<CampaignFiltersModal> {
  CampaignMode? _mode;
  String? _systemId;
  String? _age;
  late bool _openOnly;
  final _tagCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mode = widget.currentModeFilter;
    _systemId = widget.currentSystemId;
    _age = widget.currentAgeRating;
    _openOnly = widget.onlyOpenSlots;
    _tagCtrl.text = widget.currentTag ?? '';
  }

  @override
  void dispose() {
    _tagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.filter,
      title: 'Filtros Avancados de Mesas',
      subtitle: 'Sistema, Faixa Etaria, Modo, Tag e Vagas Abertas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<CampaignMode?>(
            initialValue: _mode,
            decoration: const InputDecoration(labelText: 'Ritmo da Mesa'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos os Modos')),
              DropdownMenuItem(value: CampaignMode.aoVivo, child: Text('Ao Vivo')),
              DropdownMenuItem(value: CampaignMode.tempoLivre, child: Text('Free Time')),
              DropdownMenuItem(value: CampaignMode.agendada, child: Text('Agendada')),
            ],
            onChanged: (v) => setState(() => _mode = v),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            initialValue: _age,
            decoration: const InputDecoration(labelText: 'Classificacao Indicativa'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Qualquer Faixa')),
              DropdownMenuItem(value: 'Livre', child: Text('Livre')),
              DropdownMenuItem(value: '14+', child: Text('14+')),
              DropdownMenuItem(value: '16+', child: Text('16+')),
              DropdownMenuItem(value: '18+', child: Text('18+')),
            ],
            onChanged: (v) => setState(() => _age = v),
          ),
          const SizedBox(height: 10),
          if (widget.availableSystems.isNotEmpty) ...[
            DropdownButtonFormField<String?>(
              initialValue: _systemId,
              decoration: const InputDecoration(labelText: 'Sistema'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos os Sistemas')),
                for (final s in widget.availableSystems)
                  DropdownMenuItem(value: s.id, child: Text(s.name)),
              ],
              onChanged: (v) => setState(() => _systemId = v),
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: _tagCtrl,
            decoration: const InputDecoration(labelText: 'Filtrar por Tag exata (sem #)'),
          ),
          SwitchListTile(
            value: _openOnly,
            onChanged: (v) => setState(() => _openOnly = v),
            title: const Text('Apenas Mesas com Vagas Disponiveis'),
          ),
          const SizedBox(height: 12),
          PrimaryGoldPillButton(
            label: 'Aplicar Filtros',
            svgIcon: ArcanaSvgIcons.check,
            expand: true,
            onPressed: () {
              widget.onApplyFilter(
                mode: _mode,
                systemId: _systemId,
                ageRating: _age,
                tag: _tagCtrl.text.trim().isEmpty ? null : _tagCtrl.text.trim(),
                openSlotsOnly: _openOnly,
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
