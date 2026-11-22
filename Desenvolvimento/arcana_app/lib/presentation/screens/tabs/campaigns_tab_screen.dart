import 'package:flutter/material.dart';
import '../../../controllers/app_controller.dart';
import '../../../core/constants/svg_icons.dart';
import '../../../core/security/rbac_guard.dart';
import '../../../core/theme/arcana_colors.dart';
import '../../../domain/entities/arcana_entities.dart';
import '../../modals/campaign_modals.dart';
import '../../modals/modal_shell.dart';
import '../../modals/profile_and_nav_modals.dart';
import '../../widgets/heraldic_buttons.dart';
import '../../widgets/heraldic_card.dart';
import '../../widgets/svg_icon_widget.dart';

class CampaignsTabScreen extends StatefulWidget {
  final AppController controller;

  const CampaignsTabScreen({super.key, required this.controller});

  @override
  State<CampaignsTabScreen> createState() => _CampaignsTabScreenState();
}

class _CampaignsTabScreenState extends State<CampaignsTabScreen> {
  int _segmentIndex = 0; // Jogando, Auxiliar, Mestre, Explorar
  String _searchQuery = '';
  CampaignMode? _modeFilter;
  String? _systemIdFilter;
  String? _ageRatingFilter;
  String? _tagFilter;
  bool _onlyOpenSlots = false;

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final ctrl = widget.controller;
    final targetRelation = CampaignSegment.values[_segmentIndex];
    final canCreate = RbacGuard.canForgeCampaign(ctrl.currentUser.role);

