import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/svg_icons.dart';
import '../../core/theme/arcana_colors.dart';
import '../../domain/entities/arcana_entities.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/heraldic_card.dart';
import '../widgets/heraldic_section_divider.dart';
import 'modal_shell.dart';

/// Modal de Preview Detalhado do Sistema (ex: AlphaD6 Core v2.4) + Ocultação de Categorias Vazias.
class SystemPreviewModal extends StatelessWidget {
  final AppController controller;
  final RpgSystem system;

  const SystemPreviewModal({
    super.key,
    required this.controller,
    required this.system,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final compResult = controller.queryCompendium(systemId: system.id);

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.bookOpen,
      title: system.name.toUpperCase(),
      subtitle: 'Versão ${system.version} • Motor ${system.diceEngine}',
      badgeLabel: system.isOfficial ? 'OFICIAL' : 'COMUNIDADE',
      badgeColor: system.isOfficial ? p.goldPrimary : p.infoBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeraldicCard(
            goldAccent: system.isOfficial,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(system.description),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: system.attributes
                      .map((a) => HeraldicChipPill(label: a, color: p.goldPrimary))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const HeraldicSectionDivider(
            svgIcon: ArcanaSvgIcons.flaskConical,
            title: 'CATEGORIAS ATIVAS DO COMPÊNDIO',
          ),
          Text(
            'Regra inteligente: apenas categorias populadas aparecem abaixo.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: compResult.visibleCategories.map((cat) {
              final count = compResult.counts[cat] ?? 0;
              return HeraldicChipPill(
                label: '${cat.labelPtBr} ($count)',
                color: p.emerald,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          ...compResult.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: HeraldicCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        HeraldicChipPill(
                          label: item.category.labelPtBr.toUpperCase(),
                          color: p.infoBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item.description, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal de Filtro Inteligente do Compêndio (oculta automaticamente categorias com 0 itens).
class SystemFiltersModal extends StatelessWidget {
  final List<CompendiumCategory> availableCategories;
  final CompendiumCategory? selected;
  final ValueChanged<CompendiumCategory?> onSelect;

  const SystemFiltersModal({
    super.key,
    required this.availableCategories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.filter,
      title: 'FILTROS DO COMPÊNDIO',
      subtitle: 'Categorias vazias são ocultadas automaticamente',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Todas Ativas'),
            selected: selected == null,
            onSelected: (_) {
              onSelect(null);
              Navigator.of(context).pop();
            },
          ),
          ...availableCategories.map(
            (cat) => ChoiceChip(
              label: Text(cat.labelPtBr),
              selected: selected == cat,
              onSelected: (_) {
                onSelect(cat);
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal de Forja de Sistema Próprio (Homebrew JSON Delta).
class SystemForgeModal extends StatefulWidget {
  final AppController controller;

  const SystemForgeModal({super.key, required this.controller});

  @override
  State<SystemForgeModal> createState() => _SystemForgeModalState();
}

class _SystemForgeModalState extends State<SystemForgeModal> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _attrsCtrl =
      TextEditingController(text: 'Vigor, Astúcia, Vontade');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _attrsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.sparkles,
      title: 'FORJA DE SISTEMA PRÓPRIO',
      subtitle: 'Crie motores de regras com Deltas JSON leves',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nome do Sistema Homebrew',
              hintText: 'Ex: Sombras de Basalto 3d6',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _attrsCtrl,
            decoration: const InputDecoration(
              labelText: 'Atributos Base (separados por vírgula)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Resumo das Regras',
              hintText: 'Explique a mecânica central do seu sistema...',
            ),
          ),
          const SizedBox(height: 16),
          PrimaryGoldPillButton(
            label: 'Publicar nos Meus Sistemas',
            svgIcon: ArcanaSvgIcons.sparkles,
            onPressed: () {
              final attrs = _attrsCtrl.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              widget.controller.createCustomSystem(
                name: _nameCtrl.text.trim().isEmpty
                    ? 'Sistema Forjado 3d6'
                    : _nameCtrl.text.trim(),
                description: _descCtrl.text.trim().isEmpty
                    ? 'Motor homebrew personalizado com suporte modular.'
                    : _descCtrl.text.trim(),
                attributes: attrs.isEmpty ? ['Corpo', 'Mente', 'Espírito'] : attrs,
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

