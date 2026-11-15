import 'package:flutter/material.dart';
import '../../core/security/rbac_guard.dart';
import '../../core/theme/arcana_colors.dart';
import '../../domain/entities/arcana_entities.dart';
import '../../domain/usecases/authenticate_oauth_usecase.dart';
import '../../domain/usecases/build_universal_report_usecase.dart';
import '../../domain/usecases/filter_compendium_categories_usecase.dart';
import '../../domain/usecases/roll_3d6_usecase.dart';
import '../data/datasources/cloudflare_edge_client.dart';
import '../data/datasources/local_storage_datasource.dart';
import '../data/repositories/arcana_seed_repository.dart';

/// Controller central reativo do ArcanaVTT (Camada Controllers da Clean Architecture).
class AppController extends ChangeNotifier {
  final CloudflareEdgeClient edgeClient;
  final LocalStorageDatasource localStorage;
  final Roll3d6UseCase _roll3d6;
  final FilterCompendiumCategoriesUseCase _filterCompendium;
  final BuildUniversalReportUseCase _buildReport;
  final AuthenticateOAuthUseCase _oauthUseCase;

  AppController({
    CloudflareEdgeClient? edgeClient,
    LocalStorageDatasource? localStorage,
    Roll3d6UseCase? roll3d6,
    FilterCompendiumCategoriesUseCase? filterCompendium,
    BuildUniversalReportUseCase? buildReport,
    AuthenticateOAuthUseCase? oauthUseCase,
  })  : edgeClient = edgeClient ?? CloudflareEdgeClient(),
        localStorage = localStorage ?? LocalStorageDatasource(),
        _roll3d6 = roll3d6 ?? Roll3d6UseCase(),
        _filterCompendium = filterCompendium ?? FilterCompendiumCategoriesUseCase(),
        _buildReport = buildReport ?? BuildUniversalReportUseCase(),
        _oauthUseCase = oauthUseCase ?? AuthenticateOAuthUseCase();

  // Estado Visual & Acessibilidade
  ArcanaThemeMode themeMode = ArcanaThemeMode.escuroHeraldico;
  double fontScale = 1.0;
  AudioMixerSettings audioMixer = const AudioMixerSettings(
    masterVolume: 0.85,
    ambienceVolume: 0.65,
    sfxVolume: 0.90,
    voiceVolume: 0.80,
  );
  int p2pCacheMb = 14;

  // Estado de Autenticação OAuth 2.0
  bool isAuthenticated = false;
  bool trustDevice = true;
  OAuthSecurityState loginViewState = OAuthSecurityState.padrao;
  String? authErrorTitle;
  String? authErrorMessage;
  String selectedGoogleAccountEmail = 'valen.voss@gmail.com';
  String selectedGoogleAccountName = 'Valen Voss';

  UserAccount currentUser = const UserAccount(
    id: 'usr_valen_bard',
    email: 'valen.voss@gmail.com',
    username: 'valen_bard',
    displayName: 'Valen Voss',
    bio: 'Explorador das Terras Cinzentas e duelista do sistema AlphaD6.',
    avatarIcon: 'crown',
    role: UserRole.mestre,
    reputationPoints: 340,
    onboardingCompleted: false,
    trustedDeviceEnabled: true,
    trustedDaysRemaining: 30,
  );

  // Estado do Hub Central e Abas
  int currentTabIndex = 0;

  // Dados Vivos
  List<Campaign> campaigns = ArcanaSeedData.initialCampaigns();
  HeroCharacter hero = ArcanaSeedData.initialHero();
  List<RpgSystem> systems = ArcanaSeedData.initialSystems();
  List<CompendiumItem> compendiumItems = ArcanaSeedData.initialCompendium();
  List<Guild> guilds = ArcanaSeedData.initialGuilds();
  List<ForumTopic> forumTopics = ArcanaSeedData.initialForumTopics();
  List<ChatMessage> chatMessages = ArcanaSeedData.initialChatMessages();
  List<FriendContact> friends = ArcanaSeedData.initialFriends();
  List<AppNotification> notifications = ArcanaSeedData.initialNotifications();
  List<TutorialModule> tutorials = ArcanaSeedData.initialTutorials();
  List<NewsItem> news = ArcanaSeedData.initialNews();
  List<UniversalReport> reports = ArcanaSeedData.initialReports();
  List<String> hardwareBannedFingerprints = [];
  DiceRoll3d6? lastHeroRoll;

