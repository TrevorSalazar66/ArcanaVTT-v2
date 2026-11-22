import 'package:flutter/material.dart';
import '../../../controllers/app_controller.dart';
import '../../../core/constants/svg_icons.dart';
import '../../../core/security/rbac_guard.dart';
import '../../../core/theme/arcana_colors.dart';
import '../../modals/community_chat_modal.dart';
import '../../modals/community_hub_modals.dart';
import '../../modals/modal_shell.dart';
import '../../widgets/heraldic_buttons.dart';
import '../../widgets/heraldic_card.dart';
import '../../widgets/heraldic_section_divider.dart';
import '../../widgets/svg_icon_widget.dart';

class CommunitiesTabScreen extends StatefulWidget {
  final AppController controller;

  const CommunitiesTabScreen({super.key, required this.controller});

  @override
  State<CommunitiesTabScreen> createState() => _CommunitiesTabScreenState();
}

class _CommunitiesTabScreenState extends State<CommunitiesTabScreen> {
  int _segmentIndex = 0; // Noticias, Guildas, Forum
  String _forumSort = 'em_alta'; // em_alta | recentes | mais_votados

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeraldicSegmentBar(
          segments: const ['Noticias', 'Guildas', 'Forum'],
          selectedIndex: _segmentIndex,
          onSelected: (idx) => setState(() => _segmentIndex = idx),
        ),
        const SizedBox(height: 16),
        if (_segmentIndex == 0) _buildNewsView(context, ctrl),
        if (_segmentIndex == 1) _buildGuildsView(context, ctrl),
        if (_segmentIndex == 2) _buildForumView(context, ctrl),
      ],
    );
  }

  Widget _buildNewsView(BuildContext context, AppController ctrl) {
    final p = context.arcana;
    final canPost = RbacGuard.canPublishOfficialAnnouncement(ctrl.currentUser.role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeraldicCard(
          goldAccent: true,
          onTap: () => showArcanaModal(context,
            builder: (_) => CommunityChatModal(controller: ctrl),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.goldBorder),
                ),
                child: SvgIconWidget(
                  ArcanaSvgIcons.messagesSquare,
                  size: 24,
                  color: p.goldHighlight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Taverna Comunitaria (#taverna-dos-mestres)',
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ctrl.chatMessages.length} mensagens sincronizadas · Comandos universais ativos',
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              SvgIconWidget(ArcanaSvgIcons.chevronRight, size: 18, color: p.goldPrimary),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (canPost) ...[
          PrimaryGoldPillButton(
            label: 'Publicar Anuncio Oficial (Admin)',
            svgIcon: ArcanaSvgIcons.sparkles,
            expand: true,
            onPressed: () => showArcanaModal(context,
              builder: (_) => CreateAnnouncementModal(controller: ctrl),
            ),
          ),
          const SizedBox(height: 14),
        ],
        const HeraldicSectionDivider(
          svgIcon: ArcanaSvgIcons.bookOpen,
          title: 'Boletim da Plataforma',
        ),
        for (final n in ctrl.news) ...[
          HeraldicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeraldicChipPill(label: n.tag, color: p.goldPrimary),
                const SizedBox(height: 8),
                Text(
                  n.title,
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  n.summary,
                  style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildGuildsView(BuildContext context, AppController ctrl) {
    final p = context.arcana;
    final canFund = RbacGuard.canCreateGuild(ctrl.currentUser.role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canFund) ...[
          PrimaryGoldPillButton(
            label: 'Fundar Guilda (Shared World)',
            svgIcon: ArcanaSvgIcons.crown,
            expand: true,
            onPressed: () => showArcanaModal(context,
              builder: (_) => CreateGuildModal(controller: ctrl),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (ctrl.guilds.isEmpty)
          HeraldicCard(
            child: Text(
              'Nenhuma Guilda fundada neste servidor ainda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: p.textSecondary),
            ),
          )
        else
          for (final g in ctrl.guilds) ...[
            HeraldicCard(
              goldAccent: g.level >= 2,
              onTap: () => showArcanaModal(context,
                builder: (_) => GuildDetailModal(controller: ctrl, guild: g),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      HeraldicChipPill(label: '[${g.tag}]', color: p.goldPrimary),
                      const SizedBox(width: 8),
                      HeraldicChipPill(
                        label: 'NIVEL ${g.level}',
                        color: p.emerald,
                      ),
                      const Spacer(),
                      Text(
                        '${g.memberCount}/${g.maxMembers} membros',
                        style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    g.name,
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                  Text(
                    'Shared World: ${g.sharedWorldName} · ${g.currentSeason}',
                    style: TextStyle(fontSize: 12, color: p.goldHighlight),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    g.description,
                    style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: g.boostGoal > 0
                          ? (g.boostPoints / g.boostGoal).clamp(0.0, 1.0)
                          : 0.0,
                      minHeight: 7,
                      backgroundColor: p.surfaceElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(p.goldPrimary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Boost ${g.boostPoints}/${g.boostGoal} XP · Clas ${g.clans.length}/${g.maxClans}',
                        style: TextStyle(fontSize: 11, color: p.textSecondary),
                      ),
                      Text(
                        'Abrir Hub ->',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: p.goldPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryHeraldicButton(
                          label: 'Impulsionar (+200)',
                          svgIcon: ArcanaSvgIcons.flame,
                          expand: true,
                          onPressed: () => ctrl.contributeGuildBoost(g.id, 200),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _buildForumView(BuildContext context, AppController ctrl) {
    final p = context.arcana;
    final sorted = List.of(ctrl.forumTopics);
    sorted.sort((a, b) {
      if (_forumSort == 'mais_votados') {
        return b.upvotes.compareTo(a.upvotes);
      }
      if (_forumSort == 'recentes') {
        return b.createdAtIso.compareTo(a.createdAtIso);
      }
      final scoreB = b.upvotes + b.repliesCount * 2;
      final scoreA = a.upvotes + a.repliesCount * 2;
      return scoreB.compareTo(scoreA);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryGoldPillButton(
          label: 'Criar Novo Topico no Forum',
          svgIcon: ArcanaSvgIcons.plus,
          expand: true,
          onPressed: () => showArcanaModal(context,
            builder: (_) => CreateForumTopicModal(controller: ctrl),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Em Alta'),
              selected: _forumSort == 'em_alta',
              onSelected: (_) => setState(() => _forumSort = 'em_alta'),
            ),
            ChoiceChip(
              label: const Text('Mais Recentes'),
              selected: _forumSort == 'recentes',
              onSelected: (_) => setState(() => _forumSort = 'recentes'),
            ),
            ChoiceChip(
              label: const Text('Mais Votados'),
              selected: _forumSort == 'mais_votados',
              onSelected: (_) => setState(() => _forumSort = 'mais_votados'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (sorted.isEmpty)
          HeraldicCard(
            child: Text(
              'Nenhum topico no Forum ainda. Inicie a primeira discussao!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: p.textSecondary),
            ),
          )
        else
          for (final t in sorted) ...[
            HeraldicCard(
              onTap: () => showArcanaModal(context,
                builder: (_) => ForumTopicDetailModal(controller: ctrl, topic: t),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      HeraldicChipPill(label: t.category, color: p.infoBlue),
                      const Spacer(),
                      Text(
                        '${t.authorHandle} · ${t.timeAgo}',
                        style: TextStyle(fontSize: 11, color: p.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.title,
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SecondaryHeraldicButton(
                        label: '${t.upvotes}',
                        svgIcon: ArcanaSvgIcons.sparkles,
                        onPressed: () => ctrl.upvoteTopic(t.id, delta: 1),
                      ),
                      const SizedBox(width: 8),
                      HeraldicChipPill(
                        label: '${t.repliesCount} comentarios',
                        color: p.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}
