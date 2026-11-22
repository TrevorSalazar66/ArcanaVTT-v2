import 'package:flutter/material.dart';
import '../../../controllers/app_controller.dart';
import '../../../core/constants/svg_icons.dart';
import '../../../core/theme/arcana_colors.dart';
import '../../../domain/entities/arcana_entities.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/heraldic_card.dart';
import 'modal_shell.dart';
import 'universal_report_modal.dart';

class CreateAnnouncementModal extends StatefulWidget {
  final AppController controller;

  const CreateAnnouncementModal({super.key, required this.controller});

  @override
  State<CreateAnnouncementModal> createState() => _CreateAnnouncementModalState();
}

class _CreateAnnouncementModalState extends State<CreateAnnouncementModal> {
  final _tagCtrl = TextEditingController(text: 'OFICIAL');
  final _titleCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _tagCtrl.dispose();
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.sparkles,
      title: 'Publicar Anuncio Oficial',
      subtitle: 'Visivel para todos os aventureiros na Home e Aba Noticias',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _tagCtrl,
            decoration: const InputDecoration(labelText: 'Tag (ex: OFICIAL, PATCH)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Titulo do Anuncio'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _summaryCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Conteudo / Resumo'),
          ),
          const SizedBox(height: 16),
          PrimaryGoldPillButton(
            label: _saving ? 'Publicando...' : 'Publicar no Boletim',
            svgIcon: ArcanaSvgIcons.check,
            expand: true,
            onPressed: _saving
                ? null
                : () async {
                    if (_titleCtrl.text.trim().length < 4 ||
                        _summaryCtrl.text.trim().length < 6) {
                      return;
                    }
                    setState(() => _saving = true);
                    final nav = Navigator.of(context);
                    await widget.controller.createOfficialAnnouncement(
                      tag: _tagCtrl.text,
                      title: _titleCtrl.text,
                      summary: _summaryCtrl.text,
                    );
                    if (nav.mounted) nav.pop();
                  },
          ),
        ],
      ),
    );
  }
}

class CreateGuildModal extends StatefulWidget {
  final AppController controller;

  const CreateGuildModal({super.key, required this.controller});

  @override
  State<CreateGuildModal> createState() => _CreateGuildModalState();
}

class _CreateGuildModalState extends State<CreateGuildModal> {
  final _nameCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _worldCtrl = TextEditingController(text: 'Continente Compartilhado');
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tagCtrl.dispose();
    _worldCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.crown,
      title: 'Fundar Nova Guilda',
      subtitle: 'Hub de Clas, World Wiki e Mesas Compartilhadas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nome da Guilda'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _tagCtrl,
            maxLength: 8,
            decoration: const InputDecoration(labelText: 'Tag (ex: ORDEM)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _worldCtrl,
            decoration: const InputDecoration(labelText: 'Nome do Shared World'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Proposito da Guilda'),
          ),
          const SizedBox(height: 16),
          PrimaryGoldPillButton(
            label: _saving ? 'Fundando...' : 'Criar Guilda (Nivel 1)',
            svgIcon: ArcanaSvgIcons.check,
            expand: true,
            onPressed: _saving
                ? null
                : () async {
                    if (_nameCtrl.text.trim().length < 3 ||
                        _descCtrl.text.trim().length < 6) {
                      return;
                    }
                    setState(() => _saving = true);
                    final nav = Navigator.of(context);
                    await widget.controller.createGuild(
                      name: _nameCtrl.text,
                      tag: _tagCtrl.text,
                      description: _descCtrl.text,
                      sharedWorldName: _worldCtrl.text,
                    );
                    if (nav.mounted) nav.pop();
                  },
          ),
        ],
      ),
    );
  }
}

class GuildDetailModal extends StatefulWidget {
  final AppController controller;
  final Guild guild;

  const GuildDetailModal({
    super.key,
    required this.controller,
    required this.guild,
  });

  @override
  State<GuildDetailModal> createState() => _GuildDetailModalState();
}

class _GuildDetailModalState extends State<GuildDetailModal> {
  final _clanCtrl = TextEditingController();
  final _wikiTitleCtrl = TextEditingController();
  final _wikiBodyCtrl = TextEditingController();

