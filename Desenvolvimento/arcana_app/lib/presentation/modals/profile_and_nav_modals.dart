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

  @override
  void initState() {
    super.initState();
    final u = widget.controller.currentUser;
    _userCtrl = TextEditingController(text: u.username);
    _nameCtrl = TextEditingController(text: u.displayName);
    _bioCtrl = TextEditingController(text: u.bio);
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _nameCtrl.dispose();
    _bioCtrl.dispose();
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
            decoration: const InputDecoration(
              labelText: 'Identificador Único',
              prefixText: '@',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nome de Exibição'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bioCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Biografia da Taverna'),
          ),
          const SizedBox(height: 16),
          PrimaryGoldPillButton(
            label: 'Salvar Alterações',
            svgIcon: ArcanaSvgIcons.check,
            onPressed: () {
              widget.controller.updateProfile(
                username: _userCtrl.text,
                displayName: _nameCtrl.text,
                bio: _bioCtrl.text,
              );
              Navigator.of(context).pop();
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
                    label: 'Convidar',
                    svgIcon: ArcanaSvgIcons.plus,
                    borderColor: p.goldBorder,
                    onPressed: () {
                      widget.controller.addFriendByUsername(_addCtrl.text);
                      _addCtrl.clear();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
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

/// 5. Configurações Gerais (3 Temas, Escala Tipográfica 80-150%, Mixer 4 Canais, Cache P2P & Lockout Total).
class GeneralSettingsModal extends StatelessWidget {
  final AppController controller;

  const GeneralSettingsModal({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final mixer = controller.audioMixer;
        return ArcanaModalScaffold(
          svgIcon: ArcanaSvgIcons.settings,
          title: 'CONFIGURAÇÕES GERAIS',
          subtitle: 'Temas Heráldicos, Escala, Áudio e Segurança',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HeraldicSectionDivider(
                svgIcon: ArcanaSvgIcons.sparkles,
                title: 'TEMAS OFICIAIS',
              ),
              RadioGroup<ArcanaThemeMode>(
                groupValue: controller.themeMode,
                onChanged: (val) {
                  if (val != null) controller.setThemeMode(val);
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
                    '${(controller.fontScale * 100).round()}%',
                    style: TextStyle(
                      color: p.goldPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Slider(
                value: controller.fontScale,
                min: 0.8,
                max: 1.5,
                divisions: 7,
                activeColor: p.goldPrimary,
                onChanged: controller.setFontScale,
              ),
              const HeraldicSectionDivider(
                svgIcon: ArcanaSvgIcons.volume2,
                title: 'MIXER DE ÁUDIO (4 CANAIS)',
              ),
              _volumeSlider(
                'Master',
                mixer.masterVolume,
                p.goldPrimary,
                (v) => controller.updateAudioMixer(mixer.copyWith(masterVolume: v)),
              ),
              _volumeSlider(
                'Ambiência',
                mixer.ambienceVolume,
                p.infoBlue,
                (v) => controller.updateAudioMixer(mixer.copyWith(ambienceVolume: v)),
              ),
              _volumeSlider(
                'Efeitos (SFX)',
                mixer.sfxVolume,
                p.emerald,
                (v) => controller.updateAudioMixer(mixer.copyWith(sfxVolume: v)),
              ),
              _volumeSlider(
                'Voz / Mesa',
                mixer.voiceVolume,
                p.goldHighlight,
                (v) => controller.updateAudioMixer(mixer.copyWith(voiceVolume: v)),
              ),
              const HeraldicSectionDivider(
                svgIcon: ArcanaSvgIcons.shield,
                title: 'TROCA DE PAPEL (QA / RBAC)',
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: UserRole.values.map((role) {
                  return ChoiceChip(
                    label: Text(role.badgeLabel),
                    selected: controller.currentUser.role == role,
                    onSelected: (_) => controller.switchActiveRoleForPreview(role),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              SecondaryHeraldicButton(
                label: 'Limpar Cache P2P Local (${controller.p2pCacheMb} MB)',
                svgIcon: ArcanaSvgIcons.trash,
                expand: true,
                onPressed: controller.clearP2pCache,
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
                  controller.triggerTotalLockout();
                },
              ),
            ],
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
        return ArcanaModalScaffold(
          svgIcon: ArcanaSvgIcons.terminal,
          title: 'GOVERNANÇA ADMIN',
          subtitle: 'Zero-Trust • Moderação, D1 e Hardware Ban',
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
                    Text('Denúncias: ${controller.reports.length}'),
                    Text('Hardware Bans: ${controller.hardwareBannedFingerprints.length}'),
                    Text('Mesas: ${controller.campaigns.length}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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

