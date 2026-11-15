import 'package:flutter/material.dart';
import '../../../controllers/app_controller.dart';
import '../../../core/constants/svg_icons.dart';
import '../../../core/theme/arcana_colors.dart';
import '../../modals/community_chat_modal.dart';
import '../../modals/community_hub_modals.dart';
import '../../modals/modal_shell.dart';
import '../../widgets/heraldic_buttons.dart';
import '../../widgets/heraldic_card.dart';
import '../../widgets/svg_icon_widget.dart';

/// Aba 4 — Comunidades (Anúncios, Guildas, Fórum, Grupos/Chat Híbrido WhatsApp + Discord).
class CommunitiesTabScreen extends StatefulWidget {
  final AppController controller;

  const CommunitiesTabScreen({super.key, required this.controller});

  @override
  State<CommunitiesTabScreen> createState() => _CommunitiesTabScreenState();
}

class _CommunitiesTabScreenState extends State<CommunitiesTabScreen> {
  int _segmentIdx = 3; // Abre com destaque ou alterna livremente

  static const _segments = ['Anúncios', 'Guildas', 'Fórum', 'Grupos'];

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final ctrl = widget.controller;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        HeraldicSegmentBar(
          segments: _segments,
          selectedIndex: _segmentIdx,
          onSelected: (idx) => setState(() => _segmentIdx = idx),
        ),
        const SizedBox(height: 14),
        if (_segmentIdx == 0)
          ...ctrl.news.map(
            (n) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HeraldicCard(
                goldAccent: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeraldicChipPill(label: n.tag, color: p.goldPrimary),
                    const SizedBox(height: 8),
                    Text(n.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(n.summary, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          )
        else if (_segmentIdx == 1) ...[
          PrimaryGoldPillButton(
            label: 'Fundar Nova Guilda',
            svgIcon: ArcanaSvgIcons.plus,
            onPressed: () => showArcanaModal(
              context,
              builder: (_) => CreateGuildModal(controller: ctrl),
            ),
          ),
          const SizedBox(height: 12),
          if (ctrl.guilds.isEmpty)
            HeraldicCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nenhuma guilda fundada ainda.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Funde a primeira guilda para gerenciar mesas em Shared World e acumular Guild Boost.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          else
            ...ctrl.guilds.map(
              (g) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: HeraldicCard(
                  goldAccent: true,
                  onTap: () => showArcanaModal(
                    context,
                    builder: (_) =>
                        GuildPanelModal(controller: ctrl, guildId: g.id),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(g.name,
                                style: Theme.of(context).textTheme.titleMedium),
                          ),
                          HeraldicChipPill(label: '[${g.tag}]', color: p.goldPrimary),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(g.description, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: (g.boostGoal <= 0 ? 0.0 : g.boostPoints / g.boostGoal).clamp(0.0, 1.0),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(99),
                        color: p.goldPrimary,
                        backgroundColor: p.surfaceElevated,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Boost: ${g.boostPoints}/${g.boostGoal} • ${g.memberCount} Membros • Toque para abrir Guilda',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ] else if (_segmentIdx == 2) ...[
          PrimaryGoldPillButton(
            label: 'Criar Tópico no Fórum',
            svgIcon: ArcanaSvgIcons.plus,
            onPressed: () => showArcanaModal(
              context,
              builder: (_) => CreateForumTopicModal(controller: ctrl),
            ),
          ),
          const SizedBox(height: 12),
          if (ctrl.forumTopics.isEmpty)
            HeraldicCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nenhum tópico publicado no fórum ainda.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Inicie uma discussão sobre regras AlphaD6, crônicas ou recrutamento de jogadores.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          else
            ...ctrl.forumTopics.map(
              (topic) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HeraldicCard(
                  goldAccent: topic.pinned,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          HeraldicChipPill(
                            label: topic.category,
                            color: topic.pinned ? p.goldPrimary : p.infoBlue,
                          ),
                          Text(
                            '${topic.authorHandle} • ${topic.timeAgo}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(topic.title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(topic.content, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          SecondaryHeraldicButton(
                            label: 'Curtir (${topic.upvotes})',
                            svgIcon: ArcanaSvgIcons.heart,
                            borderColor: p.goldBorder,
                            onPressed: () => ctrl.upvoteTopic(topic.id),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${topic.repliesCount} respostas',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ] else ...[
          HeraldicCard(
            goldAccent: true,
            onTap: () => showArcanaModal(
              context,
              builder: (_) => CommunityChatModal(controller: ctrl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: p.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.goldBorder),
                      ),
                      alignment: Alignment.center,
                      child: SvgIconWidget(
                        ArcanaSvgIcons.messagesSquare,
                        size: 22,
                        color: p.goldPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Taverna dos Mestres',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Chat Híbrido WhatsApp + Discord • ${ctrl.chatMessages.length} mensagens',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    HeraldicChipPill(label: 'PÚBLICO', color: p.emerald),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Inclui bolhas de resposta, duplo check de leitura e rolagem de dados 3d6 embutida nas mensagens.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                PrimaryGoldPillButton(
                  label: 'Abrir Chat Comunitário',
                  svgIcon: ArcanaSvgIcons.messagesSquare,
                  onPressed: () => showArcanaModal(
                    context,
                    builder: (_) => CommunityChatModal(controller: ctrl),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

