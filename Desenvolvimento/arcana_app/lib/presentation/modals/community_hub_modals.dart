import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/svg_icons.dart';
import '../../core/theme/arcana_colors.dart';
import '../../domain/entities/arcana_entities.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/heraldic_card.dart';
import 'modal_shell.dart';

/// Painel de Guilda com Shared World & barra interativa de Guild Boost.
class GuildPanelModal extends StatelessWidget {
  final AppController controller;
  final String guildId;

  const GuildPanelModal({
    super.key,
    required this.controller,
    required this.guildId,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final Guild guild = controller.guilds.firstWhere(
          (g) => g.id == guildId,
          orElse: () => controller.guilds.first,
        );
        final ratio = (guild.boostPoints / guild.boostGoal).clamp(0.0, 1.0);

        return ArcanaModalScaffold(
          svgIcon: ArcanaSvgIcons.shield,
          title: guild.name.toUpperCase(),
          subtitle: 'Tag [${guild.tag}] • Líder ${guild.leaderHandle}',
          badgeLabel: 'SHARED WORLD',
          badgeColor: p.goldPrimary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeraldicCard(
                goldAccent: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(guild.description),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        HeraldicChipPill(
                          label: '${guild.memberCount} Membros',
                          color: p.infoBlue,
                        ),
                        HeraldicChipPill(
                          label: '${guild.activeTablesCount} Mesas Ativas',
                          color: p.emerald,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              HeraldicCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Guild Boost Comunitário',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${guild.boostPoints} / ${guild.boostGoal}',
                          style: TextStyle(
                            color: p.goldPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(99),
                      color: p.goldPrimary,
                      backgroundColor: p.surfaceElevated,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${guild.sharedWorldName} — ${guild.currentSeason}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              PrimaryGoldPillButton(
                label: 'Impulsionar Guilda (+50 Pontos)',
                svgIcon: ArcanaSvgIcons.flame,
                onPressed: () => controller.contributeGuildBoost(guild.id, 50),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Modal para Criar Novo Tópico no Fórum da Comunidade.
class CreateForumTopicModal extends StatefulWidget {
  final AppController controller;

  const CreateForumTopicModal({super.key, required this.controller});

  @override
  State<CreateForumTopicModal> createState() => _CreateForumTopicModalState();
}

class _CreateForumTopicModalState extends State<CreateForumTopicModal> {
  String _category = 'Regras & Oficina';
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _bodyCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.messageSquare,
      title: 'NOVO TÓPICO NO FÓRUM',
      subtitle: 'Compartilhe guias, dúvidas ou convites com a comunidade',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Categoria'),
            items: const [
              DropdownMenuItem(value: 'Regras & Oficina', child: Text('Regras & Oficina')),
              DropdownMenuItem(value: 'Narrativa', child: Text('Narrativa')),
              DropdownMenuItem(value: 'Recrutamento', child: Text('Recrutamento')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Título do Tópico',
              hintText: 'Ex: Dicas para combates rápidos em AlphaD6',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Conteúdo',
              hintText: 'Escreva sua publicação...',
            ),
          ),
          const SizedBox(height: 16),
          PrimaryGoldPillButton(
            label: 'Publicar Tópico',
            svgIcon: ArcanaSvgIcons.check,
            onPressed: () {
              widget.controller.createForumTopic(
                category: _category,
                title: _titleCtrl.text.trim().isEmpty
                    ? 'Discussão sobre mesas AlphaD6'
                    : _titleCtrl.text.trim(),
                content: _bodyCtrl.text.trim().isEmpty
                    ? 'Tópico aberto na comunidade ArcanaVTT.'
                    : _bodyCtrl.text.trim(),
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