  int get unreadNotificationsCount =>
      notifications.where((n) => !n.isRead).length;

  Future<void> initializeFromStorage() async {
    themeMode = await localStorage.loadTheme();
    fontScale = await localStorage.loadFontScale();
    final session = await localStorage.loadSessionState();
    isAuthenticated = (session['active'] as bool?) ?? false;
    trustDevice = (session['trusted'] as bool?) ?? true;
    edgeClient.baseUrl = (session['edgeUrl'] as String?) ?? edgeClient.baseUrl;
    currentUser = currentUser.copyWith(
      username: (session['username'] as String?) ?? currentUser.username,
      displayName: (session['displayName'] as String?) ?? currentUser.displayName,
      trustedDeviceEnabled: trustDevice,
    );
    notifyListeners();
  }

  // ---- Autenticação 100% Google OAuth 2.0 ----

  void switchSimulatedGoogleAccount() {
    if (selectedGoogleAccountEmail == 'valen.voss@gmail.com') {
      selectedGoogleAccountEmail = 'thorin.admin@gmail.com';
      selectedGoogleAccountName = 'Thorin Guardião';
    } else {
      selectedGoogleAccountEmail = 'valen.voss@gmail.com';
      selectedGoogleAccountName = 'Valen Voss';
    }
    notifyListeners();
  }

  void setTrustDevice(bool value) {
    trustDevice = value;
    currentUser = currentUser.copyWith(trustedDeviceEnabled: value);
    notifyListeners();
  }

  void previewLoginState(OAuthSecurityState state) {
    loginViewState = state;
    switch (state) {
      case OAuthSecurityState.padrao:
        authErrorTitle = null;
        authErrorMessage = null;
      case OAuthSecurityState.erroMenorIdade:
        final res = _oauthUseCase.evaluateAttempt(
          birthDate: DateTime(2013, 4, 12),
          isHardwareBanned: false,
          isAccountLocked: false,
        );
        authErrorTitle = res.errorTitle;
        authErrorMessage = res.errorMessage;
      case OAuthSecurityState.erroHardwareBan:
        final res = _oauthUseCase.evaluateAttempt(
          birthDate: DateTime(1995, 1, 1),
          isHardwareBanned: true,
          isAccountLocked: false,
        );
        authErrorTitle = res.errorTitle;
        authErrorMessage = res.errorMessage;
      case OAuthSecurityState.erroLockoutTotal:
        final res = _oauthUseCase.evaluateAttempt(
          birthDate: DateTime(1995, 1, 1),
          isHardwareBanned: false,
          isAccountLocked: true,
        );
        authErrorTitle = res.errorTitle;
        authErrorMessage = res.errorMessage;
      case OAuthSecurityState.sucessoAutenticado:
        authErrorTitle = null;
        authErrorMessage = null;
    }
    notifyListeners();
  }