  @override
  void dispose() {
    _clanCtrl.dispose();
    _wikiTitleCtrl.dispose();
    _wikiBodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final g = widget.controller.guilds.firstWhere(
      (item) => item.id == widget.guild.id,
      orElse: () => widget.guild,
    );

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.crown,
      title: '[${g.tag}] ${g.name}',
      subtitle: 'Nivel ${g.level}/5 · ${g.sharedWorldName} (${g.currentSeason})',
      badgeLabel: 'NV.${g.level}',
      badgeColor: p.emerald,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeraldicCard(
            goldAccent: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.description, style: TextStyle(fontSize: 13, color: p.textPrimary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    HeraldicChipPill(label: 'Membros max: ${g.maxMembers}', color: p.infoBlue),
                    HeraldicChipPill(label: 'Mestres max: ${g.maxMasters}', color: p.goldPrimary),
                    HeraldicChipPill(label: 'Canais: ${g.maxChannels}', color: p.emerald),
                    HeraldicChipPill(label: 'Clas max: ${g.maxClans}', color: p.goldHighlight),
                  ],
                ),
                const SizedBox(height: 12),
                PrimaryGoldPillButton(
                  label: 'Contribuir Guild Boost (+500 XP)',
                  svgIcon: ArcanaSvgIcons.flame,
                  expand: true,
                  onPressed: () async {
                    await widget.controller.contributeGuildBoost(g.id, 500);
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Clas da Guilda (${g.clans.length}/${g.maxClans})',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.w700,
              color: p.goldHighlight,
            ),
          ),
          const SizedBox(height: 8),
          for (final c in g.clans)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: HeraldicCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        (c['name'] as String?) ?? 'Cla',
                        style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Denunciar Cla',
                      onPressed: () => showArcanaModal(context,
                        builder: (_) => UniversalReportModal(
                          controller: widget.controller,
                          originType: 'cla',
                          originId: '${g.id}_${c['name']}',
                        ),
                      ),
                      icon: const Icon(Icons.flag_outlined, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _clanCtrl,
                  decoration: const InputDecoration(hintText: 'Nome do novo Cla'),
                ),
              ),
              const SizedBox(width: 8),
              SecondaryHeraldicButton(
                label: 'Fundar Cla',
                svgIcon: ArcanaSvgIcons.plus,
                onPressed: g.clans.length >= g.maxClans
                    ? null
                    : () async {
                        if (_clanCtrl.text.trim().length < 2) return;
                        final nextClans = [
                          ...g.clans,
                          {'name': _clanCtrl.text.trim()},
                        ];
                        await widget.controller
                            .updateGuildWorld(g.id, {'clans': nextClans});
                        _clanCtrl.clear();
                        if (mounted) setState(() {});
                      },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'World Wiki Compartilhada (${g.wikiArticles.length})',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.w700,
              color: p.goldHighlight,
            ),
          ),
          const SizedBox(height: 8),
          for (final w in g.wikiArticles)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: HeraldicCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (w['title'] as String?) ?? 'Artigo',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: p.goldPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Denunciar Wiki',
                          onPressed: () => showArcanaModal(context,
                            builder: (_) => UniversalReportModal(
                              controller: widget.controller,
                              originType: 'wiki',
                              originId: '${g.id}_${w['title']}',
                            ),
                          ),
                          icon: const Icon(Icons.flag_outlined, size: 16),
                        ),
                      ],
                    ),
                    Text(
                      (w['body'] as String?) ?? '',
                      style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          TextField(
            controller: _wikiTitleCtrl,
            decoration: const InputDecoration(hintText: 'Titulo do artigo na World Wiki'),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _wikiBodyCtrl,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Lore / Canon do Mundo Compartilhado'),
          ),
          const SizedBox(height: 8),
          SecondaryHeraldicButton(
            label: 'Publicar na World Wiki',
            svgIcon: ArcanaSvgIcons.bookOpen,
            expand: true,
            onPressed: () async {
              if (_wikiTitleCtrl.text.trim().length < 2) return;
              final nextWiki = [
                ...g.wikiArticles,
                {
                  'title': _wikiTitleCtrl.text.trim(),
                  'body': _wikiBodyCtrl.text.trim(),
                },
              ];
              await widget.controller.updateGuildWorld(g.id, {'wiki': nextWiki});
              _wikiTitleCtrl.clear();
              _wikiBodyCtrl.clear();
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: SecondaryHeraldicButton(
              label: 'Denunciar Guilda',
              svgIcon: ArcanaSvgIcons.flag,
              borderColor: p.crimson,
              textColor: p.crimson,
              onPressed: () => showArcanaModal(context,
                builder: (_) => UniversalReportModal(
                  controller: widget.controller,
                  originType: 'guilda',
                  originId: g.id,
                  targetUserId: g.leaderId,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CreateForumTopicModal extends StatefulWidget {
  final AppController controller;

  const CreateForumTopicModal({super.key, required this.controller});

  @override
  State<CreateForumTopicModal> createState() => _CreateForumTopicModalState();
}

class _CreateForumTopicModalState extends State<CreateForumTopicModal> {
  String _category = 'Regras';
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.feather,
      title: 'Novo Topico no Forum',
      subtitle: 'Discussoes, homebrews, narracao e convites de mesa',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Categoria'),
            items: const ['Regras', 'Cenarios', 'Homebrews', 'Mesa Aberta', 'Feedback']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? 'Regras'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Titulo do Topico'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _contentCtrl,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Conteudo da Discussao'),
          ),
          const SizedBox(height: 16),
          PrimaryGoldPillButton(
            label: _saving ? 'Publicando...' : 'Publicar no Forum',
            svgIcon: ArcanaSvgIcons.check,
            expand: true,
            onPressed: _saving
                ? null
                : () async {
                    if (_titleCtrl.text.trim().length < 5 ||
                        _contentCtrl.text.trim().length < 10) {
                      return;
                    }
                    setState(() => _saving = true);
                    final nav = Navigator.of(context);
                    await widget.controller.createForumTopic(
                      category: _category,
                      title: _titleCtrl.text,
                      content: _contentCtrl.text,
                    );
                    if (nav.mounted) nav.pop();
                  },
          ),
        ],
      ),
    );
  }
}

