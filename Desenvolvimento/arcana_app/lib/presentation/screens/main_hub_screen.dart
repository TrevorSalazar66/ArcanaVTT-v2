import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/svg_icons.dart';
import '../../core/security/rbac_guard.dart';
import '../../core/theme/arcana_colors.dart';
import '../modals/modal_shell.dart';
import '../modals/profile_and_nav_modals.dart';
import '../modals/universal_report_modal.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/svg_icon_widget.dart';
import 'tabs/campaigns_tab_screen.dart';
import 'tabs/communities_tab_screen.dart';
import 'tabs/home_tab_screen.dart';
import 'tabs/systems_tab_screen.dart';

/// Hub Central Adaptativo do ArcanaVTT:
/// - Top AppBar fixa (Drawer, Logo, Notificações, Denúncia Rápida, Avatar)
/// - Menu Gaveta com Widget Tree Pruning (RBAC Zero-Trust)
/// - BottomNavigationBar (<600dp) / NavigationRail (>=600dp)
class MainHubScreen extends StatelessWidget {
  final AppController controller;

  const MainHubScreen({super.key, required this.controller});

  static const _tabsMeta = [
    (label: 'Início', icon: ArcanaSvgIcons.crown),
    (label: 'Campanhas', icon: ArcanaSvgIcons.scroll),
    (label: 'Sistemas', icon: ArcanaSvgIcons.dices),
    (label: 'Comunidades', icon: ArcanaSvgIcons.messagesSquare),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final unread = controller.unreadNotificationsCount;
    final isWide = MediaQuery.of(context).size.width >= 600;

    final bodyTab = switch (controller.currentTabIndex) {
      0 => HomeTabScreen(controller: controller),
      1 => CampaignsTabScreen(controller: controller),
      2 => SystemsTabScreen(controller: controller),
      _ => CommunitiesTabScreen(controller: controller),
    };

    return Scaffold(
      backgroundColor: p.voidBg,
      drawer: _buildNavigationDrawer(context, p),
      appBar: AppBar(
        backgroundColor: p.obsidianBg,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: p.goldBorder.withValues(alpha: 0.35)),
        ),
        leading: Builder(
          builder: (scaffoldCtx) => IconButton(
            tooltip: 'Menu Principal',
            onPressed: () => Scaffold.of(scaffoldCtx).openDrawer(),
            icon: SvgIconWidget(ArcanaSvgIcons.menu, size: 22, color: p.goldPrimary),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            SvgIconWidget(ArcanaSvgIcons.dices, size: 22, color: p.goldPrimary),
            const SizedBox(width: 8),
            Text(
              'ARCANA VTT',
              style: TextStyle(
                color: p.goldPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Denúncia Universal',
            onPressed: () => showArcanaModal(
              context,
              builder: (_) => UniversalReportModal(
                controller: controller,
                originType: 'campanha',
                originId: 'hub_tab_${controller.currentTabIndex}',
              ),
            ),
            icon: SvgIconWidget(ArcanaSvgIcons.flag, size: 19, color: p.textSecondary),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Notificações',
                onPressed: () => showArcanaModal(
                  context,
                  builder: (_) => NotificationsModal(controller: controller),
                ),
                icon: SvgIconWidget(ArcanaSvgIcons.bell, size: 21, color: p.textPrimary),
              ),
              if (unread > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: p.crimson,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: () => showArcanaModal(
                context,
                builder: (_) => SocialProfileModal(controller: controller),
              ),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.surfaceElevated,
                  border: Border.all(color: p.goldBorder),
                ),
                alignment: Alignment.center,
                child: SvgIconWidget(
                  ArcanaSvgIcons.user,
                  size: 18,
                  color: p.goldPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  backgroundColor: p.obsidianBg,
                  selectedIndex: controller.currentTabIndex,
                  onDestinationSelected: controller.setTabIndex,
                  labelType: NavigationRailLabelType.all,
                  destinations: _tabsMeta.map((tab) {
                    return NavigationRailDestination(
                      icon: SvgIconWidget(tab.icon, size: 20, color: p.textSecondary),
                      selectedIcon:
                          SvgIconWidget(tab.icon, size: 22, color: p.goldPrimary),
                      label: Text(tab.label),
                    );
                  }).toList(),
                ),
                VerticalDivider(width: 1, color: p.subtleBorder),
                Expanded(child: bodyTab),
              ],
            )
          : bodyTab,
      bottomNavigationBar: isWide
          ? null
          : Container(
              decoration: BoxDecoration(
                color: p.obsidianBg,
                border: Border(
                  top: BorderSide(color: p.goldBorder.withValues(alpha: 0.4)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: List.generate(_tabsMeta.length, (idx) {
                    final tab = _tabsMeta[idx];
                    final active = idx == controller.currentTabIndex;
                    return Expanded(
                      child: InkWell(
                        onTap: () => controller.setTabIndex(idx),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgIconWidget(
                                tab.icon,
                                size: 20,
                                color: active ? p.goldPrimary : p.textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tab.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      active ? FontWeight.w800 : FontWeight.w500,
                                  color: active ? p.goldPrimary : p.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context, ArcanaPalette p) {
    final user = controller.currentUser;
    final showAdminPanel = RbacGuard.canAccessAdminPanel(user.role);

    return Drawer(
      backgroundColor: p.obsidianBg,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: p.voidBg,
                border: Border(bottom: BorderSide(color: p.goldBorder.withValues(alpha: 0.4))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.surfaceElevated,
                      border: Border.all(color: p.goldBorder),
                    ),
                    alignment: Alignment.center,
                    child: SvgIconWidget(ArcanaSvgIcons.crown, size: 24, color: p.goldPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text('@${user.username}',
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 6),
                        RoleBadgeWidget(role: user.role),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerItem(
                    context,
                    svg: ArcanaSvgIcons.user,
                    title: 'Meu Perfil Social',
                    onTap: () => showArcanaModal(
                      context,
                      builder: (_) => SocialProfileModal(controller: controller),
                    ),
                  ),
                  _drawerItem(
                    context,
                    svg: ArcanaSvgIcons.users,
                    title: 'Lista de Amigos & DMs',
                    onTap: () => showArcanaModal(
                      context,
                      builder: (_) => FriendsManagementModal(controller: controller),
                    ),
                  ),
                  _drawerItem(
                    context,
                    svg: ArcanaSvgIcons.book,
                    title: 'Central de Tutoriais (Sandbox)',
                    onTap: () => showArcanaModal(
                      context,
                      builder: (_) => TutorialsCentralModal(controller: controller),
                    ),
                  ),
                  _drawerItem(
                    context,
                    svg: ArcanaSvgIcons.settings,
                    title: 'Configurações Gerais',
                    onTap: () => showArcanaModal(
                      context,
                      builder: (_) => GeneralSettingsModal(controller: controller),
                    ),
                  ),
                  _drawerItem(
                    context,
                    svg: ArcanaSvgIcons.flag,
                    title: 'Denúncia Universal',
                    color: p.crimson,
                    onTap: () => showArcanaModal(
                      context,
                      builder: (_) => UniversalReportModal(
                        controller: controller,
                        originType: 'usuario',
                        originId: user.id,
                      ),
                    ),
                  ),
                  // Widget Tree Pruning Zero-Trust: só entra na árvore se Admin ou Superadmin
                  if (showAdminPanel)
                    _drawerItem(
                      context,
                      svg: ArcanaSvgIcons.terminal,
                      title: 'Painel de Governança Admin',
                      color: p.crimson,
                      onTap: () => showArcanaModal(
                        context,
                        builder: (_) => AdminGovernanceModal(controller: controller),
                      ),
                    ),
                ],
              ),
            ),
            Divider(color: p.subtleBorder, height: 1),
            _drawerItem(
              context,
              svg: ArcanaSvgIcons.logOut,
              title: 'Logout Seguro',
              color: p.crimson,
              onTap: () => showArcanaModal(
                context,
                builder: (_) => SafeLogoutModal(controller: controller),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required String svg,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final p = context.arcana;
    final tint = color ?? p.goldPrimary;
    return ListTile(
      leading: SvgIconWidget(svg, size: 20, color: tint),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color ?? p.textPrimary,
            ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }
}