  Future<bool> signInWithGoogleOAuth({
    DateTime? birthDate,
    bool simulateHardwareBan = false,
    bool simulateLockout = false,
  }) async {
    final effectiveBirth = birthDate ?? DateTime(1998, 5, 14);
    final check = _oauthUseCase.evaluateAttempt(
      birthDate: effectiveBirth,
      isHardwareBanned: simulateHardwareBan,
      isAccountLocked: simulateLockout,
    );

    if (!check.success) {
      authErrorTitle = check.errorTitle;
      authErrorMessage = check.errorMessage;
      if (check.errorCode == 'AGE_RESTRICTED') {
        loginViewState = OAuthSecurityState.erroMenorIdade;
      } else if (check.errorCode == 'HARDWARE_BANNED') {
        loginViewState = OAuthSecurityState.erroHardwareBan;
      } else {
        loginViewState = OAuthSecurityState.erroLockoutTotal;
      }
      notifyListeners();
      return false;
    }

    // Dispara tentativa opcional de sincronização real no Cloudflare Worker
    await edgeClient.postAuth({
      'action': 'oauth_google',
      'google_sub': 'sub_${selectedGoogleAccountEmail.hashCode}',
      'email': selectedGoogleAccountEmail,
      'display_name': selectedGoogleAccountName,
      'birth_date':
          '${effectiveBirth.year.toString().padLeft(4, '0')}-${effectiveBirth.month.toString().padLeft(2, '0')}-${effectiveBirth.day.toString().padLeft(2, '0')}',
      'device_fingerprint': 'android-keystore-arcana-v1',
      'trust_device': trustDevice,
    });

    final defaultRole = selectedGoogleAccountEmail.contains('thorin')
        ? UserRole.superadmin
        : UserRole.mestre;

    currentUser = UserAccount(
      id: selectedGoogleAccountEmail.contains('thorin')
          ? 'usr_admin_thorin'
          : 'usr_valen_bard',
      email: selectedGoogleAccountEmail,
      username: selectedGoogleAccountEmail.contains('thorin')
          ? 'admin_thorin'
          : 'valen_bard',
      displayName: selectedGoogleAccountName,
      bio: currentUser.bio,
      avatarIcon: 'crown',
      role: defaultRole,
      reputationPoints: selectedGoogleAccountEmail.contains('thorin') ? 990 : 340,
      onboardingCompleted: true,
      trustedDeviceEnabled: trustDevice,
      trustedDaysRemaining: trustDevice ? 30 : 1,
    );

    authErrorTitle = null;
    authErrorMessage = null;
    loginViewState = OAuthSecurityState.sucessoAutenticado;
    isAuthenticated = true;
    await localStorage.saveSessionState(
      active: true,
      trustedDevice: trustDevice,
      username: currentUser.username,
      displayName: currentUser.displayName,
    );
    notifyListeners();
    return true;
  }

  void completeLoginTransitionToHub({
    required String newUsername,
    required String newDisplayName,
  }) {
    final sanitized = newUsername
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    if (sanitized.length >= 3 && newDisplayName.trim().length >= 2) {
      currentUser = currentUser.copyWith(
        username: sanitized,
        displayName: newDisplayName.trim(),
        onboardingCompleted: true,
      );
    }
    isAuthenticated = true;
    loginViewState = OAuthSecurityState.padrao;
    notifyListeners();
  }

  Future<void> logout({bool revokeGlobal = false}) async {
    if (revokeGlobal) {
      await edgeClient.postAuth({'action': 'logout', 'scope': 'global'});
    }
    isAuthenticated = false;
    loginViewState = OAuthSecurityState.padrao;
    currentTabIndex = 0;
    await localStorage.clearSession();
    notifyListeners();
  }

  Future<void> triggerTotalLockout() async {
    await edgeClient.postAuth({
      'action': 'lockout_trigger',
      'user_id': currentUser.id,
      'reason': 'Acionado pelo usuario nas Configuracoes Gerais',
    });
    isAuthenticated = false;
    await localStorage.clearSession();
    previewLoginState(OAuthSecurityState.erroLockoutTotal);
  }

  // ---- Navegação & RBAC ----

  void setTabIndex(int index) {
    currentTabIndex = index;
    notifyListeners();
  }

  /// Permite alternar papel em ambiente de homologação/avaliação para verificar RBAC & Widget Tree Pruning.
  void switchActiveRoleForPreview(UserRole role) {
    currentUser = currentUser.copyWith(role: role);
    notifyListeners();
  }

  // ---- Perfil, Temas & Acessibilidade ----

  Future<void> setThemeMode(ArcanaThemeMode mode) async {
    themeMode = mode;
    await localStorage.saveTheme(mode);
    notifyListeners();
  }

  Future<void> setFontScale(double scale) async {
    fontScale = scale.clamp(0.8, 1.5);
    await localStorage.saveFontScale(fontScale);
    notifyListeners();
  }

  void updateProfile({
    required String username,
    required String displayName,
    required String bio,
  }) {
    final cleanUsername =
        username.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    currentUser = currentUser.copyWith(
      username: cleanUsername.length >= 3 ? cleanUsername : currentUser.username,
      displayName: displayName.trim().isNotEmpty
          ? displayName.trim()
          : currentUser.displayName,
      bio: bio.trim(),
      onboardingCompleted: true,
    );
    notifyListeners();
  }

