import 'package:flutter/material.dart';
import '../../../controllers/app_controller.dart';
import '../../../core/constants/svg_icons.dart';
import '../../../core/theme/arcana_colors.dart';
import '../../../domain/entities/arcana_entities.dart';
import '../../modals/modal_shell.dart';
import '../../modals/system_modals.dart';
import '../../widgets/heraldic_buttons.dart';
import '../../widgets/heraldic_card.dart';
import '../../widgets/svg_icon_widget.dart';

class SystemsTabScreen extends StatefulWidget {
  final AppController controller;

  const SystemsTabScreen({super.key, required this.controller});

  @override
  State<SystemsTabScreen> createState() => _SystemsTabScreenState();
}

class _SystemsTabScreenState extends State<SystemsTabScreen> {
  int _segmentIndex = 0; // Oficiais, Proprios, Meus, Comunidade
  String _searchQuery = '';
  bool _onlyFavorites = false;

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final ctrl = widget.controller;
    final selectedSeg = SystemSegment.values[_segmentIndex];

    final filtered = ctrl.systems.where((s) {
      if (_segmentIndex == 2) {
        if (s.authorId != ctrl.currentUser.id && !s.isFavorite) return false;
      } else if (s.segment != selectedSeg) {
        return false;
      }
      if (_onlyFavorites && !s.isFavorite) return false;
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return s.name.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeraldicSegmentBar(
          segments: const ['Oficiais', 'Proprios', 'Meus', 'Comunidade'],
          selectedIndex: _segmentIndex,
          onSelected: (idx) => setState(() => _segmentIndex = idx),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Pesquisar sistemas, compendios ou motores...',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SvgIconWidget(ArcanaSvgIcons.search, size: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SecondaryHeraldicButton(
              label: _onlyFavorites ? 'Favoritos' : 'Todos',
              svgIcon: ArcanaSvgIcons.heart,
              borderColor: _onlyFavorites ? p.goldPrimary : null,
              onPressed: () => setState(() => _onlyFavorites = !_onlyFavorites),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PrimaryGoldPillButton(
          label: 'Forjar Sistema (Key de Criacao / Admin)',
          svgIcon: ArcanaSvgIcons.sparkles,
          expand: true,
          onPressed: () => showArcanaModal(context,
            builder: (_) => SystemForgeModal(controller: ctrl),
          ),
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          HeraldicCard(
            child: Column(
              children: [
                SvgIconWidget(ArcanaSvgIcons.scroll, size: 32, color: p.goldPrimary),
                const SizedBox(height: 8),
                Text(
                  'Catalogo Dinamico de Sistemas',
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nenhum sistema cadastrado nesta aba ainda. O ArcanaVTT nao pre-define regras engessadas: forje seu sistema com atributos proprios ou importe da comunidade.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
              ],
            ),
          )
        else
          for (final sys in filtered) ...[
            HeraldicCard(
              goldAccent: sys.isOfficial,
              onTap: () => showArcanaModal(context,
                builder: (_) => SystemPreviewModal(controller: ctrl, system: sys),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      HeraldicChipPill(
                        label: sys.isOfficial ? 'OFICIAL' : 'HOMEBREW',
                        color: sys.isOfficial ? p.goldPrimary : p.infoBlue,
                      ),
                      const SizedBox(width: 6),
                      HeraldicChipPill(label: sys.diceEngine, color: p.emerald),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Favoritar Sistema',
                        onPressed: () => ctrl.toggleFavoriteSystem(sys.id),
                        icon: SvgIconWidget(
                          ArcanaSvgIcons.heart,
                          size: 18,
                          color: sys.isFavorite ? p.crimson : p.textSecondary,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Salvar Cache Offline',
                        onPressed: () => ctrl.toggleOfflineCacheSystem(sys.id),
                        icon: SvgIconWidget(
                          ArcanaSvgIcons.download,
                          size: 18,
                          color: sys.isOfflineCached ? p.emerald : p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${sys.name} (${sys.version})',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sys.description,
                    style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: sys.attributes
                        .map((a) => HeraldicChipPill(label: a, color: p.goldHighlight))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  SecondaryHeraldicButton(
                    label: 'Abrir Compendio & Delta',
                    svgIcon: ArcanaSvgIcons.bookOpen,
                    expand: true,
                    onPressed: () => showArcanaModal(context,
                      builder: (_) => SystemPreviewModal(controller: ctrl, system: sys),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}
