import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/security/rbac_guard.dart';
import '../core/theme/arcana_colors.dart';
import '../data/datasources/cloudflare_edge_client.dart';
import '../data/datasources/local_storage_datasource.dart';
import '../data/repositories/arcana_seed_repository.dart';
import '../domain/entities/arcana_entities.dart';
import '../domain/usecases/authenticate_oauth_usecase.dart';
import '../domain/usecases/build_universal_report_usecase.dart';
import '../domain/usecases/filter_compendium_categories_usecase.dart';
import '../domain/usecases/roll_3d6_usecase.dart';

typedef GoogleSignInProvider = Future<Map<String, String>?> Function();

/// Controller central reativo do ArcanaVTT (Camada Controllers da Clean Architecture).
class AppController extends ChangeNotifier {
  final CloudflareEdgeClient edgeClient;
  final LocalStorageDatasource localStorage;
  final Roll3d6UseCase _roll3d6;
  final FilterCompendiumCategoriesUseCase _filterCompendium;
  final BuildUniversalReportUseCase _buildReport;
  final AuthenticateOAuthUseCase _oauthUseCase;
  final GoogleSignInProvider? googleSignInProvider;

  AppController({
    CloudflareEdgeClient? edgeClient,
    LocalStorageDatasource? localStorage,
    Roll3d6UseCase? roll3d6,
    FilterCompendiumCategoriesUseCase? filterCompendium,
    BuildUniversalReportUseCase? buildReport,
    AuthenticateOAuthUseCase? oauthUseCase,
    this.googleSignInProvider,
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
  int p2pCacheMb = 0;

  // Estado de Autenticação OAuth 2.0 & Configuração Edge
  bool isAuthenticated = false;
  bool isSyncing = false;
  bool trustDevice = true;
  OAuthSecurityState loginViewState = OAuthSecurityState.padrao;
  String? authErrorTitle;
  String? authErrorMessage;
  String? lastSyncError;
  DateTime selectedBirthDate = DateTime(2000, 1, 1);
  UserRole initialRequestedRole = UserRole.mestre;
  String googleServerClientId = LocalStorageDatasource.defaultGoogleServerClientId;

  UserAccount currentUser = const UserAccount(
    id: '',
    email: '',
    username: '',
    displayName: 'Aventureiro',
    bio: '',
    avatarIcon: 'crown',
    role: UserRole.mestre,
    reputationPoints: 100,
    onboardingCompleted: false,
    trustedDeviceEnabled: true,
    trustedDaysRemaining: 30,
  );

  // Estado do Hub Central e Abas
  int currentTabIndex = 0;

  // Dados Vivos (hidratados do Cloudflare D1; sem mocks fictícios)
  List<Campaign> campaigns = [];
  HeroCharacter? hero;
  List<RpgSystem> systems = ArcanaSeedData.officialSystems();
  List<CompendiumItem> compendiumItems = ArcanaSeedData.officialCompendium();
  List<Guild> guilds = [];
  List<ForumTopic> forumTopics = [];
  List<ChatMessage> chatMessages = [];
  List<FriendContact> friends = [];
  List<AppNotification> notifications = [];
  List<TutorialModule> tutorials = ArcanaSeedData.initialTutorials();
  List<NewsItem> news = ArcanaSeedData.initialNews();
  List<UniversalReport> reports = [];
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
    edgeClient.bearerToken = session['bearerToken'] as String?;
    googleServerClientId =
        (session['googleClientId'] as String?) ?? googleServerClientId;

    currentUser = UserAccount(
      id: (session['userId'] as String?) ?? '',
      email: (session['email'] as String?) ?? '',
      username: (session['username'] as String?) ?? '',
      displayName: (session['displayName'] as String?) ?? 'Aventureiro',
      bio: (session['bio'] as String?) ?? '',
      avatarIcon: 'crown',
      role: UserRole.fromWire((session['role'] as String?) ?? 'mestre'),
      reputationPoints: 100,
      onboardingCompleted: true,
      trustedDeviceEnabled: trustDevice,
      trustedDaysRemaining: trustDevice ? 30 : 1,
    );
    notifyListeners();

    if (isAuthenticated && (edgeClient.bearerToken?.isNotEmpty ?? false)) {
      await hydrateAllFromBackend();
    }
  }

  // ---- Configuração Cloudflare Edge & Google Client ID ----

  Future<void> updateServerConfig({
    required String edgeUrl,
    String? googleClientId,
  }) async {
    final cleanUrl = edgeUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (cleanUrl.isNotEmpty) {
      edgeClient.baseUrl = cleanUrl;
      await localStorage.saveEdgeUrl(cleanUrl);
    }
    if (googleClientId != null) {
      googleServerClientId = googleClientId.trim();
      await localStorage.saveGoogleClientId(googleServerClientId);
    }
    notifyListeners();
  }

  Future<EdgeResponse> testEdgeConnection() async {
    return edgeClient.checkHealth();
  }

  // ---- Autenticação 100% Google OAuth 2.0 ----

  void setSelectedBirthDate(DateTime date) {
    selectedBirthDate = date;
    notifyListeners();
  }

  void setInitialRequestedRole(UserRole role) {
    if (role == UserRole.jogador ||
        role == UserRole.assistenteMestre ||
        role == UserRole.mestre) {
      initialRequestedRole = role;
      notifyListeners();
    }
  }

  void setTrustDevice(bool value) {
    trustDevice = value;
    currentUser = currentUser.copyWith(trustedDeviceEnabled: value);
    notifyListeners();
  }

  void resetLoginState() {
    loginViewState = OAuthSecurityState.padrao;
    authErrorTitle = null;
    authErrorMessage = null;
    notifyListeners();
  }

  void _applyBackendErrorState(String code, String message) {
    authErrorMessage = message;
    switch (code) {
      case 'AGE_RESTRICTED':
        loginViewState = OAuthSecurityState.erroMenorIdade;
        authErrorTitle = 'Restrição Etária LGPD (< 16 anos)';
      case 'HARDWARE_BANNED':
        loginViewState = OAuthSecurityState.erroHardwareBan;
        authErrorTitle = 'Dispositivo Bloqueado (Hardware Ban)';
      case 'ACCOUNT_LOCKED':
        loginViewState = OAuthSecurityState.erroLockoutTotal;
        authErrorTitle = 'Conta em Lockout Total Preventivo';
      default:
        loginViewState = OAuthSecurityState.erroHardwareBan;
        authErrorTitle = 'Falha na Autenticação ($code)';
    }
  }

  Future<bool> signInWithGoogleOAuth({
    DateTime? birthDate,
    UserRole? requestedRole,
    bool simulateHardwareBan = false,
    bool simulateLockout = false,
  }) async {
    final effectiveBirth = birthDate ?? selectedBirthDate;
    final effectiveRole = requestedRole ?? initialRequestedRole;

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

    isSyncing = true;
    authErrorTitle = null;
    authErrorMessage = null;
    notifyListeners();

    String? googleSub;
    String? email;
    String? displayName;
    String? idToken;

    try {
      if (googleSignInProvider != null) {
        final provided = await googleSignInProvider!();
        if (provided == null) {
          isSyncing = false;
          notifyListeners();
          return false;
        }
        googleSub = provided['sub'];
        email = provided['email'];
        displayName = provided['displayName'];
        idToken = provided['idToken'];
      } else {
        final googleSignIn = GoogleSignIn(
          scopes: const ['email', 'profile'],
          serverClientId: googleServerClientId.isNotEmpty
              ? googleServerClientId
              : null,
        );
        final account = await googleSignIn.signIn();
        if (account == null) {
          isSyncing = false;
          notifyListeners();
          return false;
        }
        final auth = await account.authentication;
        googleSub = account.id;
        email = account.email;
        displayName = (account.displayName != null &&
                account.displayName!.trim().length >= 2)
            ? account.displayName!.trim()
            : account.email.split('@').first;
        idToken = auth.idToken;
      }
    } catch (e) {
      isSyncing = false;
      loginViewState = OAuthSecurityState.erroHardwareBan;
      authErrorTitle = 'Falha no Google Sign-In Android';
      authErrorMessage =
          'Não foi possível obter a conta Google neste aparelho ($e). Verifique se o Client ID OAuth com SHA-1 deste APK foi cadastrado no Google Cloud Console.';
      notifyListeners();
      return false;
    }

    final payload = <String, dynamic>{
      'action': 'oauth_google',
      'google_sub': googleSub ?? 'sub_google',
      'email': email ?? '',
      'display_name': displayName ?? 'Aventureiro',
      'birth_date':
          '${effectiveBirth.year.toString().padLeft(4, '0')}-${effectiveBirth.month.toString().padLeft(2, '0')}-${effectiveBirth.day.toString().padLeft(2, '0')}',
      'device_fingerprint': 'android-keystore-arcana-v1',
      'trust_device': trustDevice,
      'requested_role': effectiveRole.wireKey,
      if (idToken != null && idToken.isNotEmpty) 'id_token': idToken,
    };

    final res = await edgeClient.postAuth(payload);
    final isStubTestFallback =
        googleSignInProvider != null && res.data['stub'] == true;

    if (!res.ok && !isStubTestFallback) {
      isSyncing = false;
      if (res.statusCode == 0) {
        loginViewState = OAuthSecurityState.erroHardwareBan;
        authErrorTitle = 'Servidor Cloudflare Inacessível';
        authErrorMessage =
            'Não foi possível conectar ao backend em ${edgeClient.baseUrl}. Publique o Worker com Wrangler e confirme a URL nas configurações de conexão.';
      } else {
        final err = res.data['error'] as Map<String, dynamic>?;
        final code = (err?['code'] as String?) ?? 'AUTH_ERROR';
        final msg = (err?['message'] as String?) ??
            'Erro ao autenticar sessão no servidor Cloudflare.';
        _applyBackendErrorState(code, msg);
      }
      notifyListeners();
      return false;
    }

    if (res.ok) {
      final token = res.data['token'] as String?;
      final userJson = (res.data['user'] as Map<String, dynamic>?) ?? {};
      final profileJson = (res.data['profile'] as Map<String, dynamic>?) ?? {};
      edgeClient.bearerToken = token;

      final onboardingDone = (profileJson['onboarding_completed'] as int? ?? 0) == 1;
      currentUser = UserAccount(
        id: (userJson['id'] as String?) ?? '',
        email: (userJson['email'] as String?) ?? (email ?? ''),
        username: (profileJson['username'] as String?) ??
            (email ?? 'heroi').split('@').first,
        displayName: (profileJson['display_name'] as String?) ??
            (displayName ?? 'Aventureiro'),
        bio: (profileJson['bio'] as String?) ?? '',
        avatarIcon: (profileJson['avatar_icon'] as String?) ?? 'crown',
        role: UserRole.fromWire((userJson['role'] as String?) ?? effectiveRole.wireKey),
        reputationPoints: (profileJson['reputation_points'] as int?) ?? 100,
        onboardingCompleted: onboardingDone,
        trustedDeviceEnabled: trustDevice,
        trustedDaysRemaining: (res.data['trusted_device_days'] as int?) ?? 30,
      );
      loginViewState = onboardingDone
          ? OAuthSecurityState.padrao
          : OAuthSecurityState.sucessoAutenticado;
      isAuthenticated = true;

      await localStorage.saveSessionState(
        active: true,
        trustedDevice: trustDevice,
        userId: currentUser.id,
        email: currentUser.email,
        username: currentUser.username,
        displayName: currentUser.displayName,
        bio: currentUser.bio,
        role: currentUser.role.wireKey,
        bearerToken: token,
      );
      await hydrateAllFromBackend();
    } else {
      // Caminho restrito apenas a testes automatizados offline com provider injetado
      final userEmail = email ?? 'aventureiro@gmail.com';
      final baseUser = userEmail.split('@').first.toLowerCase();
      currentUser = UserAccount(
        id: 'usr_local_${userEmail.hashCode}',
        email: userEmail,
        username: baseUser,
        displayName: displayName ?? 'Aventureiro',
        bio: '',
        avatarIcon: 'crown',
        role: effectiveRole,
        reputationPoints: 100,
        onboardingCompleted: true,
        trustedDeviceEnabled: trustDevice,
        trustedDaysRemaining: trustDevice ? 30 : 1,
      );
      loginViewState = OAuthSecurityState.sucessoAutenticado;
      isAuthenticated = true;
    }

    isSyncing = false;
    notifyListeners();
    return true;
  }

  Future<bool> verifyLockoutRecovery({
    required String email,
    required String recoveryCode,
  }) async {
    final res = await edgeClient.postAuth({
      'action': 'lockout_verify',
      'email': email.trim(),
      'recovery_code': recoveryCode.trim(),
      'device_fingerprint': 'android-keystore-arcana-v1',
    });
    if (res.ok) {
      resetLoginState();
      return true;
    }
    final err = res.data['error'] as Map<String, dynamic>?;
    authErrorMessage =
        (err?['message'] as String?) ?? 'Código de recuperação inválido ou expirado.';
    notifyListeners();
    return false;
  }

  Future<void> completeLoginTransitionToHub({
    required String newUsername,
    required String newDisplayName,
  }) async {
    await updateProfile(
      username: newUsername,
      displayName: newDisplayName,
      bio: currentUser.bio,
    );
    isAuthenticated = true;
    loginViewState = OAuthSecurityState.padrao;
    notifyListeners();
  }

  Future<void> logout({bool revokeGlobal = false}) async {
    if (revokeGlobal && (edgeClient.bearerToken?.isNotEmpty ?? false)) {
      await edgeClient.postAuth({'action': 'logout', 'scope': 'global'});
    }
    if (googleSignInProvider == null) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
    edgeClient.bearerToken = null;
    isAuthenticated = false;
    loginViewState = OAuthSecurityState.padrao;
    campaigns = [];
    hero = null;
    guilds = [];
    forumTopics = [];
    chatMessages = [];
    friends = [];
    notifications = [];
    reports = [];
    currentTabIndex = 0;
    await localStorage.clearSession();
    notifyListeners();
  }

  Future<void> triggerTotalLockout() async {
    if (currentUser.id.isNotEmpty) {
      await edgeClient.postAuth({
        'action': 'lockout_trigger',
        'user_id': currentUser.id,
        'reason': 'Acionado pelo usuario nas Configuracoes Gerais',
      });
    }
    edgeClient.bearerToken = null;
    isAuthenticated = false;
    await localStorage.clearSession();
    loginViewState = OAuthSecurityState.erroLockoutTotal;
    authErrorTitle = 'Conta em Lockout Total Preventivo';
    authErrorMessage =
        'Todas as sessões foram revogadas. Insira o código de 6 dígitos enviado ao seu e-mail Google.';
    notifyListeners();
  }

  // ---- Hidratação Completa do Banco Cloudflare D1 ----

  Future<void> hydrateAllFromBackend() async {
    if (edgeClient.bearerToken == null || edgeClient.bearerToken!.isEmpty) {
      return;
    }
    isSyncing = true;
    lastSyncError = null;
    notifyListeners();

    try {
      final sysRes = await edgeClient.postSync({'action': 'systems.list', 'segment': 'todos'});
      if (sysRes.ok) {
        final rawSystems = (sysRes.data['systems'] as List<dynamic>?) ?? [];
        if (rawSystems.isNotEmpty) {
          systems = rawSystems
              .whereType<Map<String, dynamic>>()
              .map(_mapSystem)
              .toList();
        }
      }

      final cmpRes = await edgeClient.postSync({'action': 'campaigns.list', 'filter': 'todas'});
      if (cmpRes.ok) {
        final rawCmps = (cmpRes.data['campaigns'] as List<dynamic>?) ?? [];
        final rawMembers = (cmpRes.data['memberships'] as List<dynamic>?) ?? [];
        final memberByCmp = <String, Map<String, dynamic>>{};
        for (final m in rawMembers.whereType<Map<String, dynamic>>()) {
          final id = m['campaign_id'] as String?;
          if (id != null) memberByCmp[id] = m;
        }
        campaigns = rawCmps
            .whereType<Map<String, dynamic>>()
            .map((c) => _mapCampaign(c, memberByCmp[c['id']]))
            .toList();
      }

      final allComp = <CompendiumItem>[];
      for (final sys in systems) {
        final compRes = await edgeClient.postSync({
          'action': 'compendium.query',
          'system_id': sys.id,
        });
        if (compRes.ok) {
          final items = (compRes.data['items'] as List<dynamic>?) ?? [];
          allComp.addAll(
            items.whereType<Map<String, dynamic>>().map(_mapCompendiumItem),
          );
        }
      }
      if (allComp.isNotEmpty) {
        compendiumItems = allComp;
      }

      final commRes = await edgeClient.postSync({
        'action': 'communities.overview',
        'channel_id': 'taverna-dos-mestres',
      });
      if (commRes.ok) {
        final rawGuilds = (commRes.data['guilds'] as List<dynamic>?) ?? [];
        guilds = rawGuilds.whereType<Map<String, dynamic>>().map(_mapGuild).toList();

        final rawTopics = (commRes.data['forum_topics'] as List<dynamic>?) ?? [];
        forumTopics = rawTopics
            .whereType<Map<String, dynamic>>()
            .map(_mapForumTopic)
            .toList();

        final rawMsgs = (commRes.data['messages'] as List<dynamic>?) ?? [];
        chatMessages = rawMsgs
            .whereType<Map<String, dynamic>>()
            .map(_mapChatMessage)
            .toList();
      }

      final socialRes = await edgeClient.postSync({'action': 'social.overview'});
      if (socialRes.ok) {
        final rawFriends = (socialRes.data['friends'] as List<dynamic>?) ?? [];
        friends = rawFriends
            .whereType<Map<String, dynamic>>()
            .map(_mapFriend)
            .toList();

        final rawNotifs =
            (socialRes.data['notifications'] as List<dynamic>?) ?? [];
        notifications = rawNotifs
            .whereType<Map<String, dynamic>>()
            .map(_mapNotification)
            .toList();

        final rawChars = (socialRes.data['characters'] as List<dynamic>?) ?? [];
        if (rawChars.isNotEmpty && rawChars.first is Map<String, dynamic>) {
          hero = _mapCharacter(rawChars.first as Map<String, dynamic>);
        }
      }

      if (RbacGuard.canAccessAdminPanel(currentUser.role)) {
        final adminRes = await edgeClient.postSync({'action': 'admin.overview'});
        if (adminRes.ok) {
          final rawReports = (adminRes.data['reports'] as List<dynamic>?) ?? [];
          reports = rawReports
              .whereType<Map<String, dynamic>>()
              .map(_mapReport)
              .toList();
        }
      }
    } catch (e) {
      lastSyncError = e.toString();
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  // ---- Navegação & RBAC ----

  void setTabIndex(int index) {
    currentTabIndex = index;
    notifyListeners();
  }

  /// Alternância de papel apenas em memória para testes de Widget Tree Pruning.
  void switchActiveRoleForPreview(UserRole role) {
    currentUser = currentUser.copyWith(role: role);
    notifyListeners();
  }

  // ---- Perfil, Temas & Acessibilidade ----

  Future<void> setThemeMode(ArcanaThemeMode mode) async {
    themeMode = mode;
    await localStorage.saveTheme(mode);
    notifyListeners();
    if (edgeClient.bearerToken?.isNotEmpty ?? false) {
      await _syncCurrentProfile();
    }
  }

  Future<void> setFontScale(double scale) async {
    fontScale = scale.clamp(0.8, 1.5);
    await localStorage.saveFontScale(fontScale);
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String username,
    required String displayName,
    required String bio,
    UserRole? preferredRole,
  }) async {
    final cleanUsername =
        username.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    final nextUsername =
        cleanUsername.length >= 3 ? cleanUsername : currentUser.username;
    final nextDisplay = displayName.trim().isNotEmpty
        ? displayName.trim()
        : currentUser.displayName;
    final nextBio = bio.trim();

    if (edgeClient.bearerToken?.isNotEmpty ?? false) {
      final res = await edgeClient.postSync({
        'action': 'profile.setup',
        'username': nextUsername,
        'display_name': nextDisplay,
        'bio': nextBio,
        if (preferredRole != null) 'preferred_role': preferredRole.wireKey,
        'theme_preference': themeMode.wireKey,
        'font_scale': fontScale,
      });
      if (!res.ok) {
        final err = res.data['error'] as Map<String, dynamic>?;
        lastSyncError = (err?['message'] as String?) ?? 'Falha ao atualizar perfil.';
        notifyListeners();
        return false;
      }
      final updatedRoleStr = res.data['role'] as String?;
      currentUser = currentUser.copyWith(
        username: nextUsername,
        displayName: nextDisplay,
        bio: nextBio,
        role: updatedRoleStr != null
            ? UserRole.fromWire(updatedRoleStr)
            : preferredRole ?? currentUser.role,
        onboardingCompleted: true,
      );
    } else {
      currentUser = currentUser.copyWith(
        username: nextUsername,
        displayName: nextDisplay,
        bio: nextBio,
        role: preferredRole ?? currentUser.role,
        onboardingCompleted: true,
      );
    }

    await localStorage.saveSessionState(
      active: isAuthenticated,
      trustedDevice: trustDevice,
      userId: currentUser.id,
      email: currentUser.email,
      username: currentUser.username,
      displayName: currentUser.displayName,
      bio: currentUser.bio,
      role: currentUser.role.wireKey,
      bearerToken: edgeClient.bearerToken,
    );
    notifyListeners();
    return true;
  }

  Future<void> _syncCurrentProfile() async {
    if (currentUser.username.length < 3) return;
    await edgeClient.postSync({
      'action': 'profile.setup',
      'username': currentUser.username,
      'display_name': currentUser.displayName,
      'bio': currentUser.bio,
      'theme_preference': themeMode.wireKey,
      'font_scale': fontScale,
    });
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

  Future<Campaign?> quickJoinByCode(String rawCode) async {
    final normalized =
        rawCode.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (normalized.length < 4) return null;

    if (edgeClient.bearerToken?.isNotEmpty ?? false) {
      final res = await edgeClient.postSync({
        'action': 'campaigns.quick_join',
        'code': normalized,
      });
      if (!res.ok) {
        final err = res.data['error'] as Map<String, dynamic>?;
        lastSyncError = (err?['message'] as String?) ?? 'Código não localizado.';
        notifyListeners();
        return null;
      }
      final raw = res.data['campaign'] as Map<String, dynamic>?;
      if (raw != null) {
        final joined = _mapCampaign(raw, {'table_role': 'jogador', 'status': 'active'});
        campaigns = [
          joined,
          ...campaigns.where((c) => c.id != joined.id),
        ];
        notifyListeners();
        return joined;
      }
      return null;
    }

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

  Future<Campaign?> createCampaign({
    required String title,
    required String synopsis,
    required String systemId,
    required CampaignMode mode,
    required String scheduleText,
    required int maxSlots,
    required bool isPublic,
  }) async {
    if (!RbacGuard.canForgeCampaign(currentUser.role)) return null;

    if (edgeClient.bearerToken?.isNotEmpty ?? false) {
      final res = await edgeClient.postSync({
        'action': 'campaigns.create',
        'title': title.trim(),
        'synopsis': synopsis.trim(),
        'system_id': systemId,
        'mode': _campaignModeToWire(mode),
        'schedule_text': scheduleText.trim().isEmpty
            ? 'Tempo Livre'
            : scheduleText.trim(),
        'max_slots': maxSlots,
        'visibility': isPublic ? 'publica' : 'privada',
      });
      if (!res.ok) {
        final err = res.data['error'] as Map<String, dynamic>?;
        lastSyncError = (err?['message'] as String?) ?? 'Erro ao criar campanha.';
        notifyListeners();
        return null;
      }
      final raw = res.data['campaign'] as Map<String, dynamic>?;
      if (raw != null) {
        final created = _mapCampaign(raw, {'table_role': 'mestre', 'status': 'active'});
        campaigns = [created, ...campaigns];
        notifyListeners();
        return created;
      }
      return null;
    }

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
    return newCampaign;
  }

  Future<bool> applyToCampaign({
    required String campaignId,
    required String characterName,
    required String pitch,
  }) async {
    if (edgeClient.bearerToken?.isNotEmpty ?? false) {
      final res = await edgeClient.postSync({
        'action': 'campaigns.apply',
        'campaign_id': campaignId,
        'character_name': characterName.trim(),
        'pitch': pitch.trim(),
      });
      return res.ok;
    }
    return true;
  }

  // ---- Ficha de Herói ----

  Future<bool> saveHeroCharacter({
    required String name,
    required String heroClass,
    required String campaignTitle,
    required int level,
    required int corpo,
    required int mente,
    required int espirito,
    required List<String> slots,
  }) async {
    final existingId = hero?.id;
    if (edgeClient.bearerToken?.isNotEmpty ?? false) {
      final res = await edgeClient.postSync({
        'action': 'characters.upsert',
        'id': ?existingId,
        'name': name.trim(),
        'title': heroClass.trim(),
        'system_id': systems.first.id,
        'level': level,
        'corpo': corpo,
        'mente': mente,
        'espirito': espirito,
        'hp_current': 14 + corpo * 2,
        'hp_max': 14 + corpo * 2,
        'anima_current': 6 + espirito,
        'anima_max': 6 + espirito,
        'exhaustion': 0,
        'slots': slots,
      });
      if (!res.ok) return false;
      final rawChar = res.data['character'] as Map<String, dynamic>?;
      if (rawChar != null) {
        hero = _mapCharacter(rawChar);
        notifyListeners();
        return true;
      }
    }

    hero = HeroCharacter(
      id: existingId ?? 'chr_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      heroClass: heroClass.trim(),
      campaignTitle: campaignTitle.trim().isEmpty ? 'Sem Campanha' : campaignTitle.trim(),
      level: level,
      hpCurrent: 14 + corpo * 2,
      hpMax: 14 + corpo * 2,
      animaCurrent: 6 + espirito,
      animaMax: 6 + espirito,
      exhaustion: 0,
      corpo: corpo,
      mente: mente,
      espirito: espirito,
      slots: slots,
    );
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

  Future<void> createCustomSystem({
    required String name,
    required String description,
    required List<String> attributes,
  }) async {
    if (edgeClient.bearerToken?.isNotEmpty ?? false) {
      final res = await edgeClient.postSync({
        'action': 'systems.create',
        'name': name.trim(),
        'version': 'v1.0',
        'dice_engine': '3d6',
        'description': description.trim(),
        'attributes': attributes,
      });
      if (res.ok && res.data['system'] is Map<String, dynamic>) {
        final created = _mapSystem(res.data['system'] as Map<String, dynamic>);
        systems = [created, ...systems];
        notifyListeners();
        return;
      }
    }

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
        category: CompendiumCategory.poderes,
        name: 'Poder Inicial de ${sys.name}',
        rarity: 'Comum',
        slotsWeight: 0,
        description: 'Habilidade gerada automaticamente na Forja de Sistema.',
      ),
    ];
    notifyListeners();
  }

  // ---- Comunidades, Guildas, Fórum & Chat Híbrido WhatsApp + Discord ----

  Future<bool> createGuild({
    required String name,
    required String tag,
    required String description,
    String sharedWorldName = 'Continente de Valen',
    String currentSeason = 'Temporada I',
  }) async {
    if (edgeClient.bearerToken?.isNotEmpty ?? false) {
      final res = await edgeClient.postSync({
        'action': 'guilds.create',
        'name': name.trim(),
        'tag': tag.trim().toUpperCase(),
        'description': description.trim(),
        'shared_world_name': sharedWorldName,
        'current_season': currentSeason,
      });
      if (!res.ok) return false;
      if (res.data['guild'] is Map<String, dynamic>) {
        guilds = [_mapGuild(res.data['guild'] as Map<String, dynamic>), ...guilds];
        notifyListeners();
        return true;
      }
    }

    final cleanTag =
        tag.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final created = Guild(
      id: 'gld_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      tag: cleanTag.isEmpty ? 'ARC' : cleanTag,
      leaderHandle: '@${currentUser.username}',
      description: description.trim(),
      memberCount: 1,
      activeTablesCount: 0,
      boostPoints: 0,
      boostGoal: 1000,
      sharedWorldName: sharedWorldName,
      currentSeason: currentSeason,
    );
    guilds = [created, ...guilds];
    notifyListeners();
    return true;
  }

  Future<void> contributeGuildBoost(String guildId, int points) async {
    if (edgeClient.bearerToken?.isNotEmpty ?? false) {
      final res = await edgeClient.postSync({
        'action': 'guilds.boost',
        'guild_id': guildId,
        'points': points,
      });
      if (res.ok && res.data['guild'] is Map<String, dynamic>) {
        final updated = _mapGuild(res.data['guild'] as Map<String, dynamic>);
        guilds = guilds.map((g) => g.id == guildId ? updated : g).toList();
        notifyListeners();
        return;
      }
    }

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

  Future<void> createForumTopic({
    required String category,
    required String title,
    required String content,
  }) async {
    if (edgeClient.bearerToken?.isNotEmpty ?? false) {
      final res = await edgeClient.postSync({
        'action': 'forum.create_topic',
        'category': category,
        'title': title.trim(),
        'content': content.trim(),
      });
      if (res.ok && res.data['topic'] is Map<String, dynamic>) {
        final created = _mapForumTopic(res.data['topic'] as Map<String, dynamic>);
        forumTopics = [created, ...forumTopics];
        notifyListeners();
        return;
      }
    }

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

  Future<void> upvoteTopic(String topicId) async {
    if (edgeClient.bearerToken?.isNotEmpty ?? false) {
      final res = await edgeClient.postSync({
        'action': 'forum.upvote',
        'topic_id': topicId,
      });
      if (res.ok && res.data['topic'] is Map<String, dynamic>) {
        final updated = _mapForumTopic(res.data['topic'] as Map<String, dynamic>);
        forumTopics = forumTopics.map((t) => t.id == topicId ? updated : t).toList();
        notifyListeners();
        return;
      }
    }

    forumTopics = forumTopics.map((t) {
      if (t.id != topicId) return t;
      return t.copyWith(upvotes: t.upvotes + 1);
    }).toList();
    notifyListeners();
  }

  Future<void> sendCommunityMessage({
    required String content,
    String channelId = 'taverna-dos-mestres',
    String? replyPreview,
    bool with3d6Roll = false,
    String rollLabel = 'ROLAGEM NA TAVERNA (3D6)',
  }) async {
    if (edgeClient.bearerToken?.isNotEmpty ?? false) {
      final res = await edgeClient.postSync({
        'action': 'chat.send_message',
        'channel_id': channelId,
        'content': content.trim(),
        'with_3d6_roll': with3d6Roll,
        'roll_label': rollLabel,
      });
      if (res.ok && res.data['message'] is Map<String, dynamic>) {
        final sent = _mapChatMessage(res.data['message'] as Map<String, dynamic>);
        chatMessages = [...chatMessages, sent];
        notifyListeners();
        return;
      }
    }

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

  Future<void> markAllNotificationsRead() async {
    if (edgeClient.bearerToken?.isNotEmpty ?? false) {
      await edgeClient.postSync({'action': 'notifications.mark_read'});
    }
    notifications =
        notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  Future<void> markNotificationRead(String id) async {
    if (edgeClient.bearerToken?.isNotEmpty ?? false) {
      await edgeClient.postSync({
        'action': 'notifications.mark_read',
        'notification_id': id,
      });
    }
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

  Future<String?> addFriendByUsername(String rawHandle) async {
    final clean = rawHandle.replaceAll('@', '').trim().toLowerCase();
    if (clean.length < 3) {
      return 'Informe um identificador com ao menos 3 caracteres.';
    }

    if (edgeClient.bearerToken?.isNotEmpty ?? false) {
      final res = await edgeClient.postSync({
        'action': 'social.add_friend',
        'username': clean,
      });
      if (!res.ok) {
        final err = res.data['error'] as Map<String, dynamic>?;
        return (err?['message'] as String?) ?? 'Não foi possível adicionar @$clean.';
      }
      if (res.data['friendship'] is Map<String, dynamic>) {
        final added = _mapFriend(res.data['friendship'] as Map<String, dynamic>);
        friends = [added, ...friends.where((f) => f.id != added.id)];
        notifyListeners();
        return null;
      }
    }

    friends = [
      FriendContact(
        id: 'fr_${DateTime.now().millisecondsSinceEpoch}',
        username: clean,
        displayName: clean.toUpperCase(),
        presenceStatus: 'Online',
        activity: 'Na Taverna',
        lastDm: 'Aliado adicionado agora.',
      ),
      ...friends,
    ];
    notifyListeners();
    return null;
  }

  // ---- Denúncia Universal & Governança Admin ----

  Future<UniversalReport> submitUniversalReport({
    required String originType,
    required String originId,
    required String reasonCategory,
    required String description,
  }) async {
    if (edgeClient.bearerToken?.isNotEmpty ?? false) {
      final res = await edgeClient.postSync({
        'action': 'report.submit',
        'origin_type': originType,
        'origin_id': originId,
        'reason_category': reasonCategory,
        'description': description,
        'context_session': 'hub_tab_$currentTabIndex',
      });
      if (res.ok) {
        final rawTags = (res.data['auto_tags'] as List<dynamic>?) ?? [];
        final report = UniversalReport(
          id: (res.data['report_id'] as String?) ?? 'rep_${DateTime.now().millisecondsSinceEpoch}',
          originType: originType,
          originId: originId,
          reasonCategory: reasonCategory,
          description: description,
          autoTags: rawTags.map((e) => e.toString()).toList(),
          status: (res.data['status'] as String?) ?? 'pending',
          createdAtText: 'agora',
        );
        reports = [report, ...reports];
        notifyListeners();
        return report;
      }
    }

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

  Future<void> moderateReport({
    required String reportId,
    required String decision,
    bool applyHardwareBan = false,
  }) async {
    if (!RbacGuard.canModerateReports(currentUser.role)) return;

    if (edgeClient.bearerToken?.isNotEmpty ?? false) {
      await edgeClient.postSync({
        'action': 'admin.moderate',
        'report_id': reportId,
        'decision': applyHardwareBan ? 'hardware_ban' : decision,
        if (applyHardwareBan) 'ban_device_fingerprint': 'fp_${reportId.substring(0, 6)}',
      });
    }

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

  // ---- Mappers D1 JSON -> Entidades de Domínio ----

  String _campaignModeToWire(CampaignMode mode) {
    switch (mode) {
      case CampaignMode.aoVivo:
        return 'ao_vivo';
      case CampaignMode.tempoLivre:
        return 'tempo_livre';
      case CampaignMode.agendada:
        return 'agendada';
    }
  }

  Campaign _mapCampaign(
    Map<String, dynamic> c,
    Map<String, dynamic>? membership,
  ) {
    final ownerId = (c['owner_id'] as String?) ?? '';
    final tableRole = membership?['table_role'] as String?;
    final memberStatus = membership?['status'] as String?;

    CampaignSegment relation;
    if (ownerId == currentUser.id || tableRole == 'mestre') {
      relation = CampaignSegment.mestre;
    } else if (tableRole == 'assistente_mestre') {
      relation = CampaignSegment.auxiliar;
    } else if (memberStatus == 'active') {
      relation = CampaignSegment.jogando;
    } else {
      relation = CampaignSegment.explorar;
    }

    final modeStr = (c['mode'] as String?) ?? 'ao_vivo';
    final mode = switch (modeStr) {
      'tempo_livre' => CampaignMode.tempoLivre,
      'agendada' => CampaignMode.agendada,
      _ => CampaignMode.aoVivo,
    };

    var chapterTitle = 'Sessão 0';
    try {
      final stateRaw = c['state_json'] as String?;
      if (stateRaw != null && stateRaw.isNotEmpty) {
        final decoded = jsonDecode(stateRaw) as Map<String, dynamic>;
        chapterTitle = (decoded['chapter'] as String?) ?? chapterTitle;
      }
    } catch (_) {}

    final sysId = (c['system_id'] as String?) ?? 'sys_alphad6_v24';
    final matchedSystem = systems.cast<RpgSystem?>().firstWhere(
          (s) => s?.id == sysId,
          orElse: () => null,
        );

    return Campaign(
      id: (c['id'] as String?) ?? '',
      title: (c['title'] as String?) ?? '',
      synopsis: (c['synopsis'] as String?) ?? '',
      masterHandle:
          ownerId == currentUser.id ? '@${currentUser.username}' : '@mestre',
      systemId: sysId,
      systemName: matchedSystem != null
          ? '${matchedSystem.name} ${matchedSystem.version}'
          : 'AlphaD6 Core v2.4',
      quickJoinCode: (c['quick_join_code'] as String?) ?? '',
      mode: mode,
      scheduleText: (c['schedule_text'] as String?) ?? 'Tempo Livre',
      maxSlots: (c['max_slots'] as int?) ?? 5,
      occupiedSlots: (c['occupied_slots'] as int?) ?? 1,
      userRelation: relation,
      chapterTitle: chapterTitle,
      isPublic: ((c['visibility'] as String?) ?? 'publica') == 'publica',
    );
  }

  RpgSystem _mapSystem(Map<String, dynamic> s) {
    final seg = switch ((s['category_type'] as String?) ?? 'proprios') {
      'oficiais' => SystemSegment.oficiais,
      'meus' => SystemSegment.meus,
      'comunidade' => SystemSegment.comunidade,
      _ => SystemSegment.proprios,
    };

    var attrs = <String>['Corpo', 'Mente', 'Espírito'];
    try {
      final rawRules = s['rules_json'] as String?;
      if (rawRules != null && rawRules.isNotEmpty) {
        final decoded = jsonDecode(rawRules) as Map<String, dynamic>;
        final rawList = decoded['attributes'] as List<dynamic>?;
        if (rawList != null && rawList.isNotEmpty) {
          attrs = rawList.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}

    return RpgSystem(
      id: (s['id'] as String?) ?? '',
      name: (s['name'] as String?) ?? '',
      version: (s['version'] as String?) ?? 'v1.0',
      segment: seg,
      diceEngine: (s['dice_engine'] as String?) ?? '3d6',
      description: (s['description'] as String?) ?? '',
      attributes: attrs,
      downloadsCount: (s['downloads_count'] as int?) ?? 0,
      rating: ((s['rating'] as num?) ?? 5.0).toDouble(),
      isOfficial: (s['is_official'] as int? ?? 0) == 1,
    );
  }

  CompendiumItem _mapCompendiumItem(Map<String, dynamic> i) {
    final cat = switch ((i['category'] as String?) ?? 'itens') {
      'equipamentos' => CompendiumCategory.equipamentos,
      'seres' => CompendiumCategory.seres,
      'poderes' => CompendiumCategory.poderes,
      'pistas' => CompendiumCategory.pistas,
      _ => CompendiumCategory.itens,
    };

    return CompendiumItem(
      id: (i['id'] as String?) ?? '',
      systemId: (i['system_id'] as String?) ?? 'sys_alphad6_v24',
      category: cat,
      name: (i['name'] as String?) ?? '',
      rarity: (i['rarity'] as String?) ?? 'Comum',
      slotsWeight: (i['slots_weight'] as int?) ?? 0,
      description: (i['description'] as String?) ?? '',
    );
  }

  Guild _mapGuild(Map<String, dynamic> g) {
    var worldName = 'Continente de Valen';
    var season = 'Temporada I';
    try {
      final raw = g['shared_world_json'] as String?;
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        worldName = (decoded['world'] as String?) ?? worldName;
        season = (decoded['season'] as String?) ?? season;
      }
    } catch (_) {}

    return Guild(
      id: (g['id'] as String?) ?? '',
      name: (g['name'] as String?) ?? '',
      tag: (g['tag'] as String?) ?? '',
      leaderHandle: (g['leader_id'] as String?) == currentUser.id
          ? '@${currentUser.username}'
          : '@lider',
      description: (g['description'] as String?) ?? '',
      memberCount: (g['member_count'] as int?) ?? 1,
      activeTablesCount: (g['active_tables_count'] as int?) ?? 0,
      boostPoints: (g['boost_points'] as int?) ?? 0,
      boostGoal: (g['boost_goal'] as int?) ?? 1000,
      sharedWorldName: worldName,
      currentSeason: season,
    );
  }

  ForumTopic _mapForumTopic(Map<String, dynamic> t) {
    return ForumTopic(
      id: (t['id'] as String?) ?? '',
      authorHandle: (t['author_handle'] as String?) ?? '@aventureiro',
      category: (t['category'] as String?) ?? 'Geral',
      title: (t['title'] as String?) ?? '',
      content: (t['content'] as String?) ?? '',
      upvotes: (t['upvotes'] as int?) ?? 1,
      repliesCount: (t['replies_count'] as int?) ?? 0,
      pinned: (t['pinned'] as int? ?? 0) == 1,
      timeAgo: _formatTimeShort(t['created_at'] as String?),
    );
  }

  ChatMessage _mapChatMessage(Map<String, dynamic> m) {
    DiceRoll3d6? dice;
    try {
      final rawDice = m['dice_roll_json'] as String?;
      if (rawDice != null && rawDice.isNotEmpty) {
        final decoded = jsonDecode(rawDice) as Map<String, dynamic>;
        dice = DiceRoll3d6(
          label: (decoded['label'] as String?) ?? 'ROLAGEM 3D6',
          dice: ((decoded['dice'] as List<dynamic>?) ?? [1, 1, 1])
              .map((d) => (d as num).toInt())
              .toList(),
          successes: (decoded['successes'] as int?) ?? 0,
          outcome: (decoded['outcome'] as String?) ?? '',
        );
      }
    } catch (_) {}

    final senderId = (m['sender_id'] as String?) ?? '';
    return ChatMessage(
      id: (m['id'] as String?) ?? '',
      channelId: (m['channel_id'] as String?) ?? 'taverna-dos-mestres',
      senderHandle: (m['sender_handle'] as String?) ?? '@aventureiro',
      senderRole: UserRole.fromWire((m['sender_role'] as String?) ?? 'jogador'),
      content: (m['content'] as String?) ?? '',
      timeText: _formatHourMinute(m['created_at'] as String?),
      isMine: senderId == currentUser.id,
      isRead: true,
      replyPreview: m['reply_preview'] as String?,
      diceRoll: dice,
    );
  }

  HeroCharacter _mapCharacter(Map<String, dynamic> c) {
    var corpo = 3;
    var mente = 3;
    var espirito = 3;
    try {
      final rawAttr = jsonDecode((c['attributes_json'] as String?) ?? '{}')
          as Map<String, dynamic>;
      corpo = (rawAttr['corpo'] as int?) ?? 3;
      mente = (rawAttr['mente'] as int?) ?? 3;
      espirito = (rawAttr['espirito'] as int?) ?? 3;
    } catch (_) {}

    var slots = <String>[];
    try {
      final rawSlots =
          jsonDecode((c['slots_json'] as String?) ?? '[]') as List<dynamic>;
      slots = rawSlots.map((e) => e.toString()).toList();
    } catch (_) {}

    var hpCur = 20;
    var hpMax = 20;
    var animaCur = 10;
    var animaMax = 10;
    var exhaustion = 0;
    try {
      final rawSt = jsonDecode((c['statuses_json'] as String?) ?? '{}')
          as Map<String, dynamic>;
      hpCur = (rawSt['hp_current'] as int?) ?? 20;
      hpMax = (rawSt['hp_max'] as int?) ?? 20;
      animaCur = (rawSt['anima_current'] as int?) ?? 10;
      animaMax = (rawSt['anima_max'] as int?) ?? 10;
      exhaustion = (rawSt['exhaustion'] as int?) ?? 0;
    } catch (_) {}

    return HeroCharacter(
      id: (c['id'] as String?) ?? '',
      name: (c['name'] as String?) ?? 'Herói',
      heroClass: (c['title'] as String?) ?? 'Aventureiro',
      campaignTitle: 'Taverna ArcanaVTT',
      level: (c['level'] as int?) ?? 1,
      hpCurrent: hpCur,
      hpMax: hpMax,
      animaCurrent: animaCur,
      animaMax: animaMax,
      exhaustion: exhaustion,
      corpo: corpo,
      mente: mente,
      espirito: espirito,
      slots: slots,
    );
  }

  FriendContact _mapFriend(Map<String, dynamic> f) {
    final uname = (f['friend_username'] as String?) ??
        (f['friend_id'] as String?) ??
        'aliado';
    return FriendContact(
      id: (f['friend_id'] as String?) ?? '',
      username: uname,
      displayName: (f['friend_display_name'] as String?) ?? uname,
      presenceStatus: (f['presence_status'] as String?) ?? 'online',
      activity: (f['presence_activity'] as String?) ?? 'Na Taverna',
      lastDm: 'Conectado pelo Cloudflare D1',
    );
  }

  AppNotification _mapNotification(Map<String, dynamic> n) {
    return AppNotification(
      id: (n['id'] as String?) ?? '',
      category: (n['category'] as String?) ?? 'sistema',
      title: (n['title'] as String?) ?? '',
      body: (n['body'] as String?) ?? '',
      timeAgo: _formatTimeShort(n['created_at'] as String?),
      isRead: (n['is_read'] as int? ?? 0) == 1,
    );
  }

  UniversalReport _mapReport(Map<String, dynamic> r) {
    var tags = <String>[];
    try {
      final raw = jsonDecode((r['auto_tags_json'] as String?) ?? '[]')
          as List<dynamic>;
      tags = raw.map((e) => e.toString()).toList();
    } catch (_) {}

    return UniversalReport(
      id: (r['id'] as String?) ?? '',
      originType: (r['origin_type'] as String?) ?? 'chat',
      originId: (r['origin_id'] as String?) ?? '',
      reasonCategory: (r['reason_category'] as String?) ?? '',
      description: (r['description'] as String?) ?? '',
      autoTags: tags,
      status: (r['status'] as String?) ?? 'pending',
      createdAtText: _formatTimeShort(r['created_at'] as String?),
    );
  }

  String _formatHourMinute(String? iso) {
    if (iso == null) return '--:--';
    final parsed = DateTime.tryParse(iso)?.toLocal();
    if (parsed == null) return '--:--';
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formatTimeShort(String? iso) {
    if (iso == null) return 'agora';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return 'agora';
    final diff = DateTime.now().toUtc().difference(parsed.toUtc());
    if (diff.inMinutes < 2) return 'agora';
    if (diff.inHours < 1) return 'há ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'há ${diff.inHours}h';
    return 'há ${diff.inDays}d';
  }
}
