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
        if (controller.guilds.isEmpty) {
          return ArcanaModalScaffold(
            svgIcon: ArcanaSvgIcons.shield,
            title: 'GUILDA NÃO ENCONTRADA',
            subtitle: 'Nenhuma guilda registrada na sua conta no momento',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HeraldicCard(
                  child: Text(
                    'Funde uma nova guilda na aba Comunidades para habilitar o mundo compartilhado e campanhas vinculadas.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryGoldPillButton(
                  label: 'Fundar Nova Guilda',
                  svgIcon: ArcanaSvgIcons.plus,
                  onPressed: () {
                    Navigator.of(context).pop();
                    showArcanaModal(
                      context,
                      builder: (_) => CreateGuildModal(controller: controller),
                    );
                  },
                ),
              ],
            ),
          );
        }

        final Guild guild = controller.guilds.firstWhere(
          (g) => g.id == guildId,
          orElse: () => controller.guilds.first,
        );
        final ratio =
            (guild.boostGoal <= 0 ? 0.0 : guild.boostPoints / guild.boostGoal)
                .clamp(0.0, 1.0);

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
            onPressed: () async {
              await widget.controller.createForumTopic(
                category: _category,
                title: _titleCtrl.text.trim().isEmpty
                    ? 'Discussão sobre mesas AlphaD6'
                    : _titleCtrl.text.trim(),
                content: _bodyCtrl.text.trim().isEmpty
                    ? 'Tópico aberto na comunidade ArcanaVTT.'
                    : _bodyCtrl.text.trim(),
              );
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

/// Modal para Fundar uma Nova Guilda sincronizada no Cloudflare D1.
class CreateGuildModal extends StatefulWidget {
  final AppController controller;

  const CreateGuildModal({super.key, required this.controller});

  @override
  State<CreateGuildModal> createState() => _CreateGuildModalState();
}

class _CreateGuildModalState extends State<CreateGuildModal> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _tagCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _worldCtrl =
      TextEditingController(text: 'Continente de Valen');

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tagCtrl.dispose();
    _descCtrl.dispose();
    _worldCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final tag = _tagCtrl.text.trim().toUpperCase();
    if (name.length < 3) {
      setState(() => _error = 'Nome da guilda precisa ter ao menos 3 caracteres.');
      return;
    }
    if (tag.length < 2 || tag.length > 5) {
      setState(() => _error = 'A tag da guilda deve ter de 2 a 5 caracteres.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final ok = await widget.controller.createGuild(
      name: name,
      tag: tag,
      description: _descCtrl.text.trim().isEmpty
          ? 'Guilda fundada na Taverna para mesas compartilhadas.'
          : _descCtrl.text.trim(),
      sharedWorldName: _worldCtrl.text.trim().isEmpty
          ? 'Continente de Valen'
          : _worldCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = widget.controller.lastSyncError ??
            'Falha ao fundar guilda no servidor.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.shield,
      title: 'FUNDAR NOVA GUILDA',
      subtitle: 'Inaugure um Shared World e convide mestres e heróis',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nome da Guilda',
              hintText: 'Ex: Ordem da Chama Dourada',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _tagCtrl,
            textCapitalization: TextCapitalization.characters,
            maxLength: 5,
            decoration: const InputDecoration(
              labelText: 'Tag da Guilda (2 a 5 letras)',
              hintText: 'Ex: ORDE',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _worldCtrl,
            decoration: const InputDecoration(
              labelText: 'Nome do Mundo Compartilhado',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Descrição / Juramento da Guilda',
              hintText: 'Foco em one-shots ou crônicas semanais...',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: p.crimson, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          PrimaryGoldPillButton(
            label: _saving ? 'Fundando Guilda...' : 'Fundar Guilda no D1',
            svgIcon: ArcanaSvgIcons.check,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