    final filtered = ctrl.campaigns.where((c) {
      if (_segmentIndex == 3) {
        if (!c.isPublic) return false;
      } else {
        if (c.userRelation != targetRelation) return false;
      }
      if (_modeFilter != null && c.mode != _modeFilter) return false;
      if (_systemIdFilter != null && c.systemId != _systemIdFilter) return false;
      if (_ageRatingFilter != null && c.ageRating != _ageRatingFilter) return false;
      if (_tagFilter != null && !c.tags.contains(_tagFilter)) return false;
      if (_onlyOpenSlots && c.occupiedSlots >= c.maxSlots) return false;

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final hay =
            '${c.title} ${c.synopsis} ${c.masterHandle} ${c.systemName} ${c.quickJoinCode} ${c.tags.join(' ')}'
                .toLowerCase();
        return hay.contains(q);
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeraldicSegmentBar(
          segments: const ['Jogando', 'Auxiliar', 'Mestre', 'Explorar'],
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
                  hintText: 'Buscar titulo, @mestre, #tag, sistema...',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SvgIconWidget(ArcanaSvgIcons.search, size: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SecondaryHeraldicButton(
              label: 'Filtros',
              svgIcon: ArcanaSvgIcons.filter,
              onPressed: () => showArcanaModal(context,
                builder: (_) => CampaignFiltersModal(
                  currentModeFilter: _modeFilter,
                  currentSystemId: _systemIdFilter,
                  currentAgeRating: _ageRatingFilter,
                  currentTag: _tagFilter,
                  onlyOpenSlots: _onlyOpenSlots,
                  availableSystems: ctrl.systems,
                  onApplyFilter: ({
                    CampaignMode? mode,
                    String? systemId,
                    String? ageRating,
                    String? tag,
                    bool openSlotsOnly = false,
                  }) {
                    setState(() {
                      _modeFilter = mode;
                      _systemIdFilter = systemId;
                      _ageRatingFilter = ageRating;
                      _tagFilter = tag;
                      _onlyOpenSlots = openSlotsOnly;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (canCreate) ...[
          PrimaryGoldPillButton(
            label: 'Forjar Nova Campanha',
            svgIcon: ArcanaSvgIcons.wand2,
            expand: true,
            onPressed: () => showArcanaModal(context,
              builder: (_) => CreateCampaignWizardModal(controller: ctrl),
            ),
          ),
          const SizedBox(height: 14),
        ] else ...[
          HeraldicCard(
            child: Row(
              children: [
                SvgIconWidget(ArcanaSvgIcons.info, size: 18, color: p.goldPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'A criacao de mesas requer patente Mestre ou superior. Solicite a um Administrador ou candidate-se na aba Explorar.',
                    style: TextStyle(fontSize: 12, color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (filtered.isEmpty)
          HeraldicCard(
            child: Column(
              children: [
                SvgIconWidget(ArcanaSvgIcons.scroll, size: 32, color: p.textSecondary),
                const SizedBox(height: 8),
                Text(
                  'Nenhuma mesa nesta categoria',
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _segmentIndex == 3
                      ? 'Ainda nao ha mesas publicas visiveis.'
                      : 'Use Explorar ou Quick Join (codigo 6 digitos) para encontrar mesas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
              ],
            ),
          )
        else
          for (final cmp in filtered) ...[
            _buildCampaignCard(context, p, ctrl, cmp),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  String _campaignIconSvg(String iconName) {
    switch (iconName) {
      case 'shield':
        return ArcanaSvgIcons.shield;
      case 'crown':
        return ArcanaSvgIcons.crown;
      case 'skull':
        return ArcanaSvgIcons.skull;
      case 'flame':
        return ArcanaSvgIcons.flame;
      case 'scroll':
        return ArcanaSvgIcons.scroll;
      default:
        return ArcanaSvgIcons.swords;
    }
  }

  Widget _buildCampaignCard(
    BuildContext context,
    ArcanaPalette p,
    AppController ctrl,
    Campaign cmp,
  ) {
    final canOpenHub =
        cmp.userRelation != CampaignSegment.explorar || ctrl.ghostSpectatorActive;

    return HeraldicCard(
      goldAccent: cmp.mode == CampaignMode.aoVivo,
      onTap: canOpenHub
          ? () => showArcanaModal(context,
                builder: (_) => CampaignGeneralModal(controller: ctrl, campaign: cmp),
              )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HeraldicChipPill(
                label: cmp.modeBadge,
                color: cmp.mode == CampaignMode.aoVivo ? p.emerald : p.infoBlue,
              ),
              const SizedBox(width: 6),
              HeraldicChipPill(label: cmp.ageRating, color: p.goldPrimary),
              if (cmp.isInactiveArchived) ...[
                const SizedBox(width: 6),
                HeraldicChipPill(label: 'ARQUIVADA 75D', color: p.crimson),
              ],
              const Spacer(),
              Text(
                '${cmp.occupiedSlots}/${cmp.maxSlots} vagas · ${cmp.quickJoinCode}',
                style: TextStyle(fontSize: 11.5, color: p.goldHighlight),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.goldBorder),
                ),
                child: SvgIconWidget(
                  _campaignIconSvg(cmp.iconName),
                  size: 20,
                  color: p.goldHighlight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cmp.title,
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => showArcanaModal(context,
                        builder: (_) => SocialProfileModal(
                          controller: ctrl,
                          targetUserId: cmp.ownerId.isNotEmpty ? cmp.ownerId : null,
                          targetUsername: cmp.masterHandle,
                        ),
                      ),
                      child: Text(
                        '${cmp.systemName} · Mestre ${cmp.masterHandle} (ver perfil)',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: p.goldPrimary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            cmp.synopsis,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, color: p.textSecondary),
          ),
          if (cmp.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: cmp.tags
                  .map((t) => HeraldicChipPill(label: '#$t', color: p.textSecondary))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cmp.scheduleText,
                style: TextStyle(fontSize: 11.5, color: p.textSecondary),
              ),
              if (canOpenHub)
                SecondaryHeraldicButton(
                  label: ctrl.ghostSpectatorActive &&
                          cmp.userRelation == CampaignSegment.explorar
                      ? 'Auditar (Fantasma)'
                      : 'Abrir Hub da Mesa',
                  svgIcon: ArcanaSvgIcons.scroll,
                  onPressed: () => showArcanaModal(context,
                    builder: (_) => CampaignGeneralModal(controller: ctrl, campaign: cmp),
                  ),
                )
              else
                PrimaryGoldPillButton(
                  label: 'Candidatar-se',
                  svgIcon: ArcanaSvgIcons.feather,
                  onPressed: () => showArcanaModal(context,
                    builder: (_) =>
                        CampaignApplicationModal(controller: ctrl, campaign: cmp),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