  void updateAudioMixer(AudioMixerSettings settings) {
    audioMixer = settings;
    notifyListeners();
  }

  void clearP2pCache() {
    p2pCacheMb = 0;
    notifyListeners();
  }

  // ---- Campanhas ----

  Campaign? quickJoinByCode(String rawCode) {
    final normalized =
        rawCode.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    for (var i = 0; i < campaigns.length; i++) {
      final c = campaigns[i];
      if (c.quickJoinCode.toUpperCase() == normalized) {
        final updated = Campaign(
          id: c.id,
          title: c.title,
          synopsis: c.synopsis,
          masterHandle: c.masterHandle,
          systemId: c.systemId,
          systemName: c.systemName,
          quickJoinCode: c.quickJoinCode,
          mode: c.mode,
          scheduleText: c.scheduleText,
          maxSlots: c.maxSlots,
          occupiedSlots: c.occupiedSlots < c.maxSlots
              ? c.occupiedSlots + 1
              : c.occupiedSlots,
          userRelation: CampaignSegment.jogando,
          chapterTitle: c.chapterTitle,
          isPublic: c.isPublic,
        );
        campaigns = [...campaigns]..[i] = updated;
        notifyListeners();
        return updated;
      }
    }
    return null;
  }

  bool createCampaign({
    required String title,
    required String synopsis,
    required String systemId,
    required CampaignMode mode,
    required String scheduleText,
    required int maxSlots,
    required bool isPublic,
  }) {
    if (!RbacGuard.canForgeCampaign(currentUser.role)) return false;

    final system = systems.firstWhere(
      (s) => s.id == systemId,
      orElse: () => systems.first,
    );
    final codeNum = (DateTime.now().millisecondsSinceEpoch % 899) + 100;
    final newCampaign = Campaign(
      id: 'cmp_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      synopsis: synopsis.trim(),
      masterHandle: '@${currentUser.username}',
      systemId: system.id,
      systemName: '${system.name} ${system.version}',
      quickJoinCode: 'ARC$codeNum',
      mode: mode,
      scheduleText: scheduleText.trim().isEmpty ? 'Tempo Livre' : scheduleText.trim(),
      maxSlots: maxSlots,
      occupiedSlots: 1,
      userRelation: CampaignSegment.mestre,
      chapterTitle: 'Sessão 0 — Preparação da Mesa',
      isPublic: isPublic,
    );
    campaigns = [newCampaign, ...campaigns];
    notifyListeners();
    return true;
  }

  // ---- Sistemas & Compêndio ----

  FilteredCompendiumResult queryCompendium({
    required String systemId,
    CompendiumCategory? category,
    String searchQuery = '',
  }) {
    final itemsForSystem =
        compendiumItems.where((i) => i.systemId == systemId).toList();
    return _filterCompendium.execute(
      systemItems: itemsForSystem,
      selectedCategory: category,
      searchQuery: searchQuery,
    );
  }

  void createCustomSystem({
    required String name,
    required String description,
    required List<String> attributes,
  }) {
    final sys = RpgSystem(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      version: 'v1.0',
      segment: SystemSegment.proprios,
      diceEngine: '3d6',
      description: description.trim(),
      attributes: attributes,
      downloadsCount: 1,
      rating: 5.0,
      isOfficial: false,
    );
    systems = [sys, ...systems];
    compendiumItems = [
      ...compendiumItems,
      CompendiumItem(
        id: 'cmp_init_${sys.id}',
        systemId: sys.id,
        category: CompendiumCategory.itens,
        name: 'Grimório Base de ${sys.name}',
        rarity: 'Comum',
        slotsWeight: 1,
        description: 'Item inicial gerado na Forja de Sistema.',
      ),
    ];
    notifyListeners();
  }

  // ---- Comunidades, Fórum & Chat Híbrido WhatsApp + Discord ----

