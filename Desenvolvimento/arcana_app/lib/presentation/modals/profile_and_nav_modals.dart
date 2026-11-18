import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/svg_icons.dart';
import '../../core/security/rbac_guard.dart';
import '../../core/theme/arcana_colors.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/heraldic_card.dart';
import '../widgets/heraldic_section_divider.dart';
import '../widgets/svg_icon_widget.dart';
import 'modal_shell.dart';
import 'quick_join_modal.dart';

/// 1. Central de Notificações.
class NotificationsModal extends StatefulWidget {
  final AppController controller;

  const NotificationsModal({super.key, required this.controller});

  @override
  State<NotificationsModal> createState() => _NotificationsModalState();
}

class _NotificationsModalState extends State<NotificationsModal> {
  String _filter = 'todas';

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final items = widget.controller.notifications.where((n) {
          if (_filter == 'todas') return true;
          return n.category == _filter;
        }).toList();

        return ArcanaModalScaffold(
          svgIcon: ArcanaSvgIcons.bell,
          title: 'NOTIFICAÇÕES',
          subtitle: '${widget.controller.unreadNotificationsCount} avisos pendentes',
          badgeLabel: 'AO VIVO',
          badgeColor: p.infoBlue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 6,
                    children: ['todas', 'mesas', 'social', 'sistema']
                        .map(
                          (cat) => ChoiceChip(
                            label: Text(cat.toUpperCase()),
                            selected: _filter == cat,
                            onSelected: (_) => setState(() => _filter = cat),
                          ),
                        )
                        .toList(),
                  ),
                  TextButton(
                    onPressed: widget.controller.markAllNotificationsRead,
                    child: const Text('Limpar'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (items.isEmpty)
                HeraldicCard(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nenhuma notificação pendente.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                ...items.map(
                  (n) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: HeraldicCard(
                      goldAccent: !n.isRead,
                      onTap: () => widget.controller.markNotificationRead(n.id),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  n.title,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                n.timeAgo,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(n.body, style: Theme.of(context).textTheme.bodySmall),
                          if (n.campaignCode != null) ...[
                            const SizedBox(height: 8),
                            SecondaryHeraldicButton(
                              label: 'Entrar pelo Código ${n.campaignCode}',
                              svgIcon: ArcanaSvgIcons.qrCode,
                              onPressed: () {
                                Navigator.of(context).pop();
                                showArcanaModal(
                                  context,
                                  builder: (_) => QuickJoinModal(
                                    controller: widget.controller,
                                    prefilledCode: n.campaignCode,
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 2. Perfil Social & Identidade.
class SocialProfileModal extends StatefulWidget {
  final AppController controller;

  const SocialProfileModal({super.key, required this.controller});

  @override
  State<SocialProfileModal> createState() => _SocialProfileModalState();
}

class _SocialProfileModalState extends State<SocialProfileModal> {
  late final TextEditingController _userCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _discordCtrl;
  late final TextEditingController _whatsappCtrl;
  late final TextEditingController _instagramCtrl;

  @override
  void initState() {
    super.initState();
    final u = widget.controller.currentUser;
    _userCtrl = TextEditingController(text: u.username);
    _nameCtrl = TextEditingController(text: u.displayName);
    _bioCtrl = TextEditingController(text: u.bio);
    _discordCtrl =
        TextEditingController(text: u.socialContacts['discord'] ?? '');
    _whatsappCtrl =
        TextEditingController(text: u.socialContacts['whatsapp'] ?? '');
    _instagramCtrl =
        TextEditingController(text: u.socialContacts['instagram'] ?? '');
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _discordCtrl.dispose();
    _whatsappCtrl.dispose();
    _instagramCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final u = widget.controller.currentUser;
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.user,
      title: 'PERFIL SOCIAL',
      subtitle: u.email,
      badgeLabel: u.role.badgeLabel,
      badgeColor: p.goldPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeraldicCard(
            goldAccent: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('Reputação', '${u.reputationPoints}', p.goldPrimary),
                _stat('Keystore', '${u.trustedDaysRemaining}d', p.emerald),
                _stat('Papel', u.role.badgeLabel, p.infoBlue),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _userCtrl,
            maxLength: 24,
            decoration: const InputDecoration(
              labelText: 'Identificador Único',
              prefixText: '@',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            maxLength: 60,
            decoration: const InputDecoration(labelText: 'Nome de Exibição'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bioCtrl,
            maxLines: 3,
            maxLength: 500,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Biografia da Taverna',
              helperText: '${_bioCtrl.text.length} / 500 caracteres',
            ),
          ),
          const SizedBox(height: 10),
          const HeraldicSectionDivider(
            svgIcon: ArcanaSvgIcons.users,
            title: 'CONTATOS SOCIAIS',
          ),
          TextField(
            controller: _discordCtrl,
            maxLength: 60,
            decoration: const InputDecoration(labelText: 'Discord (opcional)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _whatsappCtrl,
            maxLength: 30,
            decoration: const InputDecoration(labelText: 'WhatsApp (opcional)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _instagramCtrl,
            maxLength: 60,
            decoration:
                const InputDecoration(labelText: 'Instagram (opcional)'),
          ),
          const SizedBox(height: 16),
          PrimaryGoldPillButton(
            label: 'Salvar Alterações',
            svgIcon: ArcanaSvgIcons.check,
            onPressed: () async {
              final ok = await widget.controller.updateProfile(
                username: _userCtrl.text,
                displayName: _nameCtrl.text,
                bio: _bioCtrl.text,
                contacts: {
                  'discord': _discordCtrl.text,
                  'whatsapp': _whatsappCtrl.text,
                  'instagram': _instagramCtrl.text,
                },
              );
              if (!context.mounted) return;
              if (ok) {
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.controller.lastSyncError ??
                          'Não foi possível salvar alterações no servidor.',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

/// 3. Lista de Amigos & Mensagens Diretas.
class FriendsManagementModal extends StatefulWidget {
  final AppController controller;

  const FriendsManagementModal({super.key, required this.controller});

  @override
  State<FriendsManagementModal> createState() => _FriendsManagementModalState();
}

class _FriendsManagementModalState extends State<FriendsManagementModal> {
  final TextEditingController _addCtrl = TextEditingController();
  bool _adding = false;
  String? _friendError;

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return ArcanaModalScaffold(
          svgIcon: ArcanaSvgIcons.users,
          title: 'AMIGOS & DMs',
          subtitle: '${widget.controller.friends.length} aliados conectados',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Adicionar por @username',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SecondaryHeraldicButton(
                    label: _adding ? '...' : 'Convidar',
                    svgIcon: ArcanaSvgIcons.plus,
                    borderColor: p.goldBorder,
                    onPressed: _adding
                        ? null
                        : () async {
                            setState(() {
                              _adding = true;
                              _friendError = null;
                            });
                            final err = await widget.controller
                                .addFriendByUsername(_addCtrl.text);
                            if (!mounted) return;
                            setState(() {
                              _adding = false;
                              _friendError = err;
                              if (err == null) _addCtrl.clear();
                            });
                          },
                  ),
                ],
              ),
              if (_friendError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _friendError!,
                  style: TextStyle(color: p.crimson, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              if (widget.controller.friends.isEmpty)
                HeraldicCard(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nenhum aliado adicionado ainda. Busque por @username real.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                ...widget.controller.friends.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: HeraldicCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: p.surfaceElevated,
                              shape: BoxShape.circle,
                              border: Border.all(color: p.goldBorder),
                            ),
                            alignment: Alignment.center,
                            child: SvgIconWidget(ArcanaSvgIcons.user, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      f.displayName,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(width: 6),
                                    HeraldicChipPill(
                                      label: f.presenceStatus,
                                      color: f.presenceStatus == 'Em Mesa'
                                          ? p.goldPrimary
                                          : p.emerald,
                                    ),
                                  ],
                                ),
                                Text(
                                  '@${f.username} • ${f.activity}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 4. Central de Tutoriais Sandboxed (Offline).
class TutorialsCentralModal extends StatelessWidget {
  final AppController controller;

  const TutorialsCentralModal({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return ArcanaModalScaffold(
          svgIcon: ArcanaSvgIcons.book,
          title: 'CENTRAL DE TUTORIAIS',
          subtitle: 'Treinamento Guiado nas 5 Macro Funções',
          badgeLabel: 'SANDBOX',
          badgeColor: p.emerald,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeraldicCard(
                borderColor: p.infoBlue,
                child: Text(
                  'Ambiente Sandboxed Local (Offline): pratique rolagens e criação de mesas sem alterar fichas ou banco D1.',
                  style: TextStyle(color: p.infoBlue, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              ...controller.tutorials.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: HeraldicCard(
                    goldAccent: !t.completed,
                    onTap: () => controller.toggleTutorialCompleted(t.id),
                    child: Row(
                      children: [
                        SvgIconWidget(
                          t.completed
                              ? ArcanaSvgIcons.circleCheck
                              : ArcanaSvgIcons.map,
                          size: 20,
                          color: t.completed ? p.emerald : p.goldPrimary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.title,
                                  style: Theme.of(context).textTheme.titleMedium),
                              Text(t.subtitle,
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        HeraldicChipPill(
                          label: t.completed ? 'FEITO' : 'INICIAR',
                          color: t.completed ? p.emerald : p.goldPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 5. Configurações Gerais (Idioma, Vibração, Temas, Escala, Mixer, Rede P2P, Privacidade & Lockout Total).
class GeneralSettingsModal extends StatelessWidget {
  final AppController controller;

  const GeneralSettingsModal({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final ctrl = controller;
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final mixer = ctrl.audioMixer;
        const languages = ['PT-BR', 'EN-US', 'ES-ES'];
        const haptics = ['Desativado', 'Suave', 'Médio', 'Intenso'];
        const quotas = ['512 MB', '1 GB', '2 GB'];
        const dmOptions = ['Qualquer usuário', 'Apenas amigos', 'Ninguém'];
        const showcaseOptions = [
          'Público na Taverna',
          'Apenas amigos',
          'Privado',
        ];

        return ArcanaModalScaffold(
          svgIcon: ArcanaSvgIcons.settings,
          title: 'CONFIGURAÇÕES GERAIS',
          subtitle: 'Preferências, Temas, Áudio, Rede P2P e Privacidade',
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              const HeraldicSectionDivider(
                svgIcon: ArcanaSvgIcons.sparkles,
                title: 'IDIOMA & FEEDBACK HÁPTICO',
              ),
              Text(
                'Idioma do Aplicativo',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: languages
                    .map(
                      (lang) => ChoiceChip(
                        label: Text(lang),
                        selected: ctrl.appLanguage == lang,
                        onSelected: (_) => ctrl.setAppLanguage(lang),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Text(
                'Intensidade da Vibração Háptica',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: haptics
                    .map(
                      (level) => ChoiceChip(
                        label: Text(level),
                        selected: ctrl.hapticLevel == level,
                        onSelected: (_) => ctrl.setHapticLevel(level),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              const HeraldicSectionDivider(
                svgIcon: ArcanaSvgIcons.sparkles,
                title: 'TEMAS OFICIAIS',
              ),
              RadioGroup<ArcanaThemeMode>(
                groupValue: ctrl.themeMode,
                onChanged: (val) {
                  if (val != null) ctrl.setThemeMode(val);
                },
                child: Column(
                  children: ArcanaThemeMode.values
                      .map(
                        (mode) => RadioListTile<ArcanaThemeMode>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(mode.labelPtBr),
                          value: mode,
                          activeColor: p.goldPrimary,
                        ),
                      )
                      .toList(),
                ),
              ),
              const HeraldicSectionDivider(
                svgIcon: ArcanaSvgIcons.sliders,
                title: 'ESCALA TIPOGRÁFICA (80% - 150%)',
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Multiplicador de Leitura'),
                  Text(
                    '${(ctrl.fontScale * 100).round()}%',
                    style: TextStyle(
                      color: p.goldPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Slider(
                value: ctrl.fontScale,
                min: 0.8,
                max: 1.5,
                divisions: 7,
                activeColor: p.goldPrimary,
                onChanged: ctrl.setFontScale,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reduzir Animações & Partículas'),
                subtitle: const Text('Economiza bateria em telas de 60/120 Hz'),
                value: ctrl.reduceMotion,
                activeTrackColor: p.emerald,
                onChanged: ctrl.setReduceMotion,
              ),
              const HeraldicSectionDivider(
                svgIcon: ArcanaSvgIcons.volume2,
                title: 'MIXER DE ÁUDIO (4 CANAIS)',
              ),
              _volumeSlider(
                'Master',
                mixer.masterVolume,
                p.goldPrimary,
                (v) => ctrl.updateAudioMixer(mixer.copyWith(masterVolume: v)),
              ),
              _volumeSlider(
                'Ambiência',
                mixer.ambienceVolume,
                p.infoBlue,
                (v) => ctrl.updateAudioMixer(mixer.copyWith(ambienceVolume: v)),
              ),
              _volumeSlider(
                'Efeitos (SFX)',
                mixer.sfxVolume,
                p.emerald,
                (v) => ctrl.updateAudioMixer(mixer.copyWith(sfxVolume: v)),
              ),
              _volumeSlider(
                'Voz / Mesa',
                mixer.voiceVolume,
                p.goldHighlight,
                (v) => ctrl.updateAudioMixer(mixer.copyWith(voiceVolume: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mutar Áudio em Segundo Plano'),
                value: ctrl.muteInBackground,
                activeTrackColor: p.emerald,
                onChanged: ctrl.setMuteInBackground,
              ),
              const HeraldicSectionDivider(
                svgIcon: ArcanaSvgIcons.wifi,
                title: 'REDE P2P & CACHE LOCAL',
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sincronia P2P Mesh Ativa'),
                subtitle: const Text('Baixa latência com Eleição de Líder na mesa'),
                value: ctrl.p2pEnabled,
                activeTrackColor: p.emerald,
                onChanged: ctrl.setP2pEnabled,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Carregar Mídia Externa Somente via Wi-Fi'),
                value: ctrl.p2pWifiOnly,
                activeTrackColor: p.emerald,
                onChanged: ctrl.setP2pWifiOnly,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bloquear Mídia Externa (Somente Oficiais)'),
                value: ctrl.externalMediaOnlyOfficial,
                activeTrackColor: p.goldPrimary,
                onChanged: ctrl.setExternalMediaOnlyOfficial,
              ),
              const SizedBox(height: 4),
              const Text('Limite do Cache de Mapas & Áudio'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: quotas
                    .map(
                      (q) => ChoiceChip(
                        label: Text(q),
                        selected: ctrl.p2pCacheQuota == q,
                        onSelected: (_) => ctrl.setP2pCacheQuota(q),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              SecondaryHeraldicButton(
                label: 'Limpar Cache P2P Local (${ctrl.p2pCacheMb} MB)',
                svgIcon: ArcanaSvgIcons.trash,
                expand: true,
                onPressed: ctrl.clearP2pCache,
              ),
              const SizedBox(height: 12),
              const HeraldicSectionDivider(
                svgIcon: ArcanaSvgIcons.shield,
                title: 'PRIVACIDADE & SEGURANÇA',
              ),
              const Text('Quem pode enviar Mensagem Direta (DM)'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: dmOptions
                    .map(
                      (opt) => ChoiceChip(
                        label: Text(opt),
                        selected: ctrl.dmPrivacy == opt,
                        onSelected: (_) => ctrl.setDmPrivacy(opt),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              const Text('Visibilidade da Vitrine de Heróis'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: showcaseOptions
                    .map(
                      (opt) => ChoiceChip(
                        label: Text(opt),
                        selected: ctrl.showcasePrivacy == opt,
                        onSelected: (_) => ctrl.setShowcasePrivacy(opt),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Exibir Status de Presença Online'),
                value: ctrl.onlinePresenceVisible,
                activeTrackColor: p.emerald,
                onChanged: ctrl.setOnlinePresenceVisible,
              ),
              const SizedBox(height: 10),
              SecondaryHeraldicButton(
                label: 'Acionar Lockout Total de Emergência',
                svgIcon: ArcanaSvgIcons.lock,
                borderColor: p.crimson,
                textColor: p.crimson,
                expand: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  ctrl.triggerTotalLockout();
                },
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _volumeSlider(
    String label,
    double value,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 96, child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(
          child: Slider(
            value: value,
            activeColor: color,
            onChanged: onChanged,
          ),
        ),
        Text('${(value * 100).round()}%', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

/// 6. Painel de Governança Admin (Exclusivo para Admin / Superadmin).
class AdminGovernanceModal extends StatelessWidget {
  final AppController controller;

  const AdminGovernanceModal({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final canManageAdmins =
            RbacGuard.canManageAdmins(controller.currentUser.role);
        final assignableRoles = <UserRole>[
          UserRole.jogador,
          UserRole.mestre,
          if (canManageAdmins) UserRole.admin,
        ];

        return ArcanaModalScaffold(
          svgIcon: ArcanaSvgIcons.terminal,
          title: 'GOVERNANÇA ADMIN',
          subtitle: 'Zero-Trust • Cargos RBAC, Denúncias e Hardware Ban',
          badgeLabel: controller.currentUser.role.badgeLabel,
          badgeColor: p.crimson,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeraldicCard(
                borderColor: p.crimson,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Usuários: ${controller.adminUsers.length}'),
                    Text('Denúncias: ${controller.reports.length}'),
                    Text('Bans: ${controller.hardwareBannedFingerprints.length}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const HeraldicSectionDivider(
                svgIcon: ArcanaSvgIcons.users,
                title: 'GESTÃO DE USUÁRIOS & CARGOS (RBAC)',
              ),
              HeraldicCard(
                padding: const EdgeInsets.all(10),
                child: Text(
                  canManageAdmins
                      ? 'Superadmin: pode promover/rebaixar Jogador, Mestre e Admin.'
                      : 'Admin: pode promover/rebaixar apenas Jogador e Mestre (Superadmin protegido).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 8),
              if (controller.adminUsers.isEmpty)
                HeraldicCard(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Nenhum usuário listado ainda.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                ...controller.adminUsers.map((usr) {
                  final isProtectedSystem = usr.id == 'usr_system_official' ||
                      usr.role == UserRole.superadmin ||
                      (usr.role == UserRole.admin && !canManageAdmins);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: HeraldicCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      usr.displayName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    Text(
                                      '@${usr.username} • ${usr.email}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              RoleBadgeWidget(role: usr.role),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (isProtectedSystem)
                            Text(
                              usr.role == UserRole.superadmin
                                  ? 'Superadmin: cargo protegido na raiz da plataforma.'
                                  : 'Protegido pela hierarquia Zero-Trust.',
                              style: TextStyle(
                                fontSize: 11,
                                color: p.textSecondary,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: assignableRoles.map((r) {
                                final selected = usr.role == r;
                                return ChoiceChip(
                                  label: Text(r.badgeLabel),
                                  selected: selected,
                                  onSelected: selected
                                      ? null
                                      : (_) async {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final err = await controller
                                              .adminUpdateUserRole(
                                            targetUserId: usr.id,
                                            newRole: r,
                                          );
                                          if (err != null) {
                                            messenger.showSnackBar(
                                              SnackBar(content: Text(err)),
                                            );
                                          }
                                        },
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 12),
              const HeraldicSectionDivider(
                svgIcon: ArcanaSvgIcons.flag,
                title: 'FILA DE DENÚNCIAS & HARDWARE BAN',
              ),
              if (controller.reports.isEmpty)
                HeraldicCard(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nenhuma denúncia registrada.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                ...controller.reports.map(
                  (rep) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: HeraldicCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(rep.reasonCategory,
                                  style: Theme.of(context).textTheme.titleMedium),
                              HeraldicChipPill(
                                label: rep.status.toUpperCase(),
                                color: rep.status == 'pending' ? p.crimson : p.emerald,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(rep.description,
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: rep.autoTags
                                .map((t) => HeraldicChipPill(label: t, color: p.infoBlue))
                                .toList(),
                          ),
                          if (rep.status == 'pending') ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: SecondaryHeraldicButton(
                                    label: 'Resolver',
                                    borderColor: p.emerald,
                                    textColor: p.emerald,
                                    onPressed: () => controller.moderateReport(
                                      reportId: rep.id,
                                      decision: 'resolved',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SecondaryHeraldicButton(
                                    label: 'Hardware Ban',
                                    borderColor: p.crimson,
                                    textColor: p.crimson,
                                    onPressed: () => controller.moderateReport(
                                      reportId: rep.id,
                                      decision: 'resolved',
                                      applyHardwareBan: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
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
                      child: Text(
                        'Modo Espectador Fantasma: reservado para auditoria silenciosa de denúncias graves em mesas com proteção de Device Fingerprint Android.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 7. Modal de Logout Seguro.
class SafeLogoutModal extends StatelessWidget {
  final AppController controller;

  const SafeLogoutModal({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.logOut,
      title: 'LOGOUT SEGURO',
      subtitle: 'Encerramento limpo de credenciais locais e D1',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryGoldPillButton(
            label: 'Sair apenas deste aparelho',
            svgIcon: ArcanaSvgIcons.logOut,
            onPressed: () {
              Navigator.of(context).pop();
              controller.logout(revokeGlobal: false);
            },
          ),
          const SizedBox(height: 10),
          SecondaryHeraldicButton(
            label: 'Encerrar TODAS as sessões (Global Keystore + D1)',
            svgIcon: ArcanaSvgIcons.shield,
            borderColor: p.crimson,
            textColor: p.crimson,
            expand: true,
            onPressed: () {
              Navigator.of(context).pop();
              controller.logout(revokeGlobal: true);
            },
          ),
        ],
      ),
    );
  }
}

