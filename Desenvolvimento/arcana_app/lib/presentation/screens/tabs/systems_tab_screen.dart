import 'package:flutter/material.dart';
import '../../../controllers/app_controller.dart';
import '../../../core/constants/svg_icons.dart';
import '../../../core/theme/arcana_colors.dart';
import '../../../domain/entities/arcana_entities.dart';
import '../../modals/modal_shell.dart';
import '../../modals/system_modals.dart';
import '../../widgets/heraldic_buttons.dart';
import '../../widgets/heraldic_card.dart';
import '../../widgets/heraldic_section_divider.dart';
import '../../widgets/svg_icon_widget.dart';

/// Aba 3 — Sistemas & Compêndio Inteligente (Ocultação Automática de Categorias Vazias).
class SystemsTabScreen extends StatefulWidget {
  final AppController controller;

  const SystemsTabScreen({super.key, required this.controller});

  @override
  State<SystemsTabScreen> createState() => _SystemsTabScreenState();
}

class _SystemsTabScreenState extends State<SystemsTabScreen> {
  int _segmentIdx = 0;
  String _search = '';
  String _selectedSystemForCompendium = 'sys_alphad6_v24';
  CompendiumCategory? _selectedCategory;

  static const _segments = ['Oficiais', 'Próprios', 'Meus', 'Comunidade'];

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final ctrl = widget.controller;

    final filteredSystems = ctrl.systems.where((sys) {
      if (_search.trim().isNotEmpty &&
          !sys.name.toLowerCase().contains(_search.trim().toLowerCase())) {
        return false;
      }
      switch (_segmentIdx) {
        case 0:
          return sys.segment == SystemSegment.oficiais;
        case 1:
          return sys.segment == SystemSegment.proprios;
        case 2:
          return sys.segment == SystemSegment.proprios || sys.isOfficial;
        default:
          return sys.segment == SystemSegment.comunidade;
      }
    }).toList();

    final compResult = ctrl.queryCompendium(
      systemId: _selectedSystemForCompendium,
      category: _selectedCategory,
      searchQuery: _search,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Buscar sistema ou item...',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SvgIconWidget(ArcanaSvgIcons.search, size: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SecondaryHeraldicButton(
              label: _selectedCategory?.labelPtBr ?? 'Categorias',
              svgIcon: ArcanaSvgIcons.filter,
              borderColor: p.goldBorder,
              onPressed: () => showArcanaModal(
                context,
                builder: (_) => SystemFiltersModal(
                  availableCategories: compResult.visibleCategories,
                  selected: _selectedCategory,
                  onSelect: (cat) => setState(() => _selectedCategory = cat),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        HeraldicSegmentBar(
          segments: _segments,
          selectedIndex: _segmentIdx,
          onSelected: (idx) => setState(() => _segmentIdx = idx),
        ),
        const SizedBox(height: 12),
        PrimaryGoldPillButton(
          label: 'Forjar Sistema Próprio (Homebrew JSON)',
          svgIcon: ArcanaSvgIcons.sparkles,
          onPressed: () => showArcanaModal(
            context,
            builder: (_) => SystemForgeModal(controller: ctrl),
          ),
        ),
        const SizedBox(height: 14),
        ...filteredSystems.map(
          (sys) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HeraldicCard(
              goldAccent: sys.isOfficial,
              onTap: () => setState(() {
                _selectedSystemForCompendium = sys.id;
                _selectedCategory = null;
              }),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${sys.name} (${sys.version})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      HeraldicChipPill(
                        label: sys.isOfficial ? 'OFICIAL' : 'MOTOR ${sys.diceEngine.toUpperCase()}',
                        color: sys.isOfficial ? p.goldPrimary : p.infoBlue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(sys.description, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${sys.downloadsCount} mesas • Nota ${sys.rating}',
                        style: TextStyle(fontSize: 11, color: p.textSecondary),
                      ),
                      SecondaryHeraldicButton(
                        label: 'Inspecionar',
                        svgIcon: ArcanaSvgIcons.bookOpen,
                        onPressed: () => showArcanaModal(
                          context,
                          builder: (_) => SystemPreviewModal(
                            controller: ctrl,
                            system: sys,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const HeraldicSectionDivider(
          svgIcon: ArcanaSvgIcons.flaskConical,
          title: 'COMPÊNDIO INTELIGENTE',
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ctrl.systems.map((sys) {
              final active = sys.id == _selectedSystemForCompendium;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(sys.name),
                  selected: active,
                  onSelected: (_) => setState(() {
                    _selectedSystemForCompendium = sys.id;
                    _selectedCategory = null;
                  }),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: compResult.visibleCategories.map((cat) {
            final count = compResult.counts[cat] ?? 0;
            return FilterChip(
              label: Text('${cat.labelPtBr} ($count)'),
              selected: _selectedCategory == cat,
              onSelected: (sel) =>
                  setState(() => _selectedCategory = sel ? cat : null),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
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
                        child: Text(item.name,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      HeraldicChipPill(
                        label: item.category.labelPtBr,
                        color: p.emerald,
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
    );
  }
}