  void contributeGuildBoost(String guildId, int points) {
    guilds = guilds.map((g) {
      if (g.id != guildId) return g;
      final next = (g.boostPoints + points).clamp(0, g.boostGoal);
      return Guild(
        id: g.id,
        name: g.name,
        tag: g.tag,
        leaderHandle: g.leaderHandle,
        description: g.description,
        memberCount: g.memberCount,
        activeTablesCount: g.activeTablesCount,
        boostPoints: next,
        boostGoal: g.boostGoal,
        sharedWorldName: g.sharedWorldName,
        currentSeason: g.currentSeason,
      );
    }).toList();
    notifyListeners();
  }

  void createForumTopic({
    required String category,
    required String title,
    required String content,
  }) {
    final topic = ForumTopic(
      id: 'top_${DateTime.now().millisecondsSinceEpoch}',
      authorHandle: '@${currentUser.username}',
      category: category,
      title: title.trim(),
      content: content.trim(),
      upvotes: 1,
      repliesCount: 0,
      pinned: false,
      timeAgo: 'agora',
    );
    forumTopics = [topic, ...forumTopics];
    notifyListeners();
  }

  void upvoteTopic(String topicId) {
    forumTopics = forumTopics.map((t) {
      if (t.id != topicId) return t;
      return t.copyWith(upvotes: t.upvotes + 1);
    }).toList();
    notifyListeners();
  }

  void sendCommunityMessage({
    required String content,
    String channelId = 'taverna-dos-mestres',
    String? replyPreview,
    bool with3d6Roll = false,
    String rollLabel = 'ROLAGEM NA TAVERNA (3D6)',
  }) {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final diceRoll = with3d6Roll ? _roll3d6.execute(label: rollLabel) : null;

    final message = ChatMessage(
      id: 'msg_${now.millisecondsSinceEpoch}',
      channelId: channelId,
      senderHandle: '@${currentUser.username}',
      senderRole: currentUser.role,
      content: content.trim(),
      timeText: '$hh:$mm',
      isMine: true,
      isRead: true,
      replyPreview: replyPreview,
      diceRoll: diceRoll,
    );
    chatMessages = [...chatMessages, message];
    notifyListeners();
  }

  DiceRoll3d6 rollHeroAttributeTest(String attributeName) {
    final result = _roll3d6.execute(label: 'TESTE DE $attributeName (3D6)');
    lastHeroRoll = result;
    notifyListeners();
    return result;
  }

  // ---- Notificações, Tutoriais & Social ----

  void markAllNotificationsRead() {
    notifications =
        notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  void markNotificationRead(String id) {
    notifications = notifications
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    notifyListeners();
  }

  void toggleTutorialCompleted(String tutorialId) {
    tutorials = tutorials
        .map((t) => t.id == tutorialId ? t.copyWith(completed: !t.completed) : t)
        .toList();
    notifyListeners();
  }

  void addFriendByUsername(String rawHandle) {
    final clean = rawHandle.replaceAll('@', '').trim().toLowerCase();
    if (clean.length < 3) return;
    friends = [
      FriendContact(
        id: 'fr_${DateTime.now().millisecondsSinceEpoch}',
        username: clean,
        displayName: clean.toUpperCase(),
        presenceStatus: 'Online',
        activity: 'Convite enviado agora',
        lastDm: 'Convite de amizade pendente.',
      ),
      ...friends,
    ];
    notifyListeners();
  }

  // ---- Denúncia Universal & Governança Admin ----

  UniversalReport submitUniversalReport({
    required String originType,
    required String originId,
    required String reasonCategory,
    required String description,
  }) {
    final report = _buildReport.execute(
      originType: originType,
      originId: originId,
      reasonCategory: reasonCategory,
      description: description,
      reporterRole: currentUser.role,
      sessionContext: 'hub_tab_$currentTabIndex',
    );
    reports = [report, ...reports];
    notifyListeners();
    return report;
  }

  void moderateReport({
    required String reportId,
    required String decision,
    bool applyHardwareBan = false,
  }) {
    if (!RbacGuard.canModerateReports(currentUser.role)) return;
    reports = reports
        .map((r) => r.id == reportId ? r.copyWith(status: decision) : r)
        .toList();
    if (applyHardwareBan) {
      hardwareBannedFingerprints = [
        'fp_device_${reportId.substring(0, 6)}',
        ...hardwareBannedFingerprints,
      ];
    }
    notifyListeners();
  }
}

