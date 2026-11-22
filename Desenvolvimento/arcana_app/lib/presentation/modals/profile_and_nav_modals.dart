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
import 'campaign_modals.dart';
import 'modal_shell.dart';
import 'universal_report_modal.dart';

// =============================================================================
// 1. NOTIFICACOES & CONVITES DIRETOS
// =============================================================================

class NotificationsModal extends StatefulWidget {
  final AppController controller;

  const NotificationsModal({super.key, required this.controller});

  @override
  State<NotificationsModal> createState() => _NotificationsModalState();
}

class _NotificationsModalState extends State<NotificationsModal> {
  String _filter = 'todas'; // todas | mesas | social | sistema

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final ctrl = widget.controller;
    final filtered = ctrl.notifications.where((n) {
      if (_filter == 'todas') return true;
      return n.category == _filter;
    }).toList();

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.bell,
      title: 'Notificacoes & Convites',
      subtitle: 'Convites diretos de mesa, solicitacoes sociais e alertas',
      badgeLabel: '${ctrl.unreadNotificationsCount} NOVAS',
      badgeColor: ctrl.unreadNotificationsCount > 0 ? p.crimson : p.emerald,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final cat in [
                ('todas', 'Todas'),
                ('mesas', 'Mesas'),
                ('social', 'Social'),
                ('sistema', 'Sistema'),
              ])
                ChoiceChip(
                  label: Text(cat.$2),
                  selected: _filter == cat.$1,
                  onSelected: (_) => setState(() => _filter = cat.$1),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (ctrl.unreadNotificationsCount > 0) ...[
            SecondaryHeraldicButton(
              label: 'Marcar Todas como Lidas',
              svgIcon: ArcanaSvgIcons.check,
              expand: true,
              onPressed: () async {
                await ctrl.markAllNotificationsRead();
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 12),
          ],
          if (filtered.isEmpty)
            HeraldicCard(
              child: Text(
                'Nenhuma notificacao nesta categoria.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: p.textSecondary),
              ),
            )
          else
            for (final n in filtered) ...[
              HeraldicCard(
                goldAccent: !n.isRead || n.inviteId != null,
                onTap: () => ctrl.markNotificationRead(n.id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        HeraldicChipPill(
                          label: n.category.toUpperCase(),
                          color: n.inviteId != null ? p.emerald : p.goldPrimary,
                        ),
                        const Spacer(),
                        Text(
                          n.timeAgo,
                          style: TextStyle(fontSize: 11, color: p.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      n.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      n.body,
                      style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                    ),
                    if (n.inviteId != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryGoldPillButton(
                              label: 'Aceitar Convite',
                              svgIcon: ArcanaSvgIcons.check,
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final ok = await ctrl.acceptCampaignInvite(
                                  n.inviteId!,
                                  accept: true,
                                );
                                await ctrl.markNotificationRead(n.id);
                                if (mounted) {
                                  setState(() {});
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(ok
                                          ? 'Voce ingressou na campanha!'
                                          : (ctrl.lastSyncError ?? 'Erro ao aceitar.')),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          SecondaryHeraldicButton(
                            label: 'Recusar',
                            svgIcon: ArcanaSvgIcons.close,
                            borderColor: p.crimson,
                            textColor: p.crimson,
                            onPressed: () async {
                              await ctrl.acceptCampaignInvite(
                                n.inviteId!,
                                accept: false,
                              );
                              await ctrl.markNotificationRead(n.id);
                              if (mounted) setState(() {});
                            },
                          ),
                        ],
                      ),
                    ] else if (n.campaignId != null && n.campaignCode != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () async {
                            final match = ctrl.campaigns.cast<Campaign?>().firstWhere(
                                  (c) => c?.id == n.campaignId,
                                  orElse: () => null,
                                );
                            if (match != null && mounted) {
                              Navigator.of(context).pop();
                              showArcanaModal(context,
                                builder: (_) => CampaignGeneralModal(
                                  controller: ctrl,
                                  campaign: match,
                                ),
                              );
                            }
                          },
                          child: Text(
                            'Abrir Campanha (${n.campaignCode}) ->',
                            style: TextStyle(color: p.goldHighlight),
                          ),
                        ),
                      ),
                    ],
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
// 2. PERFIL SOCIAL ESTILO DISCORD (ZERO EXPOSICAO DE E-MAIL + 3 ABAS + DRILL-DOWN)
// =============================================================================

class SocialProfileModal extends StatefulWidget {
  final AppController controller;
  final String? targetUserId;
  final String? targetUsername;

  const SocialProfileModal({
    super.key,
    required this.controller,
    this.targetUserId,
    this.targetUsername,
  });

  @override
  State<SocialProfileModal> createState() => _SocialProfileModalState();
}

class _SocialProfileModalState extends State<SocialProfileModal> {
  int _tabIndex = 0; // 0: Sobre Mim | 1: Em Comum | 2: Vitrine da Taverna
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  SocialProfileView? _view;

  late final TextEditingController _userCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _discordCtrl;
  late final TextEditingController _twitchCtrl;
  late final TextEditingController _youtubeCtrl;
  late final TextEditingController _steamCtrl;
  late final TextEditingController _instagramCtrl;
  late final TextEditingController _xTwitterCtrl;
  late final TextEditingController _redditCtrl;
  late final TextEditingController _whatsappCtrl;
  String _selectedAvatar = 'shield';

  bool get _isOwnProfile =>
      (widget.targetUserId == null || widget.targetUserId == widget.controller.currentUser.id) &&
      (widget.targetUsername == null ||
          widget.targetUsername!.replaceAll('@', '').toLowerCase() ==
              widget.controller.currentUser.username.toLowerCase());

  @override
  void initState() {
    super.initState();
    final me = widget.controller.currentUser;
    _userCtrl = TextEditingController(text: me.username);
    _nameCtrl = TextEditingController(text: me.displayName);
    _bioCtrl = TextEditingController(text: me.bio);
    _selectedAvatar = me.avatarIcon;
    _discordCtrl = TextEditingController(text: me.socialContacts['discord'] ?? '');
    _twitchCtrl = TextEditingController(text: me.socialContacts['twitch'] ?? '');
    _youtubeCtrl = TextEditingController(text: me.socialContacts['youtube'] ?? '');
    _steamCtrl = TextEditingController(text: me.socialContacts['steam'] ?? '');
    _instagramCtrl = TextEditingController(text: me.socialContacts['instagram'] ?? '');
    _xTwitterCtrl = TextEditingController(text: me.socialContacts['x_twitter'] ?? '');
    _redditCtrl = TextEditingController(text: me.socialContacts['reddit'] ?? '');
    _whatsappCtrl = TextEditingController(text: me.socialContacts['whatsapp'] ?? '');
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final loaded = await widget.controller.fetchSocialProfile(
      userId: widget.targetUserId,
      username: widget.targetUsername,
    );
    if (!mounted) return;
    setState(() {
      _view = loaded;
      _loading = false;
      if (_isOwnProfile && loaded != null) {
        _userCtrl.text = loaded.username;
        _nameCtrl.text = loaded.displayName;
        _bioCtrl.text = loaded.bio;
        _selectedAvatar = loaded.avatarIcon;
        _discordCtrl.text = loaded.contacts['discord'] ?? '';
        _twitchCtrl.text = loaded.contacts['twitch'] ?? '';
        _youtubeCtrl.text = loaded.contacts['youtube'] ?? '';
        _steamCtrl.text = loaded.contacts['steam'] ?? '';
        _instagramCtrl.text = loaded.contacts['instagram'] ?? '';
        _xTwitterCtrl.text = loaded.contacts['x_twitter'] ?? '';
        _redditCtrl.text = loaded.contacts['reddit'] ?? '';
        _whatsappCtrl.text = loaded.contacts['whatsapp'] ?? '';
      }
    });
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _discordCtrl.dispose();
    _twitchCtrl.dispose();
    _youtubeCtrl.dispose();
    _steamCtrl.dispose();
    _instagramCtrl.dispose();
    _xTwitterCtrl.dispose();
    _redditCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final ctrl = widget.controller;
    final view = _view;

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.user,
      title: view?.displayName ?? (_isOwnProfile ? ctrl.currentUser.displayName : 'Perfil'),
      subtitle: view != null
          ? '@${view.username} · Google OAuth Verificado'
          : 'Carregando identificador...',
      badgeLabel: view?.role.badgeLabel ?? ctrl.currentUser.role.badgeLabel,
      badgeColor: p.goldPrimary,
      child: _loading
          ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecalho Privacidade LGPD: exibe selo Google OAuth Verificado e ID copiavel, NUNCA o e-mail!
                HeraldicCard(
                  goldAccent: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: p.surfaceElevated,
                            child: SvgIconWidget(
                              _avatarSvg(view?.avatarIcon ?? _selectedAvatar),
                              size: 26,
                              color: p.goldHighlight,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  view?.displayName ?? ctrl.currentUser.displayName,
                                  style: TextStyle(
                                    fontFamily: 'Cinzel',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: p.textPrimary,
                                  ),
                                ),
                                Text(
                                  '@${view?.username ?? ctrl.currentUser.username}',
                                  style: TextStyle(fontSize: 12.5, color: p.goldPrimary),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    HeraldicChipPill(
                                      label: 'Google OAuth Verificado',
                                      svgIcon: ArcanaSvgIcons.circleCheck,
                                      color: p.emerald,
                                    ),
                                    RoleBadgeWidget(
                                      role: view?.role ?? ctrl.currentUser.role,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'ID Publico: ${view?.userId ?? ctrl.currentUser.id} (Sigilo de e-mail ativo)',
                              style: TextStyle(fontSize: 11, color: p.textSecondary),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              final id = view?.userId ?? ctrl.currentUser.id;
                              Clipboard.setData(ClipboardData(text: id));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('ID $id copiado.')),
                              );
                            },
                            child: Text('Copiar ID', style: TextStyle(color: p.goldPrimary)),
                          ),
                        ],
                      ),
                      if (!_isOwnProfile && view != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            PrimaryGoldPillButton(
                              label: 'Abrir DM 1-a-1',
                              svgIcon: ArcanaSvgIcons.messageSquare,
                              onPressed: () => showArcanaModal(context,
                                builder: (_) => DirectMessageModal(
                                  controller: ctrl,
                                  peerUserId: view.userId,
                                  peerUsername: view.username,
                                  peerDisplayName: view.displayName,
                                ),
                              ),
                            ),
                            SecondaryHeraldicButton(
                              label: 'Adicionar Amigo',
                              svgIcon: ArcanaSvgIcons.users,
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final err = await ctrl.addFriendByUsername(view.username);
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(err ?? 'Solicitacao enviada para @${view.username}!'),
                                    ),
                                  );
                                }
                              },
                            ),
                            if (ctrl.campaigns
                                .any((c) => c.userRelation == CampaignSegment.mestre))
                              SecondaryHeraldicButton(
                                label: 'Convidar para Mesa',
                                svgIcon: ArcanaSvgIcons.key,
                                onPressed: () => _openInviteCampaignPicker(context, view.userId),
                              ),
                            SecondaryHeraldicButton(
                              label: 'Denunciar',
                              svgIcon: ArcanaSvgIcons.flag,
                              borderColor: p.crimson,
                              textColor: p.crimson,
                              onPressed: () => showArcanaModal(context,
                                builder: (_) => UniversalReportModal(
                                  controller: ctrl,
                                  originType: 'usuario',
                                  originId: view.userId,
                                  targetUserId: view.userId,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                HeraldicSegmentBar(
                  segments: const ['Sobre Mim', 'Em Comum', 'Vitrine da Taverna'],
                  selectedIndex: _tabIndex,
                  onSelected: (i) => setState(() => _tabIndex = i),
                ),
                const SizedBox(height: 12),

                if (_tabIndex == 0) _buildAboutTab(context, p, ctrl, view),
                if (_tabIndex == 1) _buildMutualTab(context, p, ctrl, view),
                if (_tabIndex == 2) _buildShowcaseTab(context, p, view),
              ],
            ),
    );
  }

  String _avatarSvg(String key) {
    switch (key) {
      case 'crown':
        return ArcanaSvgIcons.crown;
      case 'swords':
        return ArcanaSvgIcons.swords;
      case 'skull':
        return ArcanaSvgIcons.skull;
      case 'flame':
        return ArcanaSvgIcons.flame;
      case 'scroll':
        return ArcanaSvgIcons.scroll;
      default:
        return ArcanaSvgIcons.shield;
    }
  }

  Widget _buildAboutTab(
    BuildContext context,
    ArcanaPalette p,
    AppController ctrl,
    SocialProfileView? view,
  ) {
    final contacts = view?.contacts ?? ctrl.currentUser.socialContacts;

    if (!_isOwnProfile || !_editing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeraldicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biografia de Aventureiro',
                  style: TextStyle(fontWeight: FontWeight.w700, color: p.goldHighlight),
                ),
                const SizedBox(height: 6),
                Text(
                  (view?.bio ?? '').isEmpty
                      ? 'Nenhuma biografia escrita ainda.'
                      : view!.bio,
                  style: TextStyle(fontSize: 13, color: p.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          HeraldicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contatos Sociais Externos',
                  style: TextStyle(fontWeight: FontWeight.w700, color: p.goldHighlight),
                ),
                const SizedBox(height: 8),
                if (contacts.isEmpty)
                  Text(
                    'Nenhum contato externo vinculado.',
                    style: TextStyle(fontSize: 12, color: p.textSecondary),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: contacts.entries
                        .where((e) => e.value.trim().isNotEmpty)
                        .map((e) => ActionChip(
                              label: Text('${e.key.toUpperCase()}: ${e.value}'),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: e.value));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${e.key}: ${e.value} copiado!')),
                                );
                              },
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
          if (_isOwnProfile) ...[
            const SizedBox(height: 12),
            PrimaryGoldPillButton(
              label: 'Editar Perfil & 8 Contatos',
              svgIcon: ArcanaSvgIcons.feather,
              expand: true,
              onPressed: () => setState(() => _editing = true),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Brasao / Avatar:',
          style: TextStyle(fontSize: 12, color: p.textSecondary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: ['shield', 'swords', 'crown', 'skull', 'flame', 'scroll'].map((k) {
            final selected = _selectedAvatar == k;
            return ChoiceChip(
              label: SvgIconWidget(
                _avatarSvg(k),
                size: 16,
                color: selected ? p.goldHighlight : p.textSecondary,
              ),
              selected: selected,
              onSelected: (_) => setState(() => _selectedAvatar = k),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _userCtrl,
          decoration: const InputDecoration(labelText: '@username unico'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Nome de Exibicao'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bioCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Biografia'),
        ),
        const SizedBox(height: 12),
        Text(
          '8 Contatos Sociais Opcionais:',
          style: TextStyle(fontWeight: FontWeight.w700, color: p.goldHighlight),
        ),
        const SizedBox(height: 8),
        TextField(controller: _discordCtrl, decoration: const InputDecoration(labelText: 'Discord')),
        const SizedBox(height: 6),
        TextField(controller: _twitchCtrl, decoration: const InputDecoration(labelText: 'Twitch')),
        const SizedBox(height: 6),
        TextField(controller: _youtubeCtrl, decoration: const InputDecoration(labelText: 'YouTube')),
        const SizedBox(height: 6),
        TextField(controller: _steamCtrl, decoration: const InputDecoration(labelText: 'Steam')),
        const SizedBox(height: 6),
        TextField(controller: _instagramCtrl, decoration: const InputDecoration(labelText: 'Instagram')),
        const SizedBox(height: 6),
        TextField(controller: _xTwitterCtrl, decoration: const InputDecoration(labelText: 'X / Twitter')),
        const SizedBox(height: 6),
        TextField(controller: _redditCtrl, decoration: const InputDecoration(labelText: 'Reddit')),
        const SizedBox(height: 6),
        TextField(controller: _whatsappCtrl, decoration: const InputDecoration(labelText: 'WhatsApp')),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SecondaryHeraldicButton(
                label: 'Cancelar',
                onPressed: () => setState(() => _editing = false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PrimaryGoldPillButton(
                label: _saving ? 'Salvando...' : 'Salvar Perfil',
                svgIcon: ArcanaSvgIcons.check,
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        final ok = await ctrl.updateProfile(
                          username: _userCtrl.text,
                          displayName: _nameCtrl.text,
                          bio: _bioCtrl.text,
                          avatarIcon: _selectedAvatar,
                          contacts: {
                            'discord': _discordCtrl.text,
                            'twitch': _twitchCtrl.text,
                            'youtube': _youtubeCtrl.text,
                            'steam': _steamCtrl.text,
                            'instagram': _instagramCtrl.text,
                            'x_twitter': _xTwitterCtrl.text,
                            'reddit': _redditCtrl.text,
                            'whatsapp': _whatsappCtrl.text,
                          },
                        );
                        if (mounted) {
                          setState(() {
                            _saving = false;
                            if (ok) _editing = false;
                          });
                          if (ok) _loadProfile();
                        }
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMutualTab(
    BuildContext context,
    ArcanaPalette p,
    AppController ctrl,
    SocialProfileView? view,
  ) {
    final mutual = view?.mutualCampaigns ?? const [];
    final friendsInCommon = _isOwnProfile
        ? ctrl.friends.where((f) => f.status == 'accepted').length
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeraldicCard(
          child: Text(
            _isOwnProfile
                ? 'Voce possui $friendsInCommon aliados confirmados e ${ctrl.campaigns.where((c) => c.userRelation != CampaignSegment.explorar).length} mesas ativas.'
                : mutual.isEmpty
                    ? 'Voces ainda nao compartilham campanhas ativas.'
                    : 'Campanhas em comum (${mutual.length}):',
            style: TextStyle(fontSize: 13, color: p.textPrimary),
          ),
        ),
        const SizedBox(height: 8),
        for (final m in mutual)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: HeraldicCard(
              child: Row(
                children: [
                  SvgIconWidget(ArcanaSvgIcons.swords, size: 18, color: p.goldPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (m['title'] as String?) ?? 'Campanha',
                      style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary),
                    ),
                  ),
                  HeraldicChipPill(
                    label: (m['mode'] as String?)?.toUpperCase() ?? 'ATIVA',
                    color: p.emerald,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildShowcaseTab(
    BuildContext context,
    ArcanaPalette p,
    SocialProfileView? view,
  ) {
    if (view == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _metricTile(
              p,
              'Jogando',
              '${view.campaignsAsPlayer}',
              () => _showDrillDown(
                context,
                'Campanhas Participadas (${view.campaignsList.length})',
                view.campaignsList.map((c) => c['title']?.toString() ?? 'Mesa').toList(),
              ),
            ),
            const SizedBox(width: 8),
            _metricTile(
              p,
              'Mestrando',
              '${view.campaignsAsMaster}',
              () => _showDrillDown(
                context,
                'Campanhas como Mestre',
                view.campaignsList
                    .where((c) => c['owner_id'] == view.userId)
                    .map((c) => c['title']?.toString() ?? 'Mesa')
                    .toList(),
              ),
            ),
            const SizedBox(width: 8),
            _metricTile(
              p,
              'Fichas',
              '${view.charactersCount}',
              () => _showDrillDown(
                context,
                'Personagens (${view.charactersList.length})',
                view.charactersList
                    .map((ch) => '${ch['name']} (${ch['title']}, Nv.${ch['level']})')
                    .toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Maestria em Sistemas (Toque para detalhes):',
          style: TextStyle(fontWeight: FontWeight.w700, color: p.goldHighlight),
        ),
        const SizedBox(height: 8),
        if (view.systemsRanked.isEmpty)
          HeraldicCard(
            child: Text(
              'Nenhuma campanha vinculada a sistemas ainda.',
              style: TextStyle(fontSize: 12, color: p.textSecondary),
            ),
          )
        else
          for (final s in view.systemsRanked)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: HeraldicCard(
                onTap: () => _showDrillDown(
                  context,
                  s['system_name']?.toString() ?? 'Sistema',
                  [
                    'Patente: ${s['experience_tier']}',
                    'Campanhas registradas: ${s['campaigns_count']}',
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s['system_name']?.toString() ?? 'Sistema',
                        style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary),
                      ),
                    ),
                    HeraldicChipPill(
                      label: '${s['experience_tier']} (${s['campaigns_count']})',
                      color: p.goldPrimary,
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _metricTile(
    ArcanaPalette p,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: HeraldicCard(
        onTap: onTap,
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: p.goldHighlight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: p.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _showDrillDown(BuildContext context, String title, List<String> lines) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: lines.isEmpty
            ? const Text('Nenhum registro detalhado disponivel.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: lines.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('- $l'),
                )).toList(),
              ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
        ],
      ),
    );
  }

  Future<void> _openInviteCampaignPicker(BuildContext context, String targetUserId) async {
    final owned = widget.controller.campaigns
        .where((c) => c.userRelation == CampaignSegment.mestre)
        .toList();
    if (owned.isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Convidar para Qual Campanha?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: owned
              .map((c) => ListTile(
                    title: Text(c.title),
                    subtitle: Text('${c.occupiedSlots}/${c.maxSlots} vagas'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final ok = await widget.controller
                          .invitePlayerToCampaign(c.id, targetUserId);
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? 'Convite direto enviado para "${c.title}"!'
                                : (widget.controller.lastSyncError ?? 'Falha ao convidar.')),
                          ),
                        );
                      }
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// =============================================================================
// 3. MENSAGENS DIRETAS PRIVADAS 1-A-1 (DM ISOLADA + ROLAGEM PRIVADA)
// =============================================================================

class DirectMessageModal extends StatefulWidget {
  final AppController controller;
  final String peerUserId;
  final String peerUsername;
  final String peerDisplayName;

  const DirectMessageModal({
    super.key,
    required this.controller,
    required this.peerUserId,
    required this.peerUsername,
    required this.peerDisplayName,
  });

  @override
  State<DirectMessageModal> createState() => _DirectMessageModalState();
}

class _DirectMessageModalState extends State<DirectMessageModal> {
  final _msgCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.controller.fetchDmMessages(widget.peerUserId).whenComplete(() {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _rollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final ctrl = widget.controller;
    final msgs = ctrl.dmThreads[widget.peerUserId] ?? const [];

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.messageSquare,
      title: 'DM: ${widget.peerDisplayName}',
      subtitle: 'Canal 1-a-1 isolado (@${widget.peerUsername})',
      badgeLabel: 'PRIVADO',
      badgeColor: p.infoBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 290,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : msgs.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhuma mensagem direta com @${widget.peerUsername} ainda.',
                          style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: msgs.length,
                        itemBuilder: (context, idx) {
                          final m = msgs[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: m.isMine ? p.bubbleOutgoing : p.bubbleIncoming,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: p.subtleBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      m.senderHandle,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11.5,
                                        color: p.goldHighlight,
                                      ),
                                    ),
                                    Text(
                                      m.timeText,
                                      style: TextStyle(fontSize: 10.5, color: p.textSecondary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(m.content, style: TextStyle(fontSize: 13, color: p.textPrimary)),
                                if (m.diceRoll != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Dados (${m.diceRoll!.expression}): ${m.diceRoll!.dice} -> ${m.diceRoll!.outcome}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: p.emerald,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _msgCtrl,
                  decoration: const InputDecoration(hintText: 'Mensagem privada...'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _rollCtrl,
                  decoration: const InputDecoration(hintText: 'Dado (1d20)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PrimaryGoldPillButton(
                  label: 'Enviar DM',
                  svgIcon: ArcanaSvgIcons.check,
                  expand: true,
                  onPressed: () async {
                    if (_msgCtrl.text.trim().isEmpty && _rollCtrl.text.trim().isEmpty) {
                      return;
                    }
                    final content = _msgCtrl.text.trim().isEmpty
                        ? 'Rolagem privada (${_rollCtrl.text.trim()})'
                        : _msgCtrl.text.trim();
                    final messenger = ScaffoldMessenger.of(context);
                    final rollExpr = _rollCtrl.text.trim();
                    _msgCtrl.clear();
                    _rollCtrl.clear();
                    final ok = await ctrl.sendDmMessage(
                      peerUserId: widget.peerUserId,
                      content: content,
                      rollExpression: rollExpr,
                    );
                    if (mounted) {
                      setState(() {});
                      if (!ok) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(ctrl.lastSyncError ?? 'Bloqueado.')),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              SecondaryHeraldicButton(
                label: 'Denunciar DM',
                svgIcon: ArcanaSvgIcons.flag,
                borderColor: p.crimson,
                textColor: p.crimson,
                onPressed: () => showArcanaModal(context,
                  builder: (_) => UniversalReportModal(
                    controller: ctrl,
                    originType: 'dm',
                    originId: 'dm:${widget.peerUserId}',
                    targetUserId: widget.peerUserId,
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

// =============================================================================
// 4. AMIGOS & SOLICITACOES (3 ABAS + ATALHOS DM / PERFIL)
// =============================================================================

class FriendsManagementModal extends StatefulWidget {
  final AppController controller;

  const FriendsManagementModal({super.key, required this.controller});

  @override
  State<FriendsManagementModal> createState() => _FriendsManagementModalState();
}

class _FriendsManagementModalState extends State<FriendsManagementModal> {
  final _addCtrl = TextEditingController();
  int _tab = 0; // 0: Confirmados | 1: Recebidas | 2: Bloqueados

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final ctrl = widget.controller;
    final accepted = ctrl.friends.where((f) => f.status == 'accepted').toList();
    final pending = ctrl.friends.where((f) => f.status == 'pending').toList();
    final blocked = ctrl.friends.where((f) => f.status == 'blocked').toList();
    final list = _tab == 0 ? accepted : (_tab == 1 ? pending : blocked);

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.users,
      title: 'Aliados & Mensagens Diretas',
      subtitle: 'Gerencie amizades, aceite pedidos e abra chats 1-a-1',
      badgeLabel: '${accepted.length} ALIADOS',
      badgeColor: p.emerald,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Adicionar por @username...',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PrimaryGoldPillButton(
                label: 'Enviar',
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final err = await ctrl.addFriendByUsername(_addCtrl.text);
                  _addCtrl.clear();
                  if (mounted) {
                    setState(() {});
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(err ?? 'Solicitacao de amizade registrada!'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          HeraldicSegmentBar(
            segments: [
              'Confirmados (${accepted.length})',
              'Pendentes (${pending.length})',
              'Bloqueados (${blocked.length})',
            ],
            selectedIndex: _tab,
            onSelected: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            HeraldicCard(
              child: Text(
                'Nenhum registro nesta aba.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: p.textSecondary),
              ),
            )
          else
            for (final f in list) ...[
              HeraldicCard(
                onTap: () => showArcanaModal(context,
                  builder: (_) => SocialProfileModal(
                    controller: ctrl,
                    targetUserId: f.id,
                    targetUsername: f.username,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: p.surfaceElevated,
                      child: SvgIconWidget(ArcanaSvgIcons.user, size: 18, color: p.goldHighlight),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.displayName,
                            style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary),
                          ),
                          Text(
                            '@${f.username} · ${f.activity}',
                            style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (_tab == 1) ...[
                      IconButton(
                        tooltip: 'Aceitar',
                        onPressed: () async {
                          await ctrl.respondFriendRequest(f.id, 'accept');
                          if (mounted) setState(() {});
                        },
                        icon: SvgIconWidget(ArcanaSvgIcons.check, size: 18, color: p.emerald),
                      ),
                      IconButton(
                        tooltip: 'Recusar',
                        onPressed: () async {
                          await ctrl.respondFriendRequest(f.id, 'reject');
                          if (mounted) setState(() {});
                        },
                        icon: SvgIconWidget(ArcanaSvgIcons.close, size: 18, color: p.crimson),
                      ),
                    ] else if (_tab == 0) ...[
                      SecondaryHeraldicButton(
                        label: 'DM',
                        svgIcon: ArcanaSvgIcons.messageSquare,
                        onPressed: () => showArcanaModal(context,
                          builder: (_) => DirectMessageModal(
                            controller: ctrl,
                            peerUserId: f.id,
                            peerUsername: f.username,
                            peerDisplayName: f.displayName,
                          ),
                        ),
                      ),
                    ] else ...[
                      TextButton(
                        onPressed: () async {
                          await ctrl.respondFriendRequest(f.id, 'remove');
                          if (mounted) setState(() {});
                        },
                        child: Text('Desbloquear', style: TextStyle(color: p.goldPrimary)),
                      ),
                    ],
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
// 5. CENTRAL DE TUTORIAIS INTERATIVOS SANDBOX
// =============================================================================

class TutorialsCentralModal extends StatefulWidget {
  final AppController controller;

  const TutorialsCentralModal({super.key, required this.controller});

  @override
  State<TutorialsCentralModal> createState() => _TutorialsCentralModalState();
}

class _TutorialsCentralModalState extends State<TutorialsCentralModal> {
  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final tutorials = widget.controller.tutorials;
    final doneCount = tutorials.where((t) => t.completed).length;

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.book,
      title: 'Central de Tutoriais Guiados',
      subtitle: 'Ambiente Sandbox Local: pratique os 5 modulos sem alterar dados no D1',
      badgeLabel: '$doneCount/${tutorials.length} CONCLUIDOS',
      badgeColor: p.emerald,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeraldicCard(
            borderColor: p.infoBlue,
            child: Row(
              children: [
                SvgIconWidget(ArcanaSvgIcons.shield, size: 22, color: p.infoBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AMBIENTE SANDBOXED OFFLINE: treine rolagens, gatilhos e RoleGate livremente.',
                    style: TextStyle(fontSize: 12, color: p.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final t in tutorials) ...[
            HeraldicCard(
              goldAccent: t.completed,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: t.completed
                          ? p.emerald.withValues(alpha: 0.16)
                          : p.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: t.completed ? p.emerald : p.goldBorder,
                      ),
                    ),
                    child: SvgIconWidget(
                      t.completed ? ArcanaSvgIcons.check : ArcanaSvgIcons.bookOpen,
                      size: 18,
                      color: t.completed ? p.emerald : p.goldPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(t.subtitle, style: TextStyle(fontSize: 12, color: p.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SecondaryHeraldicButton(
                    label: t.completed ? 'Revisar' : 'Iniciar',
                    onPressed: () => showArcanaModal(context,
                      builder: (_) => _InteractiveTutorialRunnerModal(
                        tutorial: t,
                        onComplete: () {
                          widget.controller
                              .toggleTutorialCompleted(t.id, forceDone: true);
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  ),
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

class _InteractiveTutorialRunnerModal extends StatefulWidget {
  final TutorialModule tutorial;
  final VoidCallback onComplete;

  const _InteractiveTutorialRunnerModal({
    required this.tutorial,
    required this.onComplete,
  });

  @override
  State<_InteractiveTutorialRunnerModal> createState() =>
      _InteractiveTutorialRunnerModalState();
}

class _InteractiveTutorialRunnerModalState
    extends State<_InteractiveTutorialRunnerModal> {
  int _step = 0;
  bool _actionTested = false;

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final steps = [
      '1. Conceito Central: ${widget.tutorial.subtitle}',
      '2. Simulacao Sandbox: clique abaixo para testar o comportamento em ambiente isolado.',
      '3. Conclusao: pronto para aplicar nas campanhas reais!',
    ];

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.sparkles,
      title: widget.tutorial.title,
      subtitle: 'Passo ${_step + 1} de ${steps.length} (Sandbox)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeraldicCard(
            goldAccent: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  steps[_step],
                  style: TextStyle(fontSize: 14, color: p.textPrimary),
                ),
                if (_step == 1) ...[
                  const SizedBox(height: 12),
                  SecondaryHeraldicButton(
                    label: _actionTested
                        ? 'Simulacao Validada!'
                        : 'Executar Acao Sandbox (/roll 2d20kh1)',
                    svgIcon: ArcanaSvgIcons.dices,
                    borderColor: _actionTested ? p.emerald : null,
                    textColor: _actionTested ? p.emerald : null,
                    onPressed: () => setState(() => _actionTested = true),
                  ),
                ],
              ],
            ),
          ),
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
                  label: _step < 2 ? 'Proximo Passo' : 'Concluir Modulo',
                  svgIcon: ArcanaSvgIcons.check,
                  expand: true,
                  onPressed: () {
                    if (_step < 2) {
                      setState(() => _step += 1);
                    } else {
                      widget.onComplete();
                      Navigator.of(context).pop();
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
// 6. CONFIGURACOES GERAIS (SEM ROLE SWITCHER FAKE + LOCKOUT CONFIRMATION SUBMODAL)
// =============================================================================

class GeneralSettingsModal extends StatefulWidget {
  final AppController controller;

  const GeneralSettingsModal({super.key, required this.controller});

  @override
  State<GeneralSettingsModal> createState() => _GeneralSettingsModalState();
}

class _GeneralSettingsModalState extends State<GeneralSettingsModal> {
  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final ctrl = widget.controller;

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.settings,
      title: 'Configuracoes Gerais & P2P',
      subtitle: 'Preferencias persistidas em keystore local',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Aparencia & Acessibilidade',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.w700,
              color: p.goldHighlight,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<ArcanaThemeMode>(
            initialValue: ctrl.themeMode,
            decoration: const InputDecoration(labelText: 'Tema da Taverna'),
            items: const [
              DropdownMenuItem(
                  value: ArcanaThemeMode.escuroHeraldico, child: Text('Escuro Heraldico')),
              DropdownMenuItem(value: ArcanaThemeMode.oled, child: Text('OLED Puro')),
              DropdownMenuItem(
                  value: ArcanaThemeMode.altoContrasteSolar,
                  child: Text('Alto Contraste Solar')),
            ],
            onChanged: (v) async {
              if (v != null) {
                await ctrl.setThemeMode(v);
                if (mounted) setState(() {});
              }
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: ctrl.appLanguage,
            decoration: const InputDecoration(labelText: 'Idioma da Interface'),
            items: const ['PT-BR', 'EN-US', 'ES-ES']
                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                ctrl.setAppLanguage(v);
                setState(() {});
              }
            },
          ),
          const SizedBox(height: 10),
          Text('Escala de Fonte: ${(ctrl.fontScale * 100).round()}%'),
          Slider(
            value: ctrl.fontScale,
            min: 0.85,
            max: 1.45,
            divisions: 6,
            onChanged: (v) {
              ctrl.setFontScale(v);
              setState(() {});
            },
          ),
          SwitchListTile(
            value: ctrl.reduceMotion,
            onChanged: (v) {
              ctrl.setReduceMotion(v);
              setState(() {});
            },
            title: const Text('Reduzir Animacoes de Transicao'),
          ),
          const SizedBox(height: 10),
          Text(
            'Mixer de Audio (4 Canais)',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.w700,
              color: p.goldHighlight,
            ),
          ),
          _audioSlider('Geral (${(ctrl.audioMixer.masterVolume * 100).round()}%)',
              ctrl.audioMixer.masterVolume, (v) {
            ctrl.updateAudioMixer(ctrl.audioMixer.copyWith(masterVolume: v));
            setState(() {});
          }),
          _audioSlider('Ambiente (${(ctrl.audioMixer.ambienceVolume * 100).round()}%)',
              ctrl.audioMixer.ambienceVolume, (v) {
            ctrl.updateAudioMixer(ctrl.audioMixer.copyWith(ambienceVolume: v));
            setState(() {});
          }),
          _audioSlider('Efeitos SFX (${(ctrl.audioMixer.sfxVolume * 100).round()}%)',
              ctrl.audioMixer.sfxVolume, (v) {
            ctrl.updateAudioMixer(ctrl.audioMixer.copyWith(sfxVolume: v));
            setState(() {});
          }),
          _audioSlider('Voz (${(ctrl.audioMixer.voiceVolume * 100).round()}%)',
              ctrl.audioMixer.voiceVolume, (v) {
            ctrl.updateAudioMixer(ctrl.audioMixer.copyWith(voiceVolume: v));
            setState(() {});
          }),
          SwitchListTile(
            value: ctrl.muteInBackground,
            onChanged: (v) {
              ctrl.setMuteInBackground(v);
              setState(() {});
            },
            title: const Text('Silenciar em Segundo Plano'),
          ),
          const SizedBox(height: 10),
          Text(
            'Malha P2P & Privacidade Social',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.w700,
              color: p.goldHighlight,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: ['500 MB', '1 GB', '2 GB', 'Sem Limite'].contains(ctrl.p2pCacheQuota)
                ? ctrl.p2pCacheQuota
                : '1 GB',
            decoration: const InputDecoration(labelText: 'Cota Maxima de Cache P2P'),
            items: const ['500 MB', '1 GB', '2 GB', 'Sem Limite']
                .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                ctrl.setP2pCacheQuota(v);
                setState(() {});
              }
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: [
              'Qualquer usuario',
              'Apenas membros de mesas em comum',
              'Apenas amigos',
            ].contains(ctrl.dmPrivacy)
                ? ctrl.dmPrivacy
                : 'Qualquer usuario',
            decoration: const InputDecoration(labelText: 'Quem Pode Enviar DMs 1-a-1'),
            items: const [
              'Qualquer usuario',
              'Apenas membros de mesas em comum',
              'Apenas amigos',
            ].map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
            onChanged: (v) {
              if (v != null) {
                ctrl.setDmPrivacy(v);
                setState(() {});
              }
            },
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: ctrl.externalMediaOnlyOfficial,
            onChanged: (v) {
              ctrl.setExternalMediaOnlyOfficial(v);
              setState(() {});
            },
            title: const Text('Restringir Midias Externas apenas a Sistemas Oficiais'),
          ),
          SecondaryHeraldicButton(
            label: 'Limpar Cache Local P2P (${ctrl.p2pCacheMb} MB)',
            svgIcon: ArcanaSvgIcons.trash,
            expand: true,
            onPressed: () {
              ctrl.clearP2pCache();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          SecondaryHeraldicButton(
            label: 'Acionar Lockout Total de Emergencia',
            svgIcon: ArcanaSvgIcons.lock,
            borderColor: p.crimson,
            textColor: p.crimson,
            expand: true,
            onPressed: () => _confirmTotalLockout(context, ctrl),
          ),
        ],
      ),
    );
  }

  Widget _audioSlider(String label, double val, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Slider(value: val, min: 0, max: 1, onChanged: onChanged),
      ],
    );
  }

  Future<void> _confirmTotalLockout(BuildContext context, AppController ctrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Lockout Total de Emergencia?'),
        content: const Text(
          'Esta acao revogara IMEDIATAMENTE todas as sessoes ativas no Cloudflare e bloqueara sua conta ate o desbloqueio por codigo de 6 digitos enviado ao seu e-mail Google.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('BLOQUEAR CONTA AGORA', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop();
      await ctrl.triggerTotalLockout();
    }
  }
}

// =============================================================================
// 7. PAINEL ADMIN ZERO-TRUST (5 SUBMODULOS: COLEGIADO 3 ADMINS, KEYS, GHOST, DM AUDIT)
// =============================================================================

class AdminGovernanceModal extends StatefulWidget {
  final AppController controller;

  const AdminGovernanceModal({super.key, required this.controller});

  @override
  State<AdminGovernanceModal> createState() => _AdminGovernanceModalState();
}

class _AdminGovernanceModalState extends State<AdminGovernanceModal> {
  int _moduleIdx = 0; // 0: Telemetria | 1: Denuncias | 2: Usuarios & Keys | 3: Ghost | 4: Superadmin
  final _dmUserACtrl = TextEditingController();
  final _dmUserBCtrl = TextEditingController();
  List<ChatMessage> _auditedDms = [];

  @override
  void dispose() {
    _dmUserACtrl.dispose();
    _dmUserBCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final ctrl = widget.controller;
    final isSuperadmin = ctrl.currentUser.role == UserRole.superadmin;

    if (!RbacGuard.canAccessAdminPanel(ctrl.currentUser.role)) {
      return ArcanaModalScaffold(
        svgIcon: ArcanaSvgIcons.lock,
        title: 'Acesso Negado (RBAC)',
        subtitle: 'Modulo restrito a Admin/Superadmin',
        child: Text(
          'Permissao insuficiente.',
          style: TextStyle(color: p.crimson),
        ),
      );
    }

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.shield,
      title: 'Governanca Admin Zero-Trust',
      subtitle: '5 Submodulos Oficiais · Votacao Colegiada & Keys',
      badgeLabel: isSuperadmin ? 'SUPERADMIN' : 'ADMIN',
      badgeColor: p.crimson,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in [
                  (0, 'Telemetria'),
                  (1, 'Denuncias (${ctrl.reports.length})'),
                  (2, 'Usuarios, Ban & Keys'),
                  (3, 'Fantasma'),
                  if (isSuperadmin) (4, 'Superadmin & DMs'),
                ]) ...[
                  ChoiceChip(
                    label: Text(item.$2),
                    selected: _moduleIdx == item.$1,
                    onSelected: (_) => setState(() => _moduleIdx = item.$1),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_moduleIdx == 0) _buildTelemetry(p, ctrl),
          if (_moduleIdx == 1) _buildReportsQueue(context, p, ctrl, isSuperadmin),
          if (_moduleIdx == 2) _buildUsersAndKeys(context, p, ctrl, isSuperadmin),
          if (_moduleIdx == 3) _buildGhostModule(p, ctrl),
          if (_moduleIdx == 4 && isSuperadmin) _buildSuperadminAudit(p, ctrl),
        ],
      ),
    );
  }

  Widget _buildTelemetry(ArcanaPalette p, AppController ctrl) {
    return HeraldicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saude Cloudflare Edge & D1',
            style: TextStyle(fontWeight: FontWeight.w700, color: p.goldHighlight),
          ),
          const SizedBox(height: 8),
          Text('Usuarios registrados: ${ctrl.adminUsers.length}'),
          Text('Campanhas ativas: ${ctrl.campaigns.length}'),
          Text('Sistemas cadastrados: ${ctrl.systems.length}'),
          Text('Denuncias pendentes: ${ctrl.reports.where((r) => r.status == 'pending').length}'),
          Text('Dispositivos em Hardware Ban: ${ctrl.bannedDevices.length}'),
        ],
      ),
    );
  }

  Widget _buildReportsQueue(
    BuildContext context,
    ArcanaPalette p,
    AppController ctrl,
    bool isSuperadmin,
  ) {
    if (ctrl.reports.isEmpty) {
      return HeraldicCard(
        child: Text(
          'Fila de denuncias limpa.',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        for (final r in ctrl.reports) ...[
          HeraldicCard(
            borderColor: r.status == 'pending' ? p.crimson : p.emerald,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HeraldicChipPill(
                      label: r.entityType.toUpperCase(),
                      color: p.crimson,
                    ),
                    const SizedBox(width: 6),
                    HeraldicChipPill(
                      label: '${r.status.toUpperCase()} (${r.votesCount}/${r.requiredVotes})',
                      color: r.status == 'pending' ? p.goldPrimary : p.emerald,
                    ),
                    const Spacer(),
                    Text(r.createdAtText,
                        style: TextStyle(fontSize: 11, color: p.textSecondary)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(r.reasonCategory,
                    style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
                Text(r.description, style: TextStyle(fontSize: 12.5, color: p.textSecondary)),
                if (r.status == 'pending') ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      SecondaryHeraldicButton(
                        label: 'Advertencia',
                        onPressed: () => ctrl.moderateReport(
                          reportId: r.id,
                          decision: 'warning',
                        ),
                      ),
                      SecondaryHeraldicButton(
                        label: 'Suspender 24h',
                        onPressed: () => ctrl.moderateReport(
                          reportId: r.id,
                          decision: 'suspend_24h',
                        ),
                      ),
                      SecondaryHeraldicButton(
                        label: 'Suspender 7d',
                        onPressed: () => ctrl.moderateReport(
                          reportId: r.id,
                          decision: 'suspend_7d',
                        ),
                      ),
                      SecondaryHeraldicButton(
                        label: isSuperadmin
                            ? 'Hardware Ban (Imediato)'
                            : 'Votar Hardware Ban (${r.votesCount}/3)',
                        borderColor: p.crimson,
                        textColor: p.crimson,
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final msg = await ctrl.moderateReport(
                            reportId: r.id,
                            decision: 'hardware_ban',
                            applyHardwareBan: true,
                          );
                          if (mounted && msg != null) {
                            messenger.showSnackBar(SnackBar(content: Text(msg)));
                          }
                        },
                      ),
                      SecondaryHeraldicButton(
                        label: 'Dispensar',
                        onPressed: () => ctrl.moderateReport(
                          reportId: r.id,
                          decision: 'dismissed',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildUsersAndKeys(
    BuildContext context,
    ArcanaPalette p,
    AppController ctrl,
    bool isSuperadmin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryGoldPillButton(
          label: 'Gerar Key de Criacao de Sistema (KEY-ARC)',
          svgIcon: ArcanaSvgIcons.key,
          expand: true,
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final key = await ctrl.adminGenerateCreationKey();
            if (mounted && key != null) {
              messenger.showSnackBar(
                SnackBar(content: Text('Key gerada: ${key.code}')),
              );
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 10),
        for (final k in ctrl.systemCreationKeys.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: HeraldicCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      k.code,
                      style: TextStyle(fontWeight: FontWeight.w700, color: p.goldHighlight),
                    ),
                  ),
                  HeraldicChipPill(
                    label: k.isUsed ? 'USADA' : 'DISPONIVEL',
                    color: k.isUsed ? p.textSecondary : p.emerald,
                  ),
                  IconButton(
                    onPressed: () => Clipboard.setData(ClipboardData(text: k.code)),
                    icon: const Icon(Icons.copy, size: 16),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Contas & Sigilo (E-mail Google visivel apenas no Painel Admin):',
          style: TextStyle(fontWeight: FontWeight.w700, color: p.goldPrimary),
        ),
        const SizedBox(height: 8),
        for (final u in ctrl.adminUsers) ...[
          HeraldicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${u.displayName} (@${u.username})',
                        style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary),
                      ),
                    ),
                    RoleBadgeWidget(role: u.role),
                  ],
                ),
                Text(
                  'Email Google: ${u.email} · Status: ${u.accountStatus}',
                  style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                ),
                if (u.suspendedUntil != null)
                  Text(
                    'Suspenso ate: ${u.suspendedUntil}',
                    style: TextStyle(fontSize: 11.5, color: p.crimson),
                  ),
                if (u.role != UserRole.superadmin) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      SecondaryHeraldicButton(
                        label: 'Jogador',
                        onPressed: () => ctrl.adminUpdateUserRole(
                          targetUserId: u.id,
                          newRole: UserRole.jogador,
                        ),
                      ),
                      SecondaryHeraldicButton(
                        label: 'Mestre',
                        onPressed: () => ctrl.adminUpdateUserRole(
                          targetUserId: u.id,
                          newRole: UserRole.mestre,
                        ),
                      ),
                      if (isSuperadmin)
                        SecondaryHeraldicButton(
                          label: 'Admin',
                          borderColor: p.crimson,
                          textColor: p.crimson,
                          onPressed: () => ctrl.adminUpdateUserRole(
                            targetUserId: u.id,
                            newRole: UserRole.admin,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (ctrl.bannedDevices.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Hardware Ban Ativos (Desbanimento Manual):',
            style: TextStyle(fontWeight: FontWeight.w700, color: p.crimson),
          ),
          const SizedBox(height: 6),
          for (final dev in ctrl.bannedDevices)
            HeraldicCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dev.deviceFingerprint,
                            style: TextStyle(fontSize: 12, color: p.textPrimary)),
                        Text(dev.banReason,
                            style: TextStyle(fontSize: 11, color: p.crimson)),
                      ],
                    ),
                  ),
                  SecondaryHeraldicButton(
                    label: 'Desbanir',
                    onPressed: () async {
                      await ctrl.adminUnbanDevice(dev.deviceFingerprint);
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildGhostModule(ArcanaPalette p, AppController ctrl) {
    return HeraldicCard(
      goldAccent: ctrl.ghostSpectatorActive,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Modo Espectador Fantasma (Auditoria Silenciosa)',
            style: TextStyle(fontWeight: FontWeight.w700, color: p.goldHighlight),
          ),
          const SizedBox(height: 6),
          Text(
            'Quando ativo, permite entrar em qualquer mesa publica ou privada no modo somente-observacao para investigacao de denuncias sem aparecer no elenco.',
            style: TextStyle(fontSize: 12.5, color: p.textSecondary),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: ctrl.ghostSpectatorActive,
            onChanged: (_) {
              ctrl.toggleGhostSpectator();
              setState(() {});
            },
            title: const Text('Ativar Visao Fantasma nas Campanhas'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuperadminAudit(ArcanaPalette p, AppController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeraldicCard(
          borderColor: p.crimson,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Auditoria de DMs 1-a-1 (Exclusivo Superadmin)',
                style: TextStyle(fontWeight: FontWeight.w700, color: p.crimson),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _dmUserACtrl,
                decoration: const InputDecoration(labelText: 'ID Usuario A (usr_...)'),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _dmUserBCtrl,
                decoration: const InputDecoration(labelText: 'ID Usuario B (usr_...)'),
              ),
              const SizedBox(height: 10),
              PrimaryGoldPillButton(
                label: 'Consultar Logs de DM',
                svgIcon: ArcanaSvgIcons.search,
                expand: true,
                onPressed: () async {
                  final list = await ctrl.adminAuditDms(
                    _dmUserACtrl.text.trim(),
                    _dmUserBCtrl.text.trim(),
                  );
                  if (mounted) setState(() => _auditedDms = list);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (final m in _auditedDms)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: HeraldicCard(
              child: Text('${m.senderHandle} (${m.timeText}): ${m.content}'),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// 8. LOGOUT SEGURO
// =============================================================================

class SafeLogoutModal extends StatelessWidget {
  final AppController controller;

  const SafeLogoutModal({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.logOut,
      title: 'Encerrar Sessao Segura',
      subtitle: 'Desconecte este aparelho ou todos os dispositivos confiaveis',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryGoldPillButton(
            label: 'Sair Apenas Deste Aparelho',
            svgIcon: ArcanaSvgIcons.logOut,
            expand: true,
            onPressed: () async {
              Navigator.of(context).pop();
              await controller.logout(revokeGlobal: false);
            },
          ),
          const SizedBox(height: 10),
          SecondaryHeraldicButton(
            label: 'Sair de Todos os Aparelhos (Revogar Global)',
            svgIcon: ArcanaSvgIcons.lock,
            borderColor: p.crimson,
            textColor: p.crimson,
            expand: true,
            onPressed: () async {
              Navigator.of(context).pop();
              await controller.logout(revokeGlobal: true);
            },
          ),
        ],
      ),
    );
  }
}