class ForumTopicDetailModal extends StatefulWidget {
  final AppController controller;
  final ForumTopic topic;

  const ForumTopicDetailModal({
    super.key,
    required this.controller,
    required this.topic,
  });

  @override
  State<ForumTopicDetailModal> createState() => _ForumTopicDetailModalState();
}

class _ForumTopicDetailModalState extends State<ForumTopicDetailModal> {
  final _commentCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.controller.fetchForumTopicDetail(widget.topic.id).whenComplete(() {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final topic = widget.controller.forumTopics.firstWhere(
      (t) => t.id == widget.topic.id,
      orElse: () => widget.topic,
    );

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.messageSquare,
      title: topic.title,
      subtitle: '${topic.authorHandle} · ${topic.category} · ${topic.timeAgo}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeraldicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(topic.content, style: TextStyle(fontSize: 13.5, color: p.textPrimary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SecondaryHeraldicButton(
                      label: '+1 (${topic.upvotes})',
                      svgIcon: ArcanaSvgIcons.sparkles,
                      onPressed: () async {
                        await widget.controller.upvoteTopic(topic.id, delta: 1);
                        if (mounted) setState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    SecondaryHeraldicButton(
                      label: '-1',
                      onPressed: () async {
                        await widget.controller.upvoteTopic(topic.id, delta: -1);
                        if (mounted) setState(() {});
                      },
                    ),
                    const Spacer(),
                    SecondaryHeraldicButton(
                      label: 'Denunciar',
                      svgIcon: ArcanaSvgIcons.flag,
                      borderColor: p.crimson,
                      textColor: p.crimson,
                      onPressed: () => showArcanaModal(context,
                        builder: (_) => UniversalReportModal(
                          controller: widget.controller,
                          originType: 'forum',
                          originId: topic.id,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Respostas (${topic.comments.length})',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.w700,
              color: p.goldHighlight,
            ),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
          else if (topic.comments.isEmpty)
            HeraldicCard(
              child: Text(
                'Nenhum comentario ainda.',
                style: TextStyle(fontSize: 12, color: p.textSecondary),
              ),
            )
          else
            for (final c in topic.comments) ...[
              HeraldicCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(c.authorHandle,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: p.goldPrimary)),
                        Text(c.timeAgo,
                            style: TextStyle(fontSize: 11, color: p.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(c.content, style: TextStyle(fontSize: 13, color: p.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentCtrl,
                  decoration: const InputDecoration(hintText: 'Responder ao topico...'),
                ),
              ),
              const SizedBox(width: 8),
              PrimaryGoldPillButton(
                label: 'Enviar',
                onPressed: () async {
                  if (_commentCtrl.text.trim().length < 2) return;
                  final txt = _commentCtrl.text;
                  _commentCtrl.clear();
                  await widget.controller.commentOnForumTopic(topic.id, txt);
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
