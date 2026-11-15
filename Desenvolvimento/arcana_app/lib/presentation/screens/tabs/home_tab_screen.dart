import 'package:flutter/material.dart';
import '../../../controllers/app_controller.dart';
import '../../../core/constants/svg_icons.dart';
import '../../../core/security/rbac_guard.dart';
import '../../../core/theme/arcana_colors.dart';
import '../../modals/campaign_modals.dart';
import '../../modals/hero_sheet_highlight_modal.dart';
import '../../modals/modal_shell.dart';
import '../../modals/profile_and_nav_modals.dart';
import '../../modals/quick_join_modal.dart';
import '../../widgets/heraldic_buttons.dart';
import '../../widgets/heraldic_card.dart';
import '../../widgets/heraldic_section_divider.dart';
import '../../widgets/svg_icon_widget.dart';

/// Aba 1 — Início / Hub Central Padrão.
class HomeTabScreen extends StatelessWidget {
  final AppController controller;

  const HomeTabScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final user = controller.currentUser;
    final hero = controller.hero;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        // Banner de Boas-Vindas & Card de Perfil Rápido
        Text(
          'Saudações, ${user.displayName}.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        HeraldicCard(
          goldAccent: true,
          onTap: () => showArcanaModal(
            context,
            builder: (_) => SocialProfileModal(controller: controller),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.surfaceElevated,
                  border: Border.all(color: p.goldBorder, width: 1.4),
                ),
                alignment: Alignment.center,
                child: SvgIconWidget(ArcanaSvgIcons.crown, size: 22, color: p.goldPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        RoleBadgeWidget(role: user.role),
                      ],
                    ),
                    Text(
                      '@${user.username} • ${user.reputationPoints} Reputação',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              SvgIconWidget(ArcanaSvgIcons.chevronRight, size: 18, color: p.goldPrimary),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick Join Card
        const HeraldicSectionDivider(
          svgIcon: ArcanaSvgIcons.qrCode,
          title: 'ENTRADA RÁPIDA (QUICK JOIN)',
        ),
        HeraldicCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Entre instantaneamente em qualquer mesa informando o código de 6 dígitos ou lendo o QR Code do Mestre.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PrimaryGoldPillButton(
                      label: 'Inserir Código da Mesa',
                      svgIcon: ArcanaSvgIcons.key,
                      onPressed: () => showArcanaModal(
                        context,
                        builder: (_) => QuickJoinModal(controller: controller),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SecondaryHeraldicButton(
                    label: 'QR',
                    svgIcon: ArcanaSvgIcons.qrCode,
                    borderColor: p.goldBorder,
                    onPressed: () => showArcanaModal(
                      context,
                      builder: (_) => QuickJoinModal(controller: controller),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Carrossel Continuar a Jornada
        HeraldicSectionDivider(
          svgIcon: ArcanaSvgIcons.scroll,
          title: 'CONTINUAR A JORNADA',
          trailing: TextButton(
            onPressed: () => controller.setTabIndex(1),
            child: const Text('Ver todas'),
          ),
        ),
        if (controller.campaigns.isEmpty)
          HeraldicCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.surfaceElevated,
                      border: Border.all(color: p.goldBorder),
                    ),
                    alignment: Alignment.center,
                    child: SvgIconWidget(
                      ArcanaSvgIcons.dices,
                      size: 22,
                      color: p.goldPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nenhuma campanha por enquanto',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Sua jornada começa ao entrar ou criar uma mesa.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (RbacGuard.canForgeCampaign(user.role)) ...[
                      Expanded(
                        child: PrimaryGoldPillButton(
                          label: 'Forjar campanha',
                          svgIcon: ArcanaSvgIcons.wand2,
                          onPressed: () => showArcanaModal(
                            context,
                            builder: (_) =>
                                CreateCampaignWizardModal(controller: controller),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: SecondaryHeraldicButton(
                        label: 'Entrar com Código',
                        svgIcon: ArcanaSvgIcons.key,
                        borderColor: p.goldBorder,
                        onPressed: () => showArcanaModal(
                          context,
                          builder: (_) => QuickJoinModal(controller: controller),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 174,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.campaigns.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (ctx, idx) {
                final cmp = controller.campaigns[idx];
                return SizedBox(
                  width: 268,
                  child: HeraldicCard(
                    goldAccent: idx == 0,
                    onTap: () => showArcanaModal(
                      context,
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
                              color: cmp.modeBadge == 'AO VIVO'
                                  ? p.emerald
                                  : p.goldPrimary,
                            ),
                            Text(
                              cmp.quickJoinCode,
                              style: TextStyle(
                                fontSize: 11,
                                color: p.infoBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          cmp.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cmp.chapterTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                cmp.systemName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: p.textSecondary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${cmp.occupiedSlots}/${cmp.maxSlots} Heróis',
                              style: TextStyle(
                                fontSize: 11,
                                color: p.goldPrimary,
                                fontWeight: FontWeight.w700,
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
        const SizedBox(height: 16),

        // Herói em Destaque
        const HeraldicSectionDivider(
          svgIcon: ArcanaSvgIcons.swords,
          title: 'HERÓI EM DESTAQUE',
        ),
        if (hero == null)
          HeraldicCard(
            goldAccent: true,
            onTap: () => showArcanaModal(
              context,
              builder: (_) => HeroSheetHighlightModal(controller: controller),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        ArcanaSvgIcons.sword,
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
                            'Suas fichas aparecerão aqui',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Crie seu primeiro aventureiro AlphaD6 (3d6 e 12 slots) sincronizado na nuvem.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PrimaryGoldPillButton(
                  label: 'Criar Ficha de Herói',
                  svgIcon: ArcanaSvgIcons.swords,
                  onPressed: () => showArcanaModal(
                    context,
                    builder: (_) =>
                        HeroSheetHighlightModal(controller: controller),
                  ),
                ),
              ],
            ),
          )
        else
          HeraldicCard(
            goldAccent: true,
            onTap: () => showArcanaModal(
              context,
              builder: (_) => HeroSheetHighlightModal(controller: controller),
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
                      child: SvgIconWidget(ArcanaSvgIcons.sword, size: 22, color: p.goldPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${hero.name} — Nv. ${hero.level}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${hero.heroClass} • ${hero.campaignTitle}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    HeraldicChipPill(label: 'FICHA 3D6', color: p.goldPrimary),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Vitalidade: ${hero.hpCurrent}/${hero.hpMax}',
                        style: TextStyle(fontSize: 12, color: p.emerald, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Ânima: ${hero.animaCurrent}/${hero.animaMax}',
                        style: TextStyle(fontSize: 12, color: p.infoBlue, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      'Slots: ${hero.slots.length}/12',
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Mural de Novidades
        const HeraldicSectionDivider(
          svgIcon: ArcanaSvgIcons.sparkles,
          title: 'MURAL DE NOVIDADES',
        ),
        ...controller.news.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HeraldicCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeraldicChipPill(label: item.tag, color: p.infoBlue),
                  const SizedBox(height: 6),
                  Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(item.summary, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Ações Rápidas Inferiores (com Widget Tree Pruning RBAC)
        Row(
          children: [
            if (RbacGuard.canForgeCampaign(user.role)) ...[
              Expanded(
                child: PrimaryGoldPillButton(
                  label: 'Forjar Campanha',
                  svgIcon: ArcanaSvgIcons.wand2,
                  onPressed: () => showArcanaModal(
                    context,
                    builder: (_) => CreateCampaignWizardModal(controller: controller),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: SecondaryHeraldicButton(
                label: 'Guia da Taverna',
                svgIcon: ArcanaSvgIcons.book,
                borderColor: p.goldBorder,
                onPressed: () => showArcanaModal(
                  context,
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
