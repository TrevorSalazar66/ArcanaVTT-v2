import 'package:flutter/material.dart';
import '../../../controllers/app_controller.dart';
import '../../../core/constants/svg_icons.dart';
import '../../../core/security/rbac_guard.dart';
import '../../../core/theme/arcana_colors.dart';
import '../../../domain/entities/arcana_entities.dart';
import '../../modals/campaign_modals.dart';
import '../../modals/modal_shell.dart';
import '../../widgets/heraldic_buttons.dart';
import '../../widgets/heraldic_card.dart';
import '../../widgets/svg_icon_widget.dart';

/// Aba 2 — Campanhas (Jogando, Auxiliar, Mestre, Explorar).
class CampaignsTabScreen extends StatefulWidget {
  final AppController controller;

  const CampaignsTabScreen({super.key, required this.controller});

  @override
  State<CampaignsTabScreen> createState() => _CampaignsTabScreenState();
}

class _CampaignsTabScreenState extends State<CampaignsTabScreen> {
  int _segmentIdx = 0;
  String _search = '';
  String _modeFilter = 'Todas';

  static const _segments = ['Jogando', 'Auxiliar', 'Mestre', 'Explorar'];

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final ctrl = widget.controller;
    final canForge = RbacGuard.canForgeCampaign(ctrl.currentUser.role);

    final filtered = ctrl.campaigns.where((cmp) {
      final matchesSearch = _search.trim().isEmpty ||
          cmp.title.toLowerCase().contains(_search.trim().toLowerCase()) ||
          cmp.quickJoinCode.toLowerCase().contains(_search.trim().toLowerCase());
      if (!matchesSearch) return false;

      if (_modeFilter == 'Ao Vivo' && cmp.mode != CampaignMode.aoVivo) return false;
      if (_modeFilter == 'Tempo Livre' && cmp.mode != CampaignMode.tempoLivre) {
        return false;
      }
      if (_modeFilter == 'Agendada' && cmp.mode != CampaignMode.agendada) return false;

      switch (_segmentIdx) {
        case 0:
          return cmp.userRelation == CampaignSegment.jogando;
        case 1:
          return cmp.userRelation == CampaignSegment.auxiliar;
        case 2:
          return cmp.userRelation == CampaignSegment.mestre;
        default:
          return cmp.isPublic;
      }
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Buscar mesa ou código...',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SvgIconWidget(ArcanaSvgIcons.search, size: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SecondaryHeraldicButton(
              label: _modeFilter == 'Todas' ? 'Filtros' : _modeFilter,
              svgIcon: ArcanaSvgIcons.filter,
              borderColor: p.goldBorder,
              onPressed: () => showArcanaModal(
                context,
                builder: (_) => CampaignFiltersModal(
                  currentModeFilter: _modeFilter,
                  onApplyFilter: (val) => setState(() => _modeFilter = val),
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
        if (canForge) ...[
          const SizedBox(height: 12),
          PrimaryGoldPillButton(
            label: 'Forjar Nova Campanha (4 Etapas)',
            svgIcon: ArcanaSvgIcons.plus,
            onPressed: () => showArcanaModal(
              context,
              builder: (_) => CreateCampaignWizardModal(controller: ctrl),
            ),
          ),
        ],
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          HeraldicCard(
            child: Column(
              children: [
                SvgIconWidget(ArcanaSvgIcons.scroll, size: 32, color: p.textSecondary),
                const SizedBox(height: 8),
                Text(
                  'Nenhuma campanha nesta seção para o filtro selecionado.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          )
        else
          ...filtered.map(
            (cmp) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HeraldicCard(
                goldAccent: cmp.mode == CampaignMode.aoVivo,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        HeraldicChipPill(
                          label: cmp.modeBadge,
                          color: cmp.mode == CampaignMode.aoVivo
                              ? p.emerald
                              : p.goldPrimary,
                        ),
                        HeraldicChipPill(
                          label: 'CÓD: ${cmp.quickJoinCode}',
                          color: p.infoBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(cmp.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(cmp.synopsis, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${cmp.systemName} • ${cmp.masterHandle}',
                          style: TextStyle(fontSize: 11, color: p.textSecondary),
                        ),
                        Text(
                          '${cmp.occupiedSlots}/${cmp.maxSlots} Vagas',
                          style: TextStyle(
                            fontSize: 12,
                            color: p.goldPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryHeraldicButton(
                            label: 'Abrir Hub da Mesa',
                            svgIcon: ArcanaSvgIcons.externalLink,
                            borderColor: p.goldBorder,
                            onPressed: () => showArcanaModal(
                              context,
                              builder: (_) => CampaignGeneralModal(
                                controller: ctrl,
                                campaign: cmp,
                              ),
                            ),
                          ),
                        ),
                        if (_segmentIdx == 3) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: PrimaryGoldPillButton(
                              label: 'Candidatar-se',
                              svgIcon: ArcanaSvgIcons.feather,
                              onPressed: () => showArcanaModal(
                                context,
                                builder: (_) => CampaignApplicationModal(
                                  campaign: cmp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

