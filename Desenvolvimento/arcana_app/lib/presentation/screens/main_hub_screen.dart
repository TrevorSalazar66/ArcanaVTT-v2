import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/svg_icons.dart';
import '../../core/security/rbac_guard.dart';
import '../../core/theme/arcana_colors.dart';
import '../modals/community_chat_modal.dart';
import '../modals/hero_sheet_highlight_modal.dart';
import '../modals/modal_shell.dart';
import '../modals/profile_and_nav_modals.dart';
import '../modals/universal_report_modal.dart';
import '../widgets/svg_icon_widget.dart';
import 'tabs/campaigns_tab_screen.dart';
import 'tabs/communities_tab_screen.dart';
import 'tabs/home_tab_screen.dart';
import 'tabs/systems_tab_screen.dart';

class MainHubScreen extends StatelessWidget {
  final AppController controller;

  const MainHubScreen({super.key, required this.controller});

  static const _tabs = [
    (label: 'Inicio', svg: ArcanaSvgIcons.shield),
    (label: 'Campanhas', svg: ArcanaSvgIcons.swords),
    (label: 'Sistemas', svg: ArcanaSvgIcons.scroll),
    (label: 'Comunidades', svg: ArcanaSvgIcons.users),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final unread = controller.unreadNotificationsCount;
    final width = MediaQuery.of(context).size.width;
    final isDesktopSidebar = width >= 900;
    final isTabletRail = width >= 600 && width < 900;

    final bodyContent = IndexedStack(
      index: controller.currentTabIndex,
      children: [
        HomeTabScreen(controller: controller),
        CampaignsTabScreen(controller: controller),
        SystemsTabScreen(controller: controller),
        CommunitiesTabScreen(controller: controller),
      ],
    );

    return Scaffold(
      backgroundColor: p.voidBg,
      drawer: isDesktopSidebar ? null : _buildNavigationDrawer(context, p),
      appBar: AppBar(
        backgroundColor: p.obsidianBg,
        elevation: 0,
        leading: isDesktopSidebar
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: SvgIconWidget(ArcanaSvgIcons.dices, size: 22, color: p.goldPrimary),
              )
            : Builder(
                builder: (scaffoldCtx) => IconButton(
                  tooltip: 'Menu Principal',
                  onPressed: () => Scaffold.of(scaffoldCtx).openDrawer(),
                  icon: SvgIconWidget(ArcanaSvgIcons.menu, size: 22, color: p.goldPrimary),
                ),
              ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: p.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.goldBorder),
              ),
              child: SvgIconWidget(ArcanaSvgIcons.dices, size: 18, color: p.goldPrimary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ARCANA VTT',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: p.goldHighlight,
                    ),
                  ),
                  Text(
                    'Motor Universal Edge',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: p.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notificacoes & Convites',
            onPressed: () => showArcanaModal(context,
              builder: (_) => NotificationsModal(controller: controller),
            ),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              backgroundColor: p.crimson,
              child: SvgIconWidget(ArcanaSvgIcons.bell, size: 21, color: p.goldPrimary),
            ),
          ),
          IconButton(
            tooltip: 'Denuncia Universal',
            onPressed: () => showArcanaModal(context,
              builder: (_) => UniversalReportModal(
                controller: controller,
                originType: 'usuario',
                originId: controller.currentUser.id.isEmpty
                    ? 'hub_principal'
                    : controller.currentUser.id,
              ),
            ),
            icon: SvgIconWidget(ArcanaSvgIcons.flag, size: 20, color: p.crimson),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10, left: 4),
            child: InkWell(
              onTap: () => showArcanaModal(context,
                builder: (_) => SocialProfileModal(controller: controller),
              ),
              borderRadius: BorderRadius.circular(20),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: p.surfaceElevated,
                child: SvgIconWidget(
                  _avatarSvgForKey(controller.currentUser.avatarIcon),
                  size: 18,
                  color: p.goldHighlight,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (controller.ghostSpectatorActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: p.crimson.withValues(alpha: 0.16),
                border: Border(
                  bottom: BorderSide(color: p.crimson.withValues(alpha: 0.6)),
                ),
              ),
              child: Row(
                children: [
                  SvgIconWidget(ArcanaSvgIcons.eye, size: 16, color: p.crimson),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'MODO ESPECTADOR FANTASMA ATIVO — Auditoria silenciosa em mesas e cenas.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.toggleGhostSpectator,
                    child: Text(
                      'Desativar',
                      style: TextStyle(color: p.crimson, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: isDesktopSidebar
                ? Row(
                    children: [
                      _buildFixedDesktopSidebar(context, p),
                      VerticalDivider(width: 1, thickness: 1, color: p.goldBorder),
                      Expanded(child: bodyContent),
                    ],
                  )
                : isTabletRail
                    ? Row(
                        children: [
                          NavigationRail(
                            backgroundColor: p.obsidianBg,
                            selectedIndex: controller.currentTabIndex,
                            onDestinationSelected: controller.setTabIndex,
                            labelType: NavigationRailLabelType.all,
                            destinations: _tabs
                                .map((t) => NavigationRailDestination(
                                      icon: SvgIconWidget(t.svg,
                                          size: 20, color: p.textSecondary),
                                      selectedIcon: SvgIconWidget(t.svg,
                                          size: 22, color: p.goldHighlight),
                                      label: Text(t.label),
                                    ))
                                .toList(),
                          ),
                          VerticalDivider(width: 1, thickness: 1, color: p.goldBorder),
                          Expanded(child: bodyContent),
                        ],
                      )
                    : bodyContent,
          ),
        ],
      ),
      bottomNavigationBar: (isDesktopSidebar || isTabletRail)
          ? null
          : Container(
              decoration: BoxDecoration(
                color: p.obsidianBg,
                border: Border(top: BorderSide(color: p.goldBorder)),
              ),
              child: NavigationBar(
                height: 66,
                backgroundColor: p.obsidianBg,
                indicatorColor: p.goldPrimary.withValues(alpha: 0.16),
                selectedIndex: controller.currentTabIndex,
                onDestinationSelected: controller.setTabIndex,
                destinations: _tabs
                    .map((t) => NavigationDestination(
                          icon: SvgIconWidget(t.svg, size: 20, color: p.textSecondary),
                          selectedIcon:
                              SvgIconWidget(t.svg, size: 22, color: p.goldHighlight),
                          label: t.label,
                        ))
                    .toList(),
              ),
            ),
    );
  }

  String _avatarSvgForKey(String key) {
    switch (key) {
      case 'crown':
        return ArcanaSvgIcons.crown;
      case 'swords':
        return ArcanaSvgIcons.swords;
      case 'skull':
        return ArcanaSvgIcons.skull;
      case 'flame':
        return ArcanaSvgIcons.flame;
      case 'scroll':
        return ArcanaSvgIcons.scroll;
      case 'user':
        return ArcanaSvgIcons.user;
      default:
        return ArcanaSvgIcons.shield;
    }
  }

  Widget _buildFixedDesktopSidebar(BuildContext context, ArcanaPalette p) {
    final user = controller.currentUser;
    final showAdminPanel = RbacGuard.canAccessAdminPanel(user.role);

    return Container(
      width: 260,
      color: p.obsidianBg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: InkWell(
              onTap: () => showArcanaModal(context,
                builder: (_) => SocialProfileModal(controller: controller),
              ),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.goldBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: p.obsidianBg,
                      child: SvgIconWidget(
                        _avatarSvgForKey(user.avatarIcon),
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
                            user.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary,
                            ),
                          ),
                          Text(
                            '@${user.username} · ${user.role.badgeLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: p.goldPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Divider(color: p.subtleBorder, height: 1),
          const SizedBox(height: 8),
          for (var i = 0; i < _tabs.length; i++)
            _sidebarNavItem(
              p: p,
              svg: _tabs[i].svg,
              label: _tabs[i].label,
              selected: controller.currentTabIndex == i,
              onTap: () => controller.setTabIndex(i),
            ),
          Divider(color: p.subtleBorder, height: 18),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _drawerItem(
                  context,
                  p,
                  svg: ArcanaSvgIcons.users,
                  title: 'Amigos & DMs 1-a-1',
                  closeDrawerFirst: false,
                  onTap: () => showArcanaModal(context,
                    builder: (_) => FriendsManagementModal(controller: controller),
                  ),
                ),
                _drawerItem(
                  context,
                  p,
                  svg: ArcanaSvgIcons.sword,
                  title: 'Meus Herois',
                  closeDrawerFirst: false,
                  onTap: () => showArcanaModal(context,
                    builder: (_) => HeroSheetHighlightModal(controller: controller),
                  ),
                ),
                _drawerItem(
                  context,
                  p,
                  svg: ArcanaSvgIcons.messagesSquare,
                  title: 'Taverna dos Mestres',
                  closeDrawerFirst: false,
                  onTap: () => showArcanaModal(context,
                    builder: (_) => CommunityChatModal(controller: controller),
                  ),
                ),
                _drawerItem(
                  context,
                  p,
                  svg: ArcanaSvgIcons.settings,
                  title: 'Configuracoes Gerais',
                  closeDrawerFirst: false,
                  onTap: () => showArcanaModal(context,
                    builder: (_) => GeneralSettingsModal(controller: controller),
                  ),
                ),
                if (showAdminPanel)
                  _drawerItem(
                    context,
                    p,
                    svg: ArcanaSvgIcons.shield,
                    title: 'Governanca Admin',
                    accentColor: p.crimson,
                    closeDrawerFirst: false,
                    onTap: () => showArcanaModal(context,
                      builder: (_) => AdminGovernanceModal(controller: controller),
                    ),
                  ),
              ],
            ),
          ),
          Divider(color: p.subtleBorder, height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                _drawerItem(
                  context,
                  p,
                  svg: ArcanaSvgIcons.book,
                  title: 'Guia de Tutoriais',
                  closeDrawerFirst: false,
                  onTap: () => showArcanaModal(context,
                    builder: (_) => TutorialsCentralModal(controller: controller),
                  ),
                ),
                _drawerItem(
                  context,
                  p,
                  svg: ArcanaSvgIcons.logOut,
                  title: 'Logout Seguro',
                  accentColor: p.crimson,
                  closeDrawerFirst: false,
                  onTap: () => showArcanaModal(context,
                    builder: (_) => SafeLogoutModal(controller: controller),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarNavItem({
    required ArcanaPalette p,
    required String svg,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? p.goldPrimary.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? p.goldBorder : Colors.transparent,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: SvgIconWidget(
          svg,
          size: 19,
          color: selected ? p.goldHighlight : p.textSecondary,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? p.goldHighlight : p.textPrimary,
          ),
        ),
        onTap: onTap,
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
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: p.surfaceElevated,
                border: Border(bottom: BorderSide(color: p.goldBorder)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: p.obsidianBg,
                    child: SvgIconWidget(
                      _avatarSvgForKey(user.avatarIcon),
                      size: 26,
                      color: p.goldHighlight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: p.goldHighlight,
                          ),
                        ),
                        Text(
                          '@${user.username} · ${user.role.badgeLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: p.textSecondary),
                        ),
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
                    p,
                    svg: ArcanaSvgIcons.user,
                    title: 'Perfil Social (Discord)',
                    onTap: () => showArcanaModal(context,
                      builder: (_) => SocialProfileModal(controller: controller),
                    ),
                  ),
                  _drawerItem(
                    context,
                    p,
                    svg: ArcanaSvgIcons.users,
                    title: 'Amigos & DMs 1-a-1',
                    onTap: () => showArcanaModal(context,
                      builder: (_) => FriendsManagementModal(controller: controller),
                    ),
                  ),
                  _drawerItem(
                    context,
                    p,
                    svg: ArcanaSvgIcons.sword,
                    title: 'Meus Herois & Fichas',
                    onTap: () => showArcanaModal(context,
                      builder: (_) => HeroSheetHighlightModal(controller: controller),
                    ),
                  ),
                  _drawerItem(
                    context,
                    p,
                    svg: ArcanaSvgIcons.book,
                    title: 'Central de Tutoriais',
                    onTap: () => showArcanaModal(context,
                      builder: (_) => TutorialsCentralModal(controller: controller),
                    ),
                  ),
                  _drawerItem(
                    context,
                    p,
                    svg: ArcanaSvgIcons.settings,
                    title: 'Configuracoes Gerais',
                    onTap: () => showArcanaModal(context,
                      builder: (_) => GeneralSettingsModal(controller: controller),
                    ),
                  ),
                  _drawerItem(
                    context,
                    p,
                    svg: ArcanaSvgIcons.messagesSquare,
                    title: 'Taverna dos Mestres',
                    onTap: () => showArcanaModal(context,
                      builder: (_) => CommunityChatModal(controller: controller),
                    ),
                  ),
                  if (showAdminPanel) ...[
                    Divider(color: p.subtleBorder, height: 18),
                    _drawerItem(
                      context,
                      p,
                      svg: ArcanaSvgIcons.shield,
                      title: 'Painel de Governanca Admin',
                      accentColor: p.crimson,
                      onTap: () => showArcanaModal(context,
                        builder: (_) => AdminGovernanceModal(controller: controller),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Divider(color: p.subtleBorder, height: 1),
            _drawerItem(
              context,
              p,
              svg: ArcanaSvgIcons.logOut,
              title: 'Logout Seguro',
              accentColor: p.crimson,
              onTap: () => showArcanaModal(context,
                builder: (_) => SafeLogoutModal(controller: controller),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    ArcanaPalette p, {
    required String svg,
    required String title,
    Color? accentColor,
    bool closeDrawerFirst = true,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: SvgIconWidget(svg, size: 20, color: accentColor ?? p.goldPrimary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: accentColor ?? p.textPrimary,
        ),
      ),
      onTap: () {
        if (closeDrawerFirst) Navigator.of(context).pop();
        onTap();
      },
    );
  }
}
