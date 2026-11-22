import 'package:flutter/material.dart';
import '../../../controllers/app_controller.dart';
import '../../../core/constants/svg_icons.dart';
import '../../../core/security/rbac_guard.dart';
import '../../../core/theme/arcana_colors.dart';
import '../../../domain/entities/arcana_entities.dart';
import '../../modals/campaign_modals.dart';
import '../../modals/community_hub_modals.dart';
import '../../modals/hero_sheet_highlight_modal.dart';
import '../../modals/modal_shell.dart';
import '../../modals/profile_and_nav_modals.dart';
import '../../modals/quick_join_modal.dart';
import '../../widgets/heraldic_buttons.dart';
import '../../widgets/heraldic_card.dart';
import '../../widgets/heraldic_section_divider.dart';
import '../../widgets/svg_icon_widget.dart';

class HomeTabScreen extends StatelessWidget {
  final AppController controller;

  const HomeTabScreen({super.key, required this.controller});

  String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final user = controller.currentUser;
    final activeLiveOrFreeTables = controller.campaigns
        .where((c) =>
            c.userRelation != CampaignSegment.explorar &&
            (c.mode == CampaignMode.aoVivo || c.mode == CampaignMode.tempoLivre))
        .toList();
    final hero = controller.hero;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 28 : 16,
        vertical: 16,
      ),
      children: [
        // Banner Saudacao Dinamica (Hora + Cargo) + Atalho para Perfil Social
        HeraldicCard(
          goldAccent: true,
          onTap: () => showArcanaModal(context,
            builder: (_) => SocialProfileModal(controller: controller),
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
                  user.role == UserRole.superadmin || user.role == UserRole.admin
                      ? ArcanaSvgIcons.crown
                      : ArcanaSvgIcons.shield,
                  size: 24,
                  color: p.goldHighlight,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_timeGreeting()}, ${user.role.badgeLabel.toLowerCase()}',
                      style: TextStyle(fontSize: 12, color: p.goldPrimary),
                    ),
                    Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RoleBadgeWidget(role: user.role),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '@${user.username}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: p.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SvgIconWidget(ArcanaSvgIcons.chevronRight, size: 18, color: p.goldPrimary),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick Join (Codigo 6 digitos -> sempre Candidatura se nao membro)
        const HeraldicSectionDivider(
          svgIcon: ArcanaSvgIcons.qrCode,
          title: 'Entrada Rapida (Quick Join)',
        ),
        HeraldicCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Digite o codigo de 6 caracteres para localizar ou se candidatar a uma mesa.',
                style: TextStyle(fontSize: 12.5, color: p.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PrimaryGoldPillButton(
                      label: 'Inserir Codigo da Mesa',
                      svgIcon: ArcanaSvgIcons.key,
                      expand: true,
                      onPressed: () => showArcanaModal(context,
                        builder: (_) => QuickJoinModal(controller: controller),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SecondaryHeraldicButton(
                    label: 'QR',
                    svgIcon: ArcanaSvgIcons.qrCode,
                    onPressed: () => showArcanaModal(context,
                      builder: (_) => QuickJoinModal(controller: controller),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Carrossel Mesas Ativas (estritamente AO VIVO / FREE TIME do usuario)
        HeraldicSectionDivider(
          svgIcon: ArcanaSvgIcons.scroll,
          title: 'Mesas Ativas (Ao Vivo & Free Time)',
        ),
        if (activeLiveOrFreeTables.isEmpty)
          HeraldicCard(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.surfaceElevated,
                    border: Border.all(color: p.goldBorder),
                  ),
                  child: SvgIconWidget(ArcanaSvgIcons.dices, size: 28, color: p.goldPrimary),
                ),
                const SizedBox(height: 10),
                Text(
                  'Nenhuma sessao Ao Vivo ou Free Time no momento',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Entre via Quick Join, aceite um convite direto do Mestre ou explore mesas publicas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (RbacGuard.canForgeCampaign(user.role))
                      Expanded(
                        child: PrimaryGoldPillButton(
                          label: 'Forjar Mesa',
                          svgIcon: ArcanaSvgIcons.wand2,
                          expand: true,
                          onPressed: () => showArcanaModal(context,
                            builder: (_) =>
                                CreateCampaignWizardModal(controller: controller),
                          ),
                        ),
                      ),
                    if (RbacGuard.canForgeCampaign(user.role)) const SizedBox(width: 10),
                    Expanded(
                      child: SecondaryHeraldicButton(
                        label: 'Explorar Taverna',
                        svgIcon: ArcanaSvgIcons.search,
                        expand: true,
                        onPressed: () => controller.setTabIndex(1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 215,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: activeLiveOrFreeTables.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final cmp = activeLiveOrFreeTables[index];
                final tableHero = controller.characterForCampaign(cmp.id);
                return SizedBox(
                  width: 300,
                  child: HeraldicCard(
                    goldAccent: cmp.mode == CampaignMode.aoVivo,
                    onTap: () => showArcanaModal(context,
                      builder: (_) => CampaignGeneralModal(
                        controller: controller,
                        campaign: cmp,
                      ),
                    ),
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
                                  : p.infoBlue,
                            ),
                            Text(
                              cmp.quickJoinCode,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: p.goldPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cmp.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                          ),
                        ),
                        Text(
                          '${cmp.systemName} · ${cmp.chapterTitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: p.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: p.subtleBorder),
                          ),
                          child: Row(
                            children: [
                              SvgIconWidget(
                                ArcanaSvgIcons.sword,
                                size: 14,
                                color: p.goldPrimary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  tableHero != null
                                      ? '${tableHero.name} (Nv.${tableHero.level})'
                                      : 'Nenhuma ficha vinculada ainda',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: p.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${cmp.occupiedSlots}/${cmp.maxSlots} jogadores',
                              style: TextStyle(fontSize: 11, color: p.textSecondary),
                            ),
                            Text(
                              'Entrar na Mesa ->',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: p.goldHighlight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 18),

        // Herois em Destaque (vinculados estritamente a campanhas)
        const HeraldicSectionDivider(
          svgIcon: ArcanaSvgIcons.swords,
          title: 'Seus Herois Vinculados',
        ),
        if (hero == null)
          HeraldicCard(
            child: Row(
              children: [
                SvgIconWidget(ArcanaSvgIcons.shield, size: 26, color: p.goldPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nenhum Heroi Criado',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Fichas nascem dentro de uma campanha ativa (maximo 1 heroi por mesa).',
                        style: TextStyle(fontSize: 12, color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          HeraldicCard(
            onTap: () => showArcanaModal(context,
              builder: (_) => HeroSheetHighlightModal(controller: controller),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.goldBorder),
                  ),
                  child: SvgIconWidget(ArcanaSvgIcons.sword, size: 22, color: p.goldHighlight),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${hero.name} · Nv.${hero.level}',
                        style: TextStyle(
                          fontFamily: 'Cinzel',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: p.textPrimary,
                        ),
                      ),
                      Text(
                        '${hero.heroClass} · ${hero.campaignTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: p.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'PV ${hero.hpCurrent}/${hero.hpMax}',
                            style: TextStyle(
                              fontSize: 12,
                              color: p.emerald,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Anima ${hero.animaCurrent}/${hero.animaMax}',
                            style: TextStyle(
                              fontSize: 12,
                              color: p.infoBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SvgIconWidget(ArcanaSvgIcons.chevronRight, size: 18, color: p.goldPrimary),
              ],
            ),
          ),
        const SizedBox(height: 18),

        // Central de Noticias Oficiais
        HeraldicSectionDivider(
          svgIcon: ArcanaSvgIcons.sparkles,
          title: 'Noticias & Anuncios da Taverna',
          trailing: RbacGuard.canPublishOfficialAnnouncement(user.role)
              ? IconButton(
                  tooltip: 'Publicar Anuncio Oficial',
                  onPressed: () => showArcanaModal(context,
                    builder: (_) => CreateAnnouncementModal(controller: controller),
                  ),
                  icon: SvgIconWidget(ArcanaSvgIcons.plus, size: 18, color: p.goldPrimary),
                )
              : null,
        ),
        for (final item in controller.news.take(3)) ...[
          HeraldicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeraldicChipPill(label: item.tag, color: p.goldPrimary),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.summary,
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: SecondaryHeraldicButton(
                label: 'Ver Tutoriais Sandbox',
                svgIcon: ArcanaSvgIcons.book,
                expand: true,
                onPressed: () => showArcanaModal(context,
                  builder: (_) => TutorialsCentralModal(controller: controller),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
