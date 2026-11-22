import 'dart:convert';

import 'package:flutter/foundation.dart';
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
import '../domain/usecases/universal_rpg_engine_usecase.dart';

typedef GoogleSignInProvider = Future<Map<String, String>?> Function();

class AppController extends ChangeNotifier {
  final CloudflareEdgeClient edgeClient;
  final LocalStorageDatasource localStorage;
  final Roll3d6UseCase _roll3d6;
  final UniversalRpgEngineUseCase _universalEngine;
  final FilterCompendiumCategoriesUseCase _filterCompendium;
  final BuildUniversalReportUseCase _buildReport;
  final AuthenticateOAuthUseCase _oauthUseCase;
  final GoogleSignInProvider? googleSignInProvider;
  int _localIdSeq = 0;

  String _nextLocalId(String prefix) {
    _localIdSeq += 1;
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}_$_localIdSeq';
  }

  AppController({
    CloudflareEdgeClient? edgeClient,
    LocalStorageDatasource? localStorage,
    Roll3d6UseCase? roll3d6,
    UniversalRpgEngineUseCase? universalEngine,
    FilterCompendiumCategoriesUseCase? filterCompendium,
    BuildUniversalReportUseCase? buildReport,
    AuthenticateOAuthUseCase? oauthUseCase,
    this.googleSignInProvider,
  })  : edgeClient = edgeClient ?? CloudflareEdgeClient(),
        localStorage = localStorage ?? LocalStorageDatasource(),
        _roll3d6 = roll3d6 ?? Roll3d6UseCase(),
        _universalEngine = universalEngine ?? UniversalRpgEngineUseCase(),
        _filterCompendium = filterCompendium ?? FilterCompendiumCategoriesUseCase(),
        _buildReport = buildReport ?? BuildUniversalReportUseCase(),
        _oauthUseCase = oauthUseCase ?? AuthenticateOAuthUseCase();

  // Preferencias locais persistentes
  ArcanaThemeMode themeMode = ArcanaThemeMode.escuroHeraldico;
  double fontScale = 1.0;
  String appLanguage = 'PT-BR';
  String hapticLevel = 'Medio';
  bool reduceMotion = false;
  bool muteInBackground = true;
  bool externalMediaOnlyOfficial = false;
  bool p2pEnabled = true;
  bool p2pWifiOnly = true;
  String p2pCacheQuota = '1 GB';
  String dmPrivacy = 'Qualquer usuario';
  String showcasePrivacy = 'Publico na Taverna';
  bool onlinePresenceVisible = true;
  AudioMixerSettings audioMixer = const AudioMixerSettings(
    masterVolume: 0.85,
    ambienceVolume: 0.65,
    sfxVolume: 0.9,
    voiceVolume: 1.0,
  );
  int p2pCacheMb = 0;

  // Estado de Sessao Zero-Trust
  bool isAuthenticated = false;
  bool isSyncing = false;
  bool trustDevice = true;
  OAuthSecurityState loginViewState = OAuthSecurityState.padrao;
  String? authErrorTitle;
  String? authErrorMessage;
  String? lastSyncError;
  DateTime selectedBirthDate = DateTime(2000, 1, 1);

  UserAccount currentUser = const UserAccount(
    id: '',
    email: '',
    username: '',
    displayName: 'Aventureiro',
    bio: '',
    avatarIcon: 'shield',
    role: UserRole.jogador,
    reputationPoints: 0,
    onboardingCompleted: false,
    trustedDeviceEnabled: true,
    trustedDaysRemaining: 15,
    socialContacts: {},
  );

  // Estado de Navegacao e Dominio
  int currentTabIndex = 0;
  String activeCommunityChannelId = 'taverna-dos-mestres';
  bool ghostSpectatorActive = false;

  List<Campaign> campaigns = [];
  List<HeroCharacter> characters = [];
  HeroCharacter? get hero => characters.isNotEmpty ? characters.first : null;
  HeroCharacter? characterForCampaign(String campaignId) {
    for (final c in characters) {
      if (c.campaignId == campaignId) return c;
    }
    return null;
  }

  List<RpgSystem> systems = ArcanaSeedData.officialSystems();
  List<String> favoriteSystemIds = [];
  Set<String> offlineCachedSystemIds = {};
  List<CompendiumItem> compendiumItems = ArcanaSeedData.officialCompendium();
  List<Guild> guilds = [];
  List<ForumTopic> forumTopics = [];
  List<ChatMessage> chatMessages = [];
  List<FriendContact> friends = [];
  List<AppNotification> notifications = [];
  List<TutorialModule> tutorials = ArcanaSeedData.initialTutorials();
  List<NewsItem> news = ArcanaSeedData.initialNews();
  List<UniversalReport> reports = [];
  List<AdminUserSummary> adminUsers = [];
  List<String> hardwareBannedFingerprints = [];
  List<BannedDeviceSummary> bannedDevices = [];
  List<SystemCreationKey> systemCreationKeys = [];
  List<Map<String, String>> gmBannedPlayers = [];
  Map<String, List<CampaignScene>> campaignScenesMap = {};
  Map<String, List<HeroCharacter>> campaignCharactersMap = {};
  Map<String, List<ChatMessage>> dmThreads = {};
  DiceRoll3d6? lastHeroRoll;

  int get unreadNotificationsCount =>
      notifications.where((n) => !n.isRead).length;

  String _extractErrorCode(
    Map<String, dynamic> data, [
    String fallback = 'SYNC_ERROR',
  ]) {
    final raw = data['error'];
    if (raw is String && raw.isNotEmpty) return raw;
    if (raw is Map && raw['code'] != null) return raw['code'].toString();
    return fallback;
  }

  String _extractErrorMessage(
    Map<String, dynamic> data, [
    String fallback = 'Falha na comunicacao com a Edge Cloudflare.',
  ]) {
    if (data['message'] != null && data['message'].toString().trim().isNotEmpty) {
      return data['message'].toString();
    }
    final raw = data['error'];
    if (raw is Map && raw['message'] != null) return raw['message'].toString();
    return fallback;
  }

  Future<void> initializeFromStorage() async {
    themeMode = await localStorage.loadTheme();
    fontScale = await localStorage.loadFontScale();
    final gen = await localStorage.loadGeneralSettings();
    if (gen.isNotEmpty) {
      appLanguage = (gen['appLanguage'] as String?) ?? appLanguage;
      hapticLevel = (gen['hapticLevel'] as String?) ?? hapticLevel;
      reduceMotion = (gen['reduceMotion'] as bool?) ?? reduceMotion;
      muteInBackground = (gen['muteInBackground'] as bool?) ?? muteInBackground;
      externalMediaOnlyOfficial =
          (gen['externalMediaOnlyOfficial'] as bool?) ??
              externalMediaOnlyOfficial;
      p2pEnabled = (gen['p2pEnabled'] as bool?) ?? p2pEnabled;
      p2pWifiOnly = (gen['p2pWifiOnly'] as bool?) ?? p2pWifiOnly;
      p2pCacheQuota = (gen['p2pCacheQuota'] as String?) ?? p2pCacheQuota;
      dmPrivacy = (gen['dmPrivacy'] as String?) ?? dmPrivacy;
      showcasePrivacy = (gen['showcasePrivacy'] as String?) ?? showcasePrivacy;
      onlinePresenceVisible =
          (gen['onlinePresenceVisible'] as bool?) ?? onlinePresenceVisible;
      audioMixer = AudioMixerSettings(
        masterVolume: ((gen['masterVol'] as num?)?.toDouble() ?? 0.85).clamp(0.0, 1.0),
        ambienceVolume: ((gen['ambVol'] as num?)?.toDouble() ?? 0.65).clamp(0.0, 1.0),
        sfxVolume: ((gen['sfxVol'] as num?)?.toDouble() ?? 0.90).clamp(0.0, 1.0),
        voiceVolume: ((gen['voiceVol'] as num?)?.toDouble() ?? 1.00).clamp(0.0, 1.0),
      );
    }

    final session = await localStorage.loadSessionState();
    final fp = (session['deviceFingerprint'] as String?) ??
        'android-keystore-arcana-v1';
    edgeClient.deviceFingerprint = fp;
    isAuthenticated = (session['active'] as bool?) ?? false;
    trustDevice = (session['trusted'] as bool?) ?? true;
    edgeClient.bearerToken = session['bearerToken'] as String?;
    final onboardingDone = (session['onboardingCompleted'] as bool?) ?? false;

    currentUser = UserAccount(
      id: (session['userId'] as String?) ?? '',
      email: (session['email'] as String?) ?? '',
      username: (session['username'] as String?) ?? '',
      displayName: (session['displayName'] as String?) ?? 'Aventureiro',
      bio: (session['bio'] as String?) ?? '',
      avatarIcon: (session['avatarIcon'] as String?) ?? 'shield',
      role: UserRole.fromWire((session['role'] as String?) ?? 'jogador'),
      reputationPoints: 0,
      onboardingCompleted: onboardingDone,
      trustedDeviceEnabled: trustDevice,
      trustedDaysRemaining: (session['trustedDaysRemaining'] as int?) ?? 15,
      socialContacts: const {},
    );

    if (isAuthenticated && !onboardingDone) {
      loginViewState = OAuthSecurityState.sucessoAutenticado;
    }

    notifyListeners();

    if (isAuthenticated &&
        onboardingDone &&
        edgeClient.bearerToken != null &&
        edgeClient.bearerToken!.isNotEmpty) {
      await hydrateAllFromBackend();
    }
  }

  Future<void> _persistGeneralSettings() async {
    await localStorage.saveGeneralSettings({
      'appLanguage': appLanguage,
      'hapticLevel': hapticLevel,
      'reduceMotion': reduceMotion,
      'muteInBackground': muteInBackground,
      'externalMediaOnlyOfficial': externalMediaOnlyOfficial,
      'p2pEnabled': p2pEnabled,
      'p2pWifiOnly': p2pWifiOnly,
      'p2pCacheQuota': p2pCacheQuota,
      'dmPrivacy': dmPrivacy,
      'showcasePrivacy': showcasePrivacy,
      'onlinePresenceVisible': onlinePresenceVisible,
      'masterVol': audioMixer.masterVolume,
      'ambVol': audioMixer.ambienceVolume,
      'sfxVol': audioMixer.sfxVolume,
      'voiceVol': audioMixer.voiceVolume,
    });
  }

  void setAppLanguage(String lang) {
    appLanguage = lang;
    _persistGeneralSettings();
    notifyListeners();
  }

  void setHapticLevel(String level) {
    hapticLevel = level;
    _persistGeneralSettings();
    notifyListeners();
  }

  void setReduceMotion(bool value) {
    reduceMotion = value;
    _persistGeneralSettings();
    notifyListeners();
  }

  void setMuteInBackground(bool value) {
    muteInBackground = value;
    _persistGeneralSettings();
    notifyListeners();
  }

  void setExternalMediaOnlyOfficial(bool value) {
    externalMediaOnlyOfficial = value;
    _persistGeneralSettings();
    notifyListeners();
  }

  void setP2pEnabled(bool value) {
    p2pEnabled = value;
    _persistGeneralSettings();
    notifyListeners();
  }

  void setP2pWifiOnly(bool value) {
    p2pWifiOnly = value;
    _persistGeneralSettings();
    notifyListeners();
  }

  void setP2pCacheQuota(String quota) {
    p2pCacheQuota = quota;
    _persistGeneralSettings();
    notifyListeners();
  }

  void setDmPrivacy(String privacy) {
    dmPrivacy = privacy;
    _persistGeneralSettings();
    notifyListeners();
  }

  void setShowcasePrivacy(String privacy) {
    showcasePrivacy = privacy;
    _persistGeneralSettings();
    notifyListeners();
  }

  void setOnlinePresenceVisible(bool visible) {
    onlinePresenceVisible = visible;
    _persistGeneralSettings();
    notifyListeners();
  }

  void setSelectedBirthDate(DateTime date) {
    selectedBirthDate = date;
    notifyListeners();
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
    lastSyncError = null;
    notifyListeners();
  }

  void _applyBackendErrorState(String code, String message) {
    authErrorMessage = message;
    switch (code) {
      case 'AGE_RESTRICTED':
        loginViewState = OAuthSecurityState.erroMenorIdade;
        authErrorTitle = 'Restricao Etaria LGPD (< 16 anos)';
      case 'HARDWARE_BANNED':
        loginViewState = OAuthSecurityState.erroHardwareBan;
        authErrorTitle = 'Dispositivo Bloqueado (Hardware Ban)';
      case 'ACCOUNT_BANNED':
      case 'ACCOUNT_SUSPENDED':
        loginViewState = OAuthSecurityState.erroHardwareBan;
        authErrorTitle = code == 'ACCOUNT_SUSPENDED'
            ? 'Conta Temporariamente Suspensa'
            : 'Conta Banida por Violacao';
      case 'ACCOUNT_LOCKED':
        loginViewState = OAuthSecurityState.erroLockoutTotal;
        authErrorTitle = 'Conta em Lockout Total Preventivo';
      default:
        loginViewState = OAuthSecurityState.erroHardwareBan;
        authErrorTitle = 'Falha na Autenticacao';
    }
  }

  Future<bool> signInWithGoogleOAuth({
    DateTime? birthDate,
    bool forceAccountPicker = false,
    bool simulateHardwareBan = false,
    bool simulateLockout = false,
  }) async {
    if (birthDate != null) {
      selectedBirthDate = birthDate;
      final check = _oauthUseCase.evaluateAttempt(
        birthDate: birthDate,
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
    } else if (simulateHardwareBan || simulateLockout) {
      final check = _oauthUseCase.evaluateAttempt(
        birthDate: selectedBirthDate,
        isHardwareBanned: simulateHardwareBan,
        isAccountLocked: simulateLockout,
      );
      if (!check.success) {
        authErrorTitle = check.errorTitle;
        authErrorMessage = check.errorMessage;
        loginViewState = check.errorCode == 'HARDWARE_BANNED'
            ? OAuthSecurityState.erroHardwareBan
            : OAuthSecurityState.erroLockoutTotal;
        notifyListeners();
        return false;
      }
    }

    isSyncing = true;
    authErrorTitle = null;
    authErrorMessage = null;
    lastSyncError = null;
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
          scopes: const ['email', 'profile', 'openid'],
          serverClientId: LocalStorageDatasource.defaultGoogleServerClientId,
        );
        if (forceAccountPicker) {
          try {
            await googleSignIn.signOut();
          } catch (_) {}
        }
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
                account.displayName!.trim().isNotEmpty)
            ? account.displayName!.trim()
            : account.email.split('@').first;
        idToken = auth.idToken;
      }
    } catch (e) {
      isSyncing = false;
      loginViewState = OAuthSecurityState.erroHardwareBan;
      authErrorTitle = 'Falha no Google Sign-In Android';
      authErrorMessage =
          'Nao foi possivel conectar ao Google Play Services (${e.toString()}).';
      notifyListeners();
      return false;
    }

    final payload = <String, dynamic>{
      'action': 'oauth_google',
      'google_sub': googleSub ?? 'google_oauth_anonymous',
      'email': email ?? 'aventureiro@gmail.com',
      'display_name': displayName ?? 'Aventureiro',
      'device_fingerprint': edgeClient.deviceFingerprint,
      'trust_device': trustDevice,
    };
    if (birthDate != null) {
      payload['birth_date'] =
          '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}';
    }
    if (idToken != null && idToken.isNotEmpty) {
      payload['id_token'] = idToken;
    }

    final res = await edgeClient.postAuth(payload);

    if (!res.ok) {
      isSyncing = false;
      if (res.statusCode == 0) {
        loginViewState = OAuthSecurityState.erroHardwareBan;
        authErrorTitle = 'Servidor Indisponivel';
        authErrorMessage =
            'Nao foi possivel alcancar o servidor Edge Cloudflare (${edgeClient.baseUrl}).';
      } else {
        final code = _extractErrorCode(res.data, 'AUTH_ERROR');
        final msg = _extractErrorMessage(res.data, 'Falha ao autenticar conta Google.');
        _applyBackendErrorState(code, msg);
      }
      notifyListeners();
      return false;
    }

    final token = res.data['token'] as String?;
    final userJson = (res.data['user'] as Map<String, dynamic>?) ?? {};
    final profileJson = (res.data['profile'] as Map<String, dynamic>?) ?? {};

    var contacts = <String, String>{};
    try {
      final rawContacts = profileJson['contacts_json'] as String?;
      if (rawContacts != null && rawContacts.isNotEmpty) {
        final decoded = jsonDecode(rawContacts) as Map<String, dynamic>;
        contacts = decoded.map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (_) {}

    final onboardingDone = (profileJson['onboarding_completed'] as int? ?? 0) == 1 ||
        (res.data['requires_profile_setup'] == false);
    final trustedDays = (res.data['trusted_device_days'] as num?)?.toInt() ?? 15;

    currentUser = UserAccount(
      id: (userJson['id'] as String?) ?? 'usr_local',
      email: (userJson['email'] as String?) ?? (email ?? 'aventureiro@gmail.com'),
      username: (profileJson['username'] as String?) ?? '',
      displayName: (profileJson['display_name'] as String?) ??
          (displayName ?? 'Aventureiro'),
      bio: (profileJson['bio'] as String?) ?? '',
      avatarIcon: (profileJson['avatar_icon'] as String?) ?? 'shield',
      role: UserRole.fromWire((userJson['role'] as String?) ?? 'jogador'),
      reputationPoints: (profileJson['reputation_points'] as int?) ?? 0,
      onboardingCompleted: onboardingDone,
      trustedDeviceEnabled: trustDevice,
      trustedDaysRemaining: trustedDays,
      socialContacts: contacts,
    );

    loginViewState = onboardingDone
        ? OAuthSecurityState.sucessoAutenticado
        : OAuthSecurityState.sucessoAutenticado;
    isAuthenticated = onboardingDone;
    edgeClient.bearerToken = token;

    await localStorage.saveSessionState(
      active: onboardingDone,
      trustedDevice: trustDevice,
      userId: currentUser.id,
      email: currentUser.email,
      username: currentUser.username,
      displayName: currentUser.displayName,
      bio: currentUser.bio,
      avatarIcon: currentUser.avatarIcon,
      role: currentUser.role.wireKey,
      onboardingCompleted: onboardingDone,
      trustedDaysRemaining: trustedDays,
      bearerToken: token,
    );

    if (onboardingDone) {
      await hydrateAllFromBackend();
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
      'device_fingerprint': edgeClient.deviceFingerprint,
    });
    if (res.ok) {
      resetLoginState();
      return true;
    }
    authErrorMessage = _extractErrorMessage(res.data, 'Codigo de recuperacao invalido.');
    notifyListeners();
    return false;
  }

  Future<bool> completeLoginTransitionToHub({
    String? username,
    String? newUsername,
    String? displayName,
    String? newDisplayName,
    String bio = '',
    DateTime? birthDate,
    String avatarIcon = 'shield',
    Map<String, String>? contacts,
  }) async {
    final resolvedUsername = (username ?? newUsername ?? currentUser.username).trim();
    final resolvedDisplay = (displayName ?? newDisplayName ?? currentUser.displayName).trim();
    final effectiveBirth = birthDate ?? selectedBirthDate;
    selectedBirthDate = effectiveBirth;
    final ageCheck = _oauthUseCase.evaluateAttempt(
      birthDate: effectiveBirth,
      isHardwareBanned: false,
      isAccountLocked: false,
    );
    if (!ageCheck.success) {
      isAuthenticated = false;
      edgeClient.bearerToken = null;
      await localStorage.clearSession();
      loginViewState = OAuthSecurityState.erroMenorIdade;
      authErrorTitle = ageCheck.errorTitle;
      authErrorMessage = ageCheck.errorMessage;
      notifyListeners();
      return false;
    }

    isSyncing = true;
    lastSyncError = null;
    notifyListeners();

    final ok = await updateProfile(
      username: resolvedUsername,
      displayName: resolvedDisplay,
      bio: bio,
      birthDate: effectiveBirth,
      avatarIcon: avatarIcon,
      contacts: contacts,
    );

    if (!ok) {
      isSyncing = false;
      if ((lastSyncError ?? '').toLowerCase().contains('16 anos')) {
        isAuthenticated = false;
        loginViewState = OAuthSecurityState.erroMenorIdade;
        authErrorTitle = 'Restricao Etaria LGPD (< 16 anos)';
        authErrorMessage = lastSyncError;
      }
      notifyListeners();
      return false;
    }

    isAuthenticated = true;
    loginViewState = OAuthSecurityState.padrao;
    await hydrateAllFromBackend();
    isSyncing = false;
    notifyListeners();
    return true;
  }

  Future<void> logout({bool revokeGlobal = false}) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      await edgeClient.postAuth({
        'action': 'logout',
        'scope': revokeGlobal ? 'global' : 'single',
      });
    }
    try {
      if (googleSignInProvider == null) {
        await GoogleSignIn().signOut();
      }
    } catch (_) {}
    edgeClient.bearerToken = null;
    isAuthenticated = false;
    ghostSpectatorActive = false;
    loginViewState = OAuthSecurityState.padrao;
    campaigns = [];
    characters = [];
    systems = [];
    favoriteSystemIds = [];
    compendiumItems = [];
    guilds = [];
    forumTopics = [];
    chatMessages = [];
    friends = [];
    notifications = [];
    reports = [];
    adminUsers = [];
    bannedDevices = [];
    systemCreationKeys = [];
    gmBannedPlayers = [];
    campaignScenesMap = {};
    campaignCharactersMap = {};
    dmThreads = {};
    currentTabIndex = 0;
    await localStorage.clearSession();
    notifyListeners();
  }

  Future<void> triggerTotalLockout() async {
    if (currentUser.id.isNotEmpty) {
      await edgeClient.postAuth({
        'action': 'lockout_trigger',
        'user_id': currentUser.id,
        'reason': 'Botao Panico Lockout Total acionado pelo usuario',
      });
    }
    edgeClient.bearerToken = null;
    isAuthenticated = false;
    ghostSpectatorActive = false;
    loginViewState = OAuthSecurityState.erroLockoutTotal;
    authErrorTitle = 'Conta em Lockout Total Preventivo';
    authErrorMessage =
        'Todas as sessoes foram encerradas. Verifique seu e-mail Google para obter o codigo de desbloqueio de 6 digitos.';
    await localStorage.clearSession();
    notifyListeners();
  }

  Future<void> hydrateAllFromBackend({String? channelId}) async {
    if (edgeClient.bearerToken == null || edgeClient.bearerToken!.isEmpty) {
      return;
    }
    isSyncing = true;
    lastSyncError = null;
    if (channelId != null) {
      activeCommunityChannelId = channelId;
    }
    notifyListeners();

    try {
      final sysRes = await edgeClient.postSync({'action': 'systems.list', 'segment': 'todos'});
      if (sysRes.ok) {
        final rawFav = (sysRes.data['favorite_ids'] as List<dynamic>?) ?? [];
        favoriteSystemIds = rawFav.map((e) => e.toString()).toList();
        final rawSystems = (sysRes.data['systems'] as List<dynamic>?) ?? [];
        systems = rawSystems
            .whereType<Map<String, dynamic>>()
            .map(_mapSystem)
            .toList();
      } else if (sysRes.statusCode == 403 &&
          _extractErrorCode(sysRes.data) == 'PROFILE_INCOMPLETE') {
        isAuthenticated = false;
        loginViewState = OAuthSecurityState.sucessoAutenticado;
        isSyncing = false;
        notifyListeners();
        return;
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
            .map((c) => _mapCampaign(c, memberByCmp[c['id'] as String?]))
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
      compendiumItems = allComp;

      final commRes = await edgeClient.postSync({
        'action': 'communities.overview',
        'channel_id': activeCommunityChannelId,
      });
      if (commRes.ok) {
        final rawAnn = (commRes.data['announcements'] as List<dynamic>?) ?? [];
        if (rawAnn.isNotEmpty) {
          news = rawAnn.whereType<Map<String, dynamic>>().map((a) {
            return NewsItem(
              id: (a['id'] as String?) ?? 'ann',
              tag: (a['tag'] as String?) ?? 'OFICIAL',
              title: (a['title'] as String?) ?? '',
              summary: (a['summary'] as String?) ?? '',
            );
          }).toList();
        }
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

        final rawNotifs = (socialRes.data['notifications'] as List<dynamic>?) ?? [];
        notifications = rawNotifs
            .whereType<Map<String, dynamic>>()
            .map(_mapNotification)
            .toList();

        final rawChars = (socialRes.data['characters'] as List<dynamic>?) ?? [];
        characters = rawChars
            .whereType<Map<String, dynamic>>()
            .map(_mapCharacter)
            .toList();
      }

      if (RbacGuard.canAccessAdminPanel(currentUser.role)) {
        final adminRes = await edgeClient.postSync({'action': 'admin.overview'});
        if (adminRes.ok) {
          final rawReports = (adminRes.data['reports'] as List<dynamic>?) ?? [];
          reports = rawReports
              .whereType<Map<String, dynamic>>()
              .map(_mapReport)
              .toList();

          final rawUsers = (adminRes.data['users'] as List<dynamic>?) ?? [];
          adminUsers = rawUsers
              .whereType<Map<String, dynamic>>()
              .map(_mapAdminUser)
              .toList();

          final rawBanned = (adminRes.data['banned_devices'] as List<dynamic>?) ?? [];
          bannedDevices = rawBanned
              .whereType<Map<String, dynamic>>()
              .map((d) => BannedDeviceSummary(
                    deviceFingerprint: (d['device_fingerprint'] as String?) ?? '',
                    userId: d['user_id'] as String?,
                    banReason: (d['ban_reason'] as String?) ?? 'Violacao',
                    updatedAt: (d['updated_at'] as String?) ?? '',
                  ))
              .toList();
          hardwareBannedFingerprints =
              bannedDevices.map((d) => d.deviceFingerprint).toList();

          final rawKeys = (adminRes.data['creation_keys'] as List<dynamic>?) ?? [];
          systemCreationKeys = rawKeys
              .whereType<Map<String, dynamic>>()
              .map((k) => SystemCreationKey(
                    code: (k['code'] as String?) ?? '',
                    createdBy: (k['created_by'] as String?) ?? '',
                    assignedToUserId: k['assigned_to_user_id'] as String?,
                    usedByUserId: k['used_by_user_id'] as String?,
                    isUsed: ((k['is_used'] as num?)?.toInt() ?? 0) == 1,
                    createdAt: (k['created_at'] as String?) ?? '',
                  ))
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

  void setTabIndex(int index) {
    currentTabIndex = index;
    notifyListeners();
  }

  void toggleGhostSpectator() {
    if (!RbacGuard.canAccessAdminPanel(currentUser.role)) return;
    ghostSpectatorActive = !ghostSpectatorActive;
    notifyListeners();
  }

  void switchActiveRoleForPreview(UserRole role) {
    currentUser = currentUser.copyWith(role: role);
    notifyListeners();
  }

  Future<void> setThemeMode(ArcanaThemeMode mode) async {
    themeMode = mode;
    await localStorage.saveTheme(mode);
    notifyListeners();
    if (isAuthenticated && currentUser.username.isNotEmpty) {
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
    DateTime? birthDate,
    String? avatarIcon,
    Map<String, String>? contacts,
  }) async {
    var cleanUsername = username
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (cleanUsername.length < 3) {
      cleanUsername = '${cleanUsername}_rpg'.padRight(3, '0');
    }
    if (cleanUsername.length > 24) {
      cleanUsername = cleanUsername.substring(0, 24);
    }

    final nextDisplay =
        displayName.trim().isNotEmpty ? displayName.trim() : currentUser.displayName;
    final nextBio =
        bio.trim().length > 500 ? bio.trim().substring(0, 500) : bio.trim();
    final nextAvatar = avatarIcon ?? currentUser.avatarIcon;

    if (birthDate != null) {
      selectedBirthDate = birthDate;
    }

    Map<String, String>? sanitizedContacts;
    if (contacts != null) {
      sanitizedContacts = {};
      for (final key in [
        'discord',
        'twitch',
        'youtube',
        'steam',
        'instagram',
        'x_twitter',
        'reddit',
        'whatsapp',
      ]) {
        final v = contacts[key]?.trim() ?? '';
        if (v.isNotEmpty) sanitizedContacts[key] = v;
      }
    }

    final formattedBirth = birthDate != null
        ? '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}'
        : null;

    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'profile.setup',
        'username': cleanUsername,
        'display_name': nextDisplay,
        'birth_date': ?formattedBirth,
        'bio': nextBio,
        'avatar_icon': nextAvatar,
        'contacts': ?sanitizedContacts,
        'theme_preference': themeMode.wireKey,
        'font_scale': fontScale,
      });

      if (!res.ok) {
        lastSyncError = _extractErrorMessage(res.data, 'Falha ao atualizar perfil.');
        notifyListeners();
        return false;
      }
      final updatedRoleStr = res.data['role'] as String?;
      currentUser = currentUser.copyWith(
        username: cleanUsername,
        displayName: nextDisplay,
        bio: nextBio,
        avatarIcon: nextAvatar,
        onboardingCompleted: true,
        role: updatedRoleStr != null
            ? UserRole.fromWire(updatedRoleStr)
            : currentUser.role,
        socialContacts: sanitizedContacts ?? currentUser.socialContacts,
      );
    } else {
      currentUser = currentUser.copyWith(
        username: cleanUsername,
        displayName: nextDisplay,
        bio: nextBio,
        avatarIcon: nextAvatar,
        onboardingCompleted: true,
        socialContacts: sanitizedContacts ?? currentUser.socialContacts,
      );
    }

    await localStorage.saveSessionState(
      active: true,
      trustedDevice: trustDevice,
      userId: currentUser.id,
      email: currentUser.email,
      username: currentUser.username,
      displayName: currentUser.displayName,
      bio: currentUser.bio,
      avatarIcon: currentUser.avatarIcon,
      role: currentUser.role.wireKey,
      onboardingCompleted: true,
      trustedDaysRemaining: currentUser.trustedDaysRemaining,
      bearerToken: edgeClient.bearerToken,
    );
    notifyListeners();
    return true;
  }

  Future<void> _syncCurrentProfile() async {
    await edgeClient.postSync({
      'action': 'profile.setup',
      'username': currentUser.username.isEmpty ? 'aventureiro' : currentUser.username,
      'display_name': currentUser.displayName,
      'bio': currentUser.bio,
      'avatar_icon': currentUser.avatarIcon,
      'theme_preference': themeMode.wireKey,
      'font_scale': fontScale,
    });
  }

  void updateAudioMixer(AudioMixerSettings settings) {
    audioMixer = settings;
    _persistGeneralSettings();
    notifyListeners();
  }

  void clearP2pCache() {
    p2pCacheMb = 0;
    notifyListeners();
  }

  // ==================== MOTOR UNIVERSAL & DADOS ====================

  Future<DiceRoll3d6?> rollUniversal(
    String expression, {
    String? label,
    int? difficulty,
    String? opposedExpression,
  }) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'rpg.roll_universal',
        'expression': expression.trim(),
        'label': ?label,
        'difficulty': ?difficulty,
        'opposed_expression': ?opposedExpression,
      });
      if (res.ok && res.data['roll'] is Map<String, dynamic>) {
        final r = res.data['roll'] as Map<String, dynamic>;
        final resolution = res.data['resolution'] as Map<String, dynamic>?;
        final mapped = DiceRoll3d6(
          label: (r['label'] as String?) ?? (label ?? 'ROLAGEM UNIVERSAL'),
          dice: (r['dice'] as List<dynamic>? ?? const [])
              .map((e) => int.tryParse(e.toString()) ?? 1)
              .toList(),
          successes: (r['successes'] as num?)?.toInt() ?? 0,
          outcome: resolution != null
              ? '${r['outcome']} | ${resolution['summary']}'
              : (r['outcome'] as String?) ?? '',
          expression: (r['expression'] as String?) ?? expression,
          total: (r['total'] as num?)?.toInt() ?? 0,
          engine: (r['engine'] as String?) ?? 'formula',
          keptDice: (r['kept_dice'] as List<dynamic>? ?? const [])
              .map((e) => int.tryParse(e.toString()) ?? 1)
              .toList(),
        );
        lastHeroRoll = mapped;
        notifyListeners();
        return mapped;
      }
    }

    try {
      final localRoll = _universalEngine.executeRoll(
        expression,
        label: label,
        difficulty: difficulty,
      );
      var outcome = localRoll.outcome;
      if (opposedExpression != null && opposedExpression.trim().isNotEmpty) {
        final rB = _universalEngine.executeRoll(opposedExpression, label: 'OPONENTE');
        final cmp = UniversalRpgEngineUseCase.resolveOpposed(localRoll, rB);
        outcome = '${localRoll.outcome} vs [${rB.dice.join(',')}] -> ${cmp['summary']}';
      }
      final mapped = DiceRoll3d6(
        label: localRoll.label,
        dice: localRoll.dice,
        successes: localRoll.successes,
        outcome: outcome,
        expression: localRoll.expression,
        total: localRoll.total,
        engine: localRoll.engine,
        keptDice: localRoll.keptDice ?? const [],
      );
      lastHeroRoll = mapped;
      notifyListeners();
      return mapped;
    } catch (_) {
      return null;
    }
  }

  DiceRoll3d6 rollHeroAttributeTest(String attributeName, {String? formula}) {
    if (formula != null && formula.trim().isNotEmpty) {
      final res = _universalEngine.executeRoll(
        formula,
        label: 'TESTE DE ${attributeName.toUpperCase()}',
      );
      final mapped = DiceRoll3d6(
        label: res.label,
        dice: res.dice,
        successes: res.successes,
        outcome: res.outcome,
        expression: res.expression,
        total: res.total,
        engine: res.engine,
      );
      lastHeroRoll = mapped;
      notifyListeners();
      return mapped;
    }
    final result = _roll3d6.execute(label: 'TESTE DE $attributeName (3D6)');
    lastHeroRoll = result;
    notifyListeners();
    return result;
  }

  // ==================== CAMPANHAS, CONVITES, BANIMENTO & CENAS ====================

  Future<CampaignLookupResult?> lookupCampaignByCode(String rawCode) async {
    final normalized = rawCode.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (normalized.length < 4) return null;

    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'campaigns.lookup_code',
        'code': normalized,
      });
      if (!res.ok) {
        lastSyncError = _extractErrorMessage(res.data, 'Codigo nao localizado.');
        notifyListeners();
        return null;
      }
      final raw = res.data['campaign'] as Map<String, dynamic>?;
      if (raw != null) {
        final membership = res.data['membership'] as Map<String, dynamic>?;
        final isMember = (res.data['is_member'] as bool?) ?? false;
        final status = (membership?['status'] as String?) ?? 'none';
        final mapped = _mapCampaign(raw, membership);
        if (!campaigns.any((c) => c.id == mapped.id)) {
          campaigns = [mapped, ...campaigns];
        } else {
          campaigns = campaigns.map((c) => c.id == mapped.id ? mapped : c).toList();
        }
        notifyListeners();
        return CampaignLookupResult(
          campaign: mapped,
          isMember: isMember,
          membershipStatus: status,
        );
      }
    }

    for (final c in campaigns) {
      if (c.quickJoinCode.toUpperCase() == normalized) {
        final member = c.userRelation != CampaignSegment.explorar;
        return CampaignLookupResult(
          campaign: c,
          isMember: member,
          membershipStatus: member ? 'active' : 'none',
        );
      }
    }
    return null;
  }

  Future<Campaign?> quickJoinByCode(String rawCode) async {
    final lookup = await lookupCampaignByCode(rawCode);
    return lookup?.campaign;
  }

  Future<List<CampaignMemberSummary>> fetchCampaignMembers(String campaignId) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'campaigns.list_members',
        'campaign_id': campaignId,
      });
      if (res.ok) {
        final raw = (res.data['members'] as List<dynamic>?) ?? [];
        return raw.whereType<Map<String, dynamic>>().map(_mapCampaignMember).toList();
      }
    }
    return const [];
  }

  Future<List<CampaignMemberSummary>?> manageCampaignMember({
    required String campaignId,
    required String targetUserId,
    String? status,
    String? tableRole,
    String? banReason,
  }) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'campaigns.manage_member',
        'campaign_id': campaignId,
        'target_user_id': targetUserId,
        'status': ?status,
        'table_role': ?tableRole,
        if (banReason != null && banReason.trim().isNotEmpty)
          'ban_reason': banReason.trim(),
      });
      if (!res.ok) {
        lastSyncError = _extractErrorMessage(res.data, 'Nao foi possivel atualizar membro.');
        notifyListeners();
        return null;
      }
      final raw = (res.data['members'] as List<dynamic>?) ?? [];
      final members = raw.whereType<Map<String, dynamic>>().map(_mapCampaignMember).toList();
      final activeCount = members.where((m) => m.status == 'active').length;
      campaigns = campaigns.map((c) {
        if (c.id != campaignId) return c;
        return Campaign(
          id: c.id,
          ownerId: c.ownerId,
          title: c.title,
          synopsis: c.synopsis,
          masterHandle: c.masterHandle,
          systemId: c.systemId,
          systemName: c.systemName,
          quickJoinCode: c.quickJoinCode,
          mode: c.mode,
          scheduleText: c.scheduleText,
          maxSlots: c.maxSlots,
          occupiedSlots: activeCount > 0 ? activeCount : c.occupiedSlots,
          userRelation: c.userRelation,
          chapterTitle: c.chapterTitle,
          isPublic: c.isPublic,
          iconName: c.iconName,
          bannerPreset: c.bannerPreset,
          ageRating: c.ageRating,
          tags: c.tags,
          sessionsCount: c.sessionsCount,
          noticeBoard: c.noticeBoard,
          autoApproveActions: c.autoApproveActions,
          sceneAccessMode: c.sceneAccessMode,
          xpMultiplier: c.xpMultiplier,
          discordVoiceUrl: c.discordVoiceUrl,
          discordWebhookUrl: c.discordWebhookUrl,
          isInactiveArchived: c.isInactiveArchived,
          channels: c.channels,
          worldClock: c.worldClock,
          factions: c.factions,
          worldMaps: c.worldMaps,
          diaryEntries: c.diaryEntries,
        );
      }).toList();
      notifyListeners();
      return members;
    }
    return null;
  }

  Future<bool> invitePlayerToCampaign(String campaignId, String targetUserId) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'campaigns.invite_player',
        'campaign_id': campaignId,
        'target_user_id': targetUserId,
      });
      if (!res.ok) {
        lastSyncError = _extractErrorMessage(res.data, 'Nao foi possivel enviar convite.');
        notifyListeners();
        return false;
      }
      return true;
    }
    return true;
  }

  Future<bool> acceptCampaignInvite(String inviteId, {bool accept = true}) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'campaigns.accept_invite',
        'invite_id': inviteId,
        'accept': accept,
      });
      if (!res.ok) {
        lastSyncError = _extractErrorMessage(res.data, 'Convite invalido.');
        notifyListeners();
        return false;
      }
      await hydrateAllFromBackend();
      return true;
    }
    return true;
  }

  Future<bool> leaveCampaign(String campaignId) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'campaigns.leave',
        'campaign_id': campaignId,
      });
      if (!res.ok) {
        lastSyncError = _extractErrorMessage(res.data, 'Erro ao sair da campanha.');
        notifyListeners();
        return false;
      }
    }
    campaigns = campaigns.map((c) {
      if (c.id != campaignId) return c;
      return Campaign(
        id: c.id,
        ownerId: c.ownerId,
        title: c.title,
        synopsis: c.synopsis,
        masterHandle: c.masterHandle,
        systemId: c.systemId,
        systemName: c.systemName,
        quickJoinCode: c.quickJoinCode,
        mode: c.mode,
        scheduleText: c.scheduleText,
        maxSlots: c.maxSlots,
        occupiedSlots: (c.occupiedSlots - 1).clamp(0, c.maxSlots),
        userRelation: CampaignSegment.explorar,
        chapterTitle: c.chapterTitle,
        isPublic: c.isPublic,
        iconName: c.iconName,
        bannerPreset: c.bannerPreset,
        ageRating: c.ageRating,
        tags: c.tags,
      );
    }).toList();
    characters = characters.where((ch) => ch.campaignId != campaignId).toList();
    notifyListeners();
    return true;
  }

  Future<void> fetchGmBannedPlayers() async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({'action': 'campaigns.list_banned'});
      if (res.ok) {
        final raw = (res.data['bans'] as List<dynamic>?) ?? [];
        gmBannedPlayers = raw
            .whereType<Map<String, dynamic>>()
            .map((b) => {
                  'player_id': (b['player_id'] as String?) ?? '',
                  'ban_reason': (b['ban_reason'] as String?) ?? '',
                  'created_at': (b['created_at'] as String?) ?? '',
                })
            .toList();
        notifyListeners();
      }
    }
  }

  Future<void> unbanGmPlayer(String playerId) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      await edgeClient.postSync({
        'action': 'campaigns.unban_player',
        'player_id': playerId,
      });
    }
    gmBannedPlayers = gmBannedPlayers.where((b) => b['player_id'] != playerId).toList();
    notifyListeners();
  }

  Future<Campaign?> createCampaign({
    required String title,
    required String synopsis,
    required String systemId,
    required CampaignMode mode,
    required String scheduleText,
    required int maxSlots,
    required bool isPublic,
    String iconName = 'swords',
    String bannerPreset = 'cidadela_obsidiana',
    String ageRating = '16+',
    List<String> tags = const [],
  }) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'campaigns.create',
        'title': title.trim(),
        'synopsis': synopsis.trim(),
        'system_id': systemId,
        'mode': _campaignModeToWire(mode),
        'schedule_text': scheduleText.trim().isEmpty ? 'Tempo Livre' : scheduleText.trim(),
        'max_slots': maxSlots.clamp(1, 12),
        'visibility': isPublic ? 'publica' : 'privada',
        'icon_name': iconName,
        'banner_preset': bannerPreset,
        'age_rating': ageRating,
        'tags': tags,
      });
      if (!res.ok) {
        lastSyncError = _extractErrorMessage(res.data, 'Erro ao criar campanha.');
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

    final system = systems.cast<RpgSystem?>().firstWhere(
          (s) => s?.id == systemId,
          orElse: () => null,
        );
    final codeNum = (DateTime.now().millisecondsSinceEpoch % 899) + 100;
    final newCampaign = Campaign(
      id: _nextLocalId('cmp'),
      ownerId: currentUser.id,
      title: title.trim(),
      synopsis: synopsis.trim(),
      masterHandle: '@${currentUser.username}',
      systemId: system?.id ?? 'sys_universal',
      systemName: system?.name ?? 'Motor Universal',
      quickJoinCode: 'ARC$codeNum',
      mode: mode,
      scheduleText: scheduleText.trim().isEmpty ? 'Tempo Livre' : scheduleText.trim(),
      maxSlots: maxSlots.clamp(1, 12),
      occupiedSlots: 1,
      userRelation: CampaignSegment.mestre,
      chapterTitle: 'Sessao 0 - Preparacao da Mesa',
      isPublic: isPublic,
      iconName: iconName,
      bannerPreset: bannerPreset,
      ageRating: ageRating,
      tags: tags,
    );
    campaigns = [newCampaign, ...campaigns];
    notifyListeners();
    return newCampaign;
  }

  Future<bool> updateCampaignSettings({
    required String campaignId,
    String? title,
    String? synopsis,
    bool? isPublic,
    CampaignMode? mode,
    String? scheduleText,
    Map<String, dynamic>? statePatch,
    bool reactivate75d = false,
  }) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'campaigns.update_settings',
        'campaign_id': campaignId,
        'title': ?title,
        'synopsis': ?synopsis,
        if (isPublic != null) 'visibility': isPublic ? 'publica' : 'privada',
        if (mode != null) 'mode': _campaignModeToWire(mode),
        'schedule_text': ?scheduleText,
        'state_patch': ?statePatch,
        if (reactivate75d) 'reactivate_75d': true,
      });
      if (!res.ok) {
        lastSyncError = _extractErrorMessage(res.data, 'Erro ao atualizar campanha.');
        notifyListeners();
        return false;
      }
      final raw = res.data['campaign'] as Map<String, dynamic>?;
      if (raw != null) {
        final idx = campaigns.indexWhere((c) => c.id == campaignId);
        final prevRel = idx >= 0 ? campaigns[idx].userRelation : CampaignSegment.mestre;
        final mapped = _mapCampaign(raw, {
          'table_role': prevRel == CampaignSegment.mestre
              ? 'mestre'
              : prevRel == CampaignSegment.auxiliar
                  ? 'assistente_mestre'
                  : 'jogador',
          'status': 'active',
        });
        campaigns = campaigns.map((c) => c.id == campaignId ? mapped : c).toList();
        notifyListeners();
        return true;
      }
    }

    campaigns = campaigns.map((c) {
      if (c.id != campaignId) return c;
      final patchClock = statePatch?['world_clock'] as Map<String, dynamic>?;
      final patchFactions = statePatch?['factions'] as List<dynamic>?;
      final patchDiary = statePatch?['diary_entries'] as List<dynamic>?;
      final patchMaps = statePatch?['world_maps'] as List<dynamic>?;
      final patchChannels = statePatch?['channels'] as List<dynamic>?;
      return Campaign(
        id: c.id,
        ownerId: c.ownerId,
        title: title ?? c.title,
        synopsis: synopsis ?? c.synopsis,
        masterHandle: c.masterHandle,
        systemId: c.systemId,
        systemName: c.systemName,
        quickJoinCode: c.quickJoinCode,
        mode: mode ?? c.mode,
        scheduleText: scheduleText ?? c.scheduleText,
        maxSlots: c.maxSlots,
        occupiedSlots: c.occupiedSlots,
        userRelation: c.userRelation,
        chapterTitle: (statePatch?['chapter'] as String?) ?? c.chapterTitle,
        isPublic: isPublic ?? c.isPublic,
        iconName: c.iconName,
        bannerPreset: c.bannerPreset,
        ageRating: c.ageRating,
        tags: c.tags,
        sessionsCount: (statePatch?['sessions_count'] as int?) ?? c.sessionsCount,
        noticeBoard: (statePatch?['notice_board'] as String?) ?? c.noticeBoard,
        autoApproveActions:
            (statePatch?['auto_approve_actions'] as bool?) ?? c.autoApproveActions,
        sceneAccessMode:
            (statePatch?['scene_access_mode'] as String?) ?? c.sceneAccessMode,
        xpMultiplier:
            (statePatch?['xp_multiplier'] as num?)?.toDouble() ?? c.xpMultiplier,
        discordVoiceUrl:
            (statePatch?['discord_voice_url'] as String?) ?? c.discordVoiceUrl,
        discordWebhookUrl:
            (statePatch?['discord_webhook_url'] as String?) ?? c.discordWebhookUrl,
        isInactiveArchived: reactivate75d ? false : c.isInactiveArchived,
        channels: patchChannels != null
            ? patchChannels.map((e) => e.toString()).take(3).toList()
            : c.channels,
        worldClock:
            patchClock != null ? WorldClockState.fromJson(patchClock) : c.worldClock,
        factions: patchFactions != null
            ? patchFactions
                .whereType<Map<String, dynamic>>()
                .map(FactionEntry.fromJson)
                .toList()
            : c.factions,
        worldMaps: patchMaps != null
            ? patchMaps
                .whereType<Map<String, dynamic>>()
                .map(WorldMapEntry.fromJson)
                .toList()
            : c.worldMaps,
        diaryEntries: patchDiary != null
            ? patchDiary
                .whereType<Map<String, dynamic>>()
                .map(DiaryEntry.fromJson)
                .toList()
            : c.diaryEntries,
      );
    }).toList();
    notifyListeners();
    return true;
  }

  Future<List<HeroCharacter>> fetchCampaignCharacters(String campaignId) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'campaigns.list_characters',
        'campaign_id': campaignId,
      });
      if (res.ok) {
        final raw = (res.data['characters'] as List<dynamic>?) ?? [];
        final list = raw.whereType<Map<String, dynamic>>().map(_mapCharacter).toList();
        campaignCharactersMap[campaignId] = list;
        notifyListeners();
        return list;
      }
    }
    return characters.where((c) => c.campaignId == campaignId).toList();
  }

  Future<List<CampaignScene>> fetchCampaignScenes(String campaignId) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'scenes.list',
        'campaign_id': campaignId,
      });
      if (res.ok) {
        final raw = (res.data['scenes'] as List<dynamic>?) ?? [];
        final mapped = raw.whereType<Map<String, dynamic>>().map(_mapScene).toList();
        campaignScenesMap[campaignId] = mapped;
        notifyListeners();
        return mapped;
      }
    }
    return campaignScenesMap[campaignId] ?? const [];
  }

  Future<CampaignScene?> upsertCampaignScene({
    String? id,
    required String campaignId,
    required String name,
    required String description,
    required SceneModelType modelType,
    bool isActive = false,
    int maxPlayers = 12,
    Map<String, dynamic> modelData = const {},
    List<Map<String, dynamic>> rulesData = const [],
    Map<String, dynamic> stateData = const {},
  }) async {
    final current = campaignScenesMap[campaignId] ?? [];
    final isUpdate = id != null && current.any((s) => s.id == id);
    if (!isUpdate && current.length >= 18) {
      lastSyncError = 'Limite maximo rigido de 18 cenas por campanha atingido.';
      notifyListeners();
      return null;
    }

    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'scenes.upsert',
        'id': ?id,
        'campaign_id': campaignId,
        'name': name.trim(),
        'description': description.trim(),
        'model_type': modelType.wireKey,
        'is_active': isActive,
        'max_players': maxPlayers.clamp(1, 12),
        'model_data': modelData,
        'rules_data': rulesData,
        'state_data': stateData,
      });
      if (!res.ok) {
        lastSyncError = _extractErrorMessage(res.data, 'Falha ao salvar cena.');
        notifyListeners();
        return null;
      }
      final raw = res.data['scene'] as Map<String, dynamic>?;
      if (raw != null) {
        final scene = _mapScene(raw);
        final next = [...current.where((s) => s.id != scene.id), scene];
        campaignScenesMap[campaignId] = next;
        notifyListeners();
        return scene;
      }
    }

    final localScene = CampaignScene(
      id: id ?? _nextLocalId('scn'),
      campaignId: campaignId,
      name: name.trim(),
      description: description.trim(),
      modelType: modelType,
      isActive: isActive,
      maxPlayers: maxPlayers.clamp(1, 12),
      modelData: modelData,
      rulesData: rulesData,
      stateData: stateData,
    );
    campaignScenesMap[campaignId] = [
      ...current.where((s) => s.id != localScene.id),
      localScene,
    ];
    notifyListeners();
    return localScene;
  }

  Future<void> deleteCampaignScene(String campaignId, String sceneId) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      await edgeClient.postSync({
        'action': 'scenes.delete',
        'campaign_id': campaignId,
        'scene_id': sceneId,
      });
    }
    final list = campaignScenesMap[campaignId] ?? [];
    campaignScenesMap[campaignId] = list.where((s) => s.id != sceneId).toList();
    notifyListeners();
  }

  Future<Map<String, dynamic>?> triggerSceneAction({
    required String campaignId,
    required String sceneId,
    required String triggerType,
    Map<String, dynamic> params = const {},
  }) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'scenes.trigger',
        'campaign_id': campaignId,
        'scene_id': sceneId,
        'trigger_type': triggerType,
        'params': params,
      });
      if (res.ok) {
        await fetchCampaignCharacters(campaignId);
        return res.data;
      }
    }
    return {
      'ok': true,
      'toasts': ['Gatilho $triggerType processado localmente.'],
      'logs': <String>[],
    };
  }

  Future<bool> applyToCampaign({
    required String campaignId,
    required String pitch,
  }) async {
    final cleanPitch = pitch.trim();
    if (cleanPitch.length < 5) return false;
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'campaigns.apply',
        'campaign_id': campaignId,
        'pitch': cleanPitch.length > 200 ? cleanPitch.substring(0, 200) : cleanPitch,
      });
      if (!res.ok) {
        lastSyncError = _extractErrorMessage(res.data, 'Erro ao enviar candidatura.');
        notifyListeners();
        return false;
      }
    }
    return true;
  }

  Future<bool> saveHeroCharacter({
    required String campaignId,
    required String name,
    required String heroClass,
    required int level,
    required int corpo,
    required int mente,
    required int espirito,
    required int hpCurrent,
    required int hpMax,
    required int animaCurrent,
    required int animaMax,
    required int exhaustion,
    required List<String> slots,
    String systemId = 'sys_universal',
    Map<String, int>? attributesMap,
    Map<String, int>? resourcesMap,
    Map<String, String>? equippedSlotsMap,
    List<String>? specializations,
    int? silverCoins,
    String? wealthTier,
    List<String>? powers,
    List<String>? contacts,
    String? lore,
    int? xpCurrent,
  }) async {
    final cleanCampaignId = campaignId.trim();
    if (cleanCampaignId.isEmpty) {
      lastSyncError =
          'Personagens so podem ser criados dentro de uma campanha ativa.';
      notifyListeners();
      return false;
    }

    final existing = characterForCampaign(cleanCampaignId);
    final customData = <String, dynamic>{
      'attributes': ?attributesMap,
      'resources': ?resourcesMap,
      'equipped_slots': ?equippedSlotsMap,
      'specializations': ?specializations,
      'silver_coins': ?silverCoins,
      'wealth_tier': ?wealthTier,
      'powers': ?powers,
      'contacts': ?contacts,
      'lore': ?lore,
      'xp_current': ?xpCurrent,
    };

    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'characters.upsert',
        if (existing?.id != null) 'id': existing!.id,
        'campaign_id': cleanCampaignId,
        'name': name.trim(),
        'title': heroClass.trim(),
        'system_id': systemId,
        'level': level,
        'corpo': corpo,
        'mente': mente,
        'espirito': espirito,
        'hp_current': hpCurrent,
        'hp_max': hpMax,
        'anima_current': animaCurrent,
        'anima_max': animaMax,
        'exhaustion': exhaustion,
        'slots': slots.take(24).toList(),
        if (customData.isNotEmpty) 'custom_data': customData,
      });

      if (!res.ok) {
        lastSyncError = _extractErrorMessage(res.data, 'Nao foi possivel salvar a ficha.');
        notifyListeners();
        return false;
      }
      final rawChar = res.data['character'] as Map<String, dynamic>?;
      if (rawChar != null) {
        final mapped = _mapCharacter(rawChar);
        characters = [
          mapped,
          ...characters.where((c) => c.campaignId != cleanCampaignId),
        ];
        notifyListeners();
        return true;
      }
    }

    final cmp = campaigns.cast<Campaign?>().firstWhere(
          (c) => c?.id == cleanCampaignId,
          orElse: () => null,
        );
    final saved = HeroCharacter(
      id: existing?.id ?? 'chr_${DateTime.now().millisecondsSinceEpoch}',
      campaignId: cleanCampaignId,
      name: name.trim(),
      heroClass: heroClass.trim(),
      campaignTitle: cmp?.title ?? 'Campanha Ativa',
      systemId: systemId,
      level: level,
      hpCurrent: hpCurrent,
      hpMax: hpMax,
      animaCurrent: animaCurrent,
      animaMax: animaMax,
      exhaustion: exhaustion,
      corpo: corpo,
      mente: mente,
      espirito: espirito,
      slots: slots.take(24).toList(),
      attributesMap: attributesMap ?? existing?.attributesMap ?? const {},
      resourcesMap: resourcesMap ?? existing?.resourcesMap ?? const {},
      equippedSlotsMap: equippedSlotsMap ?? existing?.equippedSlotsMap ?? const {},
      specializations: specializations ?? existing?.specializations ?? const [],
      silverCoins: silverCoins ?? existing?.silverCoins ?? 25,
      wealthTier: wealthTier ?? existing?.wealthTier ?? 'Comum',
      powers: powers ?? existing?.powers ?? const [],
      contacts: contacts ?? existing?.contacts ?? const [],
      lore: lore ?? existing?.lore ?? '',
      xpCurrent: xpCurrent ?? existing?.xpCurrent ?? 0,
    );
    characters = [
      saved,
      ...characters.where((c) => c.campaignId != cleanCampaignId),
    ];
    notifyListeners();
    return true;
  }

  // ==================== SISTEMAS & COMPENDIO DELTA ====================

  FilteredCompendiumResult queryCompendium({
    required String systemId,
    CompendiumCategory? category,
    String searchQuery = '',
  }) {
    return _filterCompendium.execute(
      systemItems: compendiumItems.where((i) => i.systemId == systemId).toList(),
      selectedCategory: category,
      searchQuery: searchQuery,
    );
  }

  Future<void> toggleFavoriteSystem(String systemId) async {
    if (favoriteSystemIds.contains(systemId)) {
      favoriteSystemIds = favoriteSystemIds.where((id) => id != systemId).toList();
    } else {
      favoriteSystemIds = [...favoriteSystemIds, systemId];
    }
    notifyListeners();
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      await edgeClient.postSync({
        'action': 'systems.toggle_favorite',
        'system_id': systemId,
      });
    }
  }

  void toggleOfflineCacheSystem(String systemId) {
    final next = Set<String>.from(offlineCachedSystemIds);
    if (next.contains(systemId)) {
      next.remove(systemId);
    } else {
      next.add(systemId);
    }
    offlineCachedSystemIds = next;
    notifyListeners();
  }

  Future<bool> createCustomSystem({
    required String name,
    required String diceEngine,
    required String description,
    required List<String> attributes,
    String? creationKey,
    bool isOfficial = false,
  }) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'systems.create',
        'name': name.trim(),
        'version': 'v1.0',
        'dice_engine': diceEngine.trim().isEmpty ? 'universal' : diceEngine.trim(),
        'description': description.trim(),
        'attributes': attributes,
        if (creationKey != null && creationKey.trim().isNotEmpty)
          'creation_key': creationKey.trim().toUpperCase(),
        'is_official': isOfficial,
      });
      if (!res.ok) {
        lastSyncError = _extractErrorMessage(
          res.data,
          'Key de Criacao invalida ou permissao negada.',
        );
        notifyListeners();
        return false;
      }
      if (res.data['system'] is Map<String, dynamic>) {
        final created = _mapSystem(res.data['system'] as Map<String, dynamic>);
        systems = [created, ...systems];
        notifyListeners();
        return true;
      }
    }

    final sys = RpgSystem(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      authorId: currentUser.id,
      name: name.trim(),
      version: 'v1.0',
      segment: isOfficial ? SystemSegment.oficiais : SystemSegment.proprios,
      diceEngine: diceEngine.trim().isEmpty ? 'universal' : diceEngine.trim(),
      description: description.trim(),
      attributes: attributes,
      downloadsCount: 1,
      rating: 5.0,
      isOfficial: isOfficial,
    );
    systems = [sys, ...systems];
    notifyListeners();
    return true;
  }

  Future<bool> upsertCompendiumItem({
    String? id,
    required String systemId,
    String? campaignId,
    String? parentId,
    required CompendiumCategory category,
    required String name,
    required String rarity,
    required int slotsWeight,
    required String description,
    bool isAllHidden = false,
    String baseAssetId = 'shield',
    String? equipSlot,
    Map<String, CompendiumBlock> blocks = const {},
  }) async {
    final existingCount = compendiumItems
        .where((i) => i.systemId == systemId && i.category == category)
        .length;
    final isUpdate = id != null && compendiumItems.any((i) => i.id == id);
    if (!isUpdate && existingCount >= 100) {
      lastSyncError =
          'Limite maximo rigido de 100 itens por categoria no Compendio atingido.';
      notifyListeners();
      return false;
    }

    final wireBlocks = <String, dynamic>{};
    for (final entry in blocks.entries) {
      wireBlocks[entry.key] = entry.value.toJson();
    }

    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'compendium.upsert',
        'id': ?id,
        'system_id': systemId,
        'campaign_id': ?campaignId,
        'parent_id': ?parentId,
        'category': category.name,
        'name': name.trim(),
        'rarity': rarity.trim(),
        'slots_weight': slotsWeight.clamp(0, 50),
        'description': description.trim(),
        'is_all_hidden': isAllHidden,
        'base_asset_id': baseAssetId,
        if (equipSlot != null && equipSlot.isNotEmpty) 'equip_slot': equipSlot,
        'blocks': wireBlocks,
      });
      if (!res.ok) {
        lastSyncError = _extractErrorMessage(res.data, 'Falha ao salvar item.');
        notifyListeners();
        return false;
      }
      if (res.data['item'] is Map<String, dynamic>) {
        final item = _mapCompendiumItem(res.data['item'] as Map<String, dynamic>);
        compendiumItems = [
          item,
          ...compendiumItems.where((i) => i.id != item.id),
        ];
        notifyListeners();
        return true;
      }
    }

    final builtBlocks = blocks.entries.map((e) {
      final b = e.value;
      if (b.diceFormula != null && b.diceFormula!.isNotEmpty) {
        final r = UniversalRpgEngineUseCase.parseDiceRange(b.diceFormula!);
        return CompendiumBlock(
          id: b.id,
          label: b.label,
          value: b.value,
          diceFormula: b.diceFormula,
          parsedMin: r.min,
          parsedMax: r.max,
          targetVariableId: b.targetVariableId,
          operation: b.operation,
          isVisible: b.isVisible,
        );
      }
      return b;
    }).toList();

    final localItem = CompendiumItem(
      id: id ?? 'cmpi_${DateTime.now().millisecondsSinceEpoch}',
      systemId: systemId,
      campaignId: campaignId,
      parentId: parentId,
      category: category,
      name: name.trim(),
      rarity: rarity.trim(),
      slotsWeight: slotsWeight.clamp(0, 50),
      description: description.trim(),
      baseAssetId: baseAssetId,
      equipSlot: equipSlot,
      isAllHidden: isAllHidden,
      authorId: currentUser.id,
      blocks: builtBlocks,
    );
    compendiumItems = [
      localItem,
      ...compendiumItems.where((i) => i.id != localItem.id),
    ];
    notifyListeners();
    return true;
  }

  // ==================== COMUNIDADES, FORUM, ANUNCIOS, CHAT & DM ====================

  Future<bool> createOfficialAnnouncement({
    required String tag,
    required String title,
    required String summary,
  }) async {
    if (!RbacGuard.canPublishOfficialAnnouncement(currentUser.role)) return false;
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'announcements.create',
        'tag': tag.trim().toUpperCase(),
        'title': title.trim(),
        'summary': summary.trim(),
      });
      if (!res.ok) return false;
      final raw = res.data['announcement'] as Map<String, dynamic>?;
      if (raw != null) {
        news = [
          NewsItem(
            id: (raw['id'] as String?) ?? 'ann',
            tag: (raw['tag'] as String?) ?? tag,
            title: (raw['title'] as String?) ?? title,
            summary: (raw['summary'] as String?) ?? summary,
          ),
          ...news,
        ];
        notifyListeners();
        return true;
      }
    }
    news = [
      NewsItem(
        id: 'news_${DateTime.now().millisecondsSinceEpoch}',
        tag: tag.trim().toUpperCase(),
        title: title.trim(),
        summary: summary.trim(),
      ),
      ...news,
    ];
    notifyListeners();
    return true;
  }

  Future<bool> createGuild({
    required String name,
    required String tag,
    required String description,
    String sharedWorldName = 'Mundo Compartilhado',
    String currentSeason = 'Temporada I',
  }) async {
    final cleanTag =
        tag.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'guilds.create',
        'name': name.trim(),
        'tag': cleanTag.isEmpty ? 'ARC' : cleanTag,
        'description': description.trim(),
        'shared_world_name': sharedWorldName,
        'current_season': currentSeason,
      });
      if (res.ok && res.data['guild'] is Map<String, dynamic>) {
        guilds = [_mapGuild(res.data['guild'] as Map<String, dynamic>), ...guilds];
        notifyListeners();
        return true;
      }
      return false;
    }

    guilds = [
      Guild(
        id: 'gld_${DateTime.now().millisecondsSinceEpoch}',
        leaderId: currentUser.id,
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
      ),
      ...guilds,
    ];
    notifyListeners();
    return true;
  }

  Future<void> contributeGuildBoost(String guildId, int points) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
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
      var lv = g.level;
      var pts = g.boostPoints + points;
      var goal = g.boostGoal;
      while (pts >= goal && lv < 5) {
        pts -= goal;
        lv += 1;
        goal += 500;
      }
      return Guild(
        id: g.id,
        leaderId: g.leaderId,
        name: g.name,
        tag: g.tag,
        leaderHandle: g.leaderHandle,
        description: g.description,
        memberCount: g.memberCount,
        activeTablesCount: g.activeTablesCount,
        boostPoints: pts,
        boostGoal: goal,
        sharedWorldName: g.sharedWorldName,
        currentSeason: g.currentSeason,
        level: lv,
        maxMembers: 20 + (lv - 1) * 20,
        maxMasters: 2 + (lv - 1) * 2,
        maxChannels: 2 + lv,
        maxClans: 1 + (lv - 1) * 2,
        maxCustomRoles: 3 + (lv - 1) * 3,
        clans: g.clans,
        wikiArticles: g.wikiArticles,
        channels: g.channels,
      );
    }).toList();
    notifyListeners();
  }

  Future<bool> updateGuildWorld(String guildId, Map<String, dynamic> worldPatch) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'guilds.update_world',
        'guild_id': guildId,
        'world_patch': worldPatch,
      });
      if (res.ok && res.data['guild'] is Map<String, dynamic>) {
        final updated = _mapGuild(res.data['guild'] as Map<String, dynamic>);
        guilds = guilds.map((g) => g.id == guildId ? updated : g).toList();
        notifyListeners();
        return true;
      }
      return false;
    }
    guilds = guilds.map((g) {
      if (g.id != guildId) return g;
      return Guild(
        id: g.id,
        leaderId: g.leaderId,
        name: g.name,
        tag: g.tag,
        leaderHandle: g.leaderHandle,
        description: g.description,
        memberCount: g.memberCount,
        activeTablesCount: g.activeTablesCount,
        boostPoints: g.boostPoints,
        boostGoal: g.boostGoal,
        sharedWorldName: (worldPatch['world'] as String?) ?? g.sharedWorldName,
        currentSeason: (worldPatch['season'] as String?) ?? g.currentSeason,
        level: g.level,
        maxMembers: g.maxMembers,
        maxMasters: g.maxMasters,
        maxChannels: g.maxChannels,
        maxClans: g.maxClans,
        maxCustomRoles: g.maxCustomRoles,
        clans: (worldPatch['clans'] as List<dynamic>?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
                .toList() ??
            g.clans,
        wikiArticles: (worldPatch['wiki'] as List<dynamic>?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
                .toList() ??
            g.wikiArticles,
        channels: (worldPatch['channels'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            g.channels,
      );
    }).toList();
    notifyListeners();
    return true;
  }

  Future<void> createForumTopic({
    required String category,
    required String title,
    required String content,
  }) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
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
      createdAtIso: DateTime.now().toIso8601String(),
    );
    forumTopics = [topic, ...forumTopics];
    notifyListeners();
  }

  Future<void> upvoteTopic(String topicId, {int delta = 1}) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'forum.upvote',
        'topic_id': topicId,
        'delta': delta,
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
      return t.copyWith(upvotes: (t.upvotes + delta).clamp(0, 99999));
    }).toList();
    notifyListeners();
  }

  Future<ForumTopic?> fetchForumTopicDetail(String topicId) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'forum.get_topic',
        'topic_id': topicId,
      });
      if (res.ok && res.data['topic'] is Map<String, dynamic>) {
        final rawComments = (res.data['comments'] as List<dynamic>?) ?? [];
        final comments = rawComments.whereType<Map<String, dynamic>>().map((c) {
          return ForumComment(
            id: (c['id'] as String?) ?? 'cmt',
            topicId: (c['topic_id'] as String?) ?? topicId,
            authorHandle: (c['author_handle'] as String?) ?? '@heroi',
            content: (c['content'] as String?) ?? '',
            timeAgo: _formatTimeShort(c['created_at'] as String?),
          );
        }).toList();
        final updated = _mapForumTopic(res.data['topic'] as Map<String, dynamic>)
            .copyWith(comments: comments, repliesCount: comments.length);
        forumTopics = forumTopics.map((t) => t.id == topicId ? updated : t).toList();
        notifyListeners();
        return updated;
      }
    }
    for (final t in forumTopics) {
      if (t.id == topicId) return t;
    }
    return null;
  }

  Future<void> commentOnForumTopic(String topicId, String content) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'forum.comment',
        'topic_id': topicId,
        'content': content.trim(),
      });
      if (res.ok) {
        await fetchForumTopicDetail(topicId);
        return;
      }
    }
    forumTopics = forumTopics.map((t) {
      if (t.id != topicId) return t;
      final cmt = ForumComment(
        id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
        topicId: topicId,
        authorHandle: '@${currentUser.username}',
        content: content.trim(),
        timeAgo: 'agora',
      );
      return t.copyWith(
        comments: [...t.comments, cmt],
        repliesCount: t.comments.length + 1,
      );
    }).toList();
    notifyListeners();
  }

  Future<void> sendCommunityMessage({
    required String content,
    String channelId = 'taverna-dos-mestres',
    String? replyPreview,
    bool with3d6Roll = false,
    String rollLabel = 'ROLAGEM NA TAVERNA (3D6)',
    String? rollExpression,
    String persona = 'ic', // ic | ooc | narrador | npc
    String? npcName,
    String? campaignId,
  }) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'chat.send_message',
        'channel_id': channelId,
        'content': content.trim(),
        'with_3d6_roll': with3d6Roll,
        'roll_label': rollLabel,
        if (rollExpression != null && rollExpression.isNotEmpty)
          'roll_expression': rollExpression,
        'persona': persona,
        if (npcName != null && npcName.isNotEmpty) 'npc_name': npcName,
        if (campaignId != null && campaignId.isNotEmpty) 'campaign_id': campaignId,
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
    DiceRoll3d6? diceRoll;
    if (rollExpression != null && rollExpression.isNotEmpty) {
      diceRoll = await rollUniversal(rollExpression, label: rollLabel);
    } else if (with3d6Roll) {
      diceRoll = _roll3d6.execute(label: rollLabel);
    }

    final message = ChatMessage(
      id: 'msg_${now.millisecondsSinceEpoch}',
      channelId: channelId,
      senderId: currentUser.id,
      senderHandle: '@${currentUser.username}',
      senderRole: currentUser.role,
      content: content.trim(),
      timeText: '$hh:$mm',
      isMine: true,
      isRead: true,
      replyPreview: replyPreview,
      diceRoll: diceRoll,
      msgType: persona,
      npcName: npcName,
    );
    chatMessages = [...chatMessages, message];
    notifyListeners();
  }

  Future<void> moderateChatActionCard({
    required String campaignId,
    required String messageId,
    required String decision, // approved | rejected
  }) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'chat.moderate_action_card',
        'campaign_id': campaignId,
        'message_id': messageId,
        'decision': decision,
      });
      if (res.ok && res.data['message'] is Map<String, dynamic>) {
        final updated = _mapChatMessage(res.data['message'] as Map<String, dynamic>);
        chatMessages = chatMessages.map((m) => m.id == messageId ? updated : m).toList();
        await hydrateAllFromBackend(channelId: updated.channelId);
        return;
      }
    }
    chatMessages = chatMessages.map((m) {
      if (m.id != messageId) return m;
      return ChatMessage(
        id: m.id,
        channelId: m.channelId,
        senderId: m.senderId,
        senderHandle: m.senderHandle,
        senderRole: m.senderRole,
        content: '${m.content} [${decision == 'approved' ? 'APROVADO' : 'RECUSADO'}]',
        timeText: m.timeText,
        isMine: m.isMine,
        isRead: m.isRead,
        replyPreview: m.replyPreview,
        diceRoll: m.diceRoll,
        msgType: m.msgType,
        actionCard: {...?m.actionCard, 'status': decision},
      );
    }).toList();
    notifyListeners();
  }

  Future<void> deleteChatMessage(String messageId, {String? campaignId}) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      await edgeClient.postSync({
        'action': 'chat.delete_message',
        'message_id': messageId,
        'campaign_id': ?campaignId,
      });
    }
    chatMessages = chatMessages.where((m) => m.id != messageId).toList();
    notifyListeners();
  }

  Future<void> clearChatChannel(String campaignId, String channelId) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      await edgeClient.postSync({
        'action': 'chat.clear_channel',
        'campaign_id': campaignId,
        'channel_id': channelId,
      });
    }
    chatMessages = chatMessages.where((m) => m.channelId != channelId).toList();
    notifyListeners();
  }

  // ==================== SOCIAL, PERFIL DISCORD & DMS 1-A-1 ====================

  Future<SocialProfileView?> fetchSocialProfile({
    String? userId,
    String? username,
  }) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'social.get_profile',
        if (userId != null && userId.isNotEmpty) 'user_id': userId,
        if (username != null && username.isNotEmpty) 'username': username,
      });
      if (res.ok && res.data['profile'] is Map<String, dynamic>) {
        final p = res.data['profile'] as Map<String, dynamic>;
        final show = (res.data['showcase'] as Map<String, dynamic>?) ?? {};
        final mutualRaw = (res.data['mutual_campaigns'] as List<dynamic>?) ?? [];
        final rawContacts = (p['contacts'] as Map?)?.cast<String, dynamic>() ?? {};
        return SocialProfileView(
          userId: (p['user_id'] as String?) ?? '',
          username: (p['username'] as String?) ?? '',
          displayName: (p['display_name'] as String?) ?? 'Aventureiro',
          bio: (p['bio'] as String?) ?? '',
          avatarIcon: (p['avatar_icon'] as String?) ?? 'shield',
          role: UserRole.fromWire((p['role'] as String?) ?? 'jogador'),
          oauthVerified: (p['oauth_verified'] as bool?) ?? true,
          reputationPoints: (p['reputation_points'] as num?)?.toInt() ?? 0,
          createdAt: (p['created_at'] as String?) ?? '',
          contacts: rawContacts.map((k, v) => MapEntry(k, v.toString())),
          mutualCampaigns: mutualRaw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
              .toList(),
          campaignsAsPlayer: (show['campaigns_as_player'] as num?)?.toInt() ?? 0,
          campaignsAsMaster: (show['campaigns_as_master'] as num?)?.toInt() ?? 0,
          charactersCount: (show['characters_count'] as num?)?.toInt() ?? 0,
          systemsRanked: (show['systems_ranked'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
              .toList(),
          campaignsList: (show['campaigns_list'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
              .toList(),
          charactersList: (show['characters_list'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
              .toList(),
        );
      }
    }

    return SocialProfileView(
      userId: userId ?? currentUser.id,
      username: username ?? currentUser.username,
      displayName: currentUser.displayName,
      bio: currentUser.bio,
      avatarIcon: currentUser.avatarIcon,
      role: currentUser.role,
      reputationPoints: currentUser.reputationPoints,
      contacts: currentUser.socialContacts,
      campaignsAsPlayer:
          campaigns.where((c) => c.userRelation == CampaignSegment.jogando).length,
      campaignsAsMaster:
          campaigns.where((c) => c.userRelation == CampaignSegment.mestre).length,
      charactersCount: characters.length,
    );
  }

  Future<List<ChatMessage>> fetchDmMessages(String peerUserId) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'dm.list_messages',
        'peer_user_id': peerUserId,
      });
      if (res.ok) {
        final raw = (res.data['messages'] as List<dynamic>?) ?? [];
        final list = raw.whereType<Map<String, dynamic>>().map(_mapChatMessage).toList();
        dmThreads[peerUserId] = list;
        notifyListeners();
        return list;
      }
    }
    return dmThreads[peerUserId] ?? const [];
  }

  Future<bool> sendDmMessage({
    required String peerUserId,
    required String content,
    String? rollExpression,
  }) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'dm.send_message',
        'peer_user_id': peerUserId,
        'content': content.trim(),
        if (rollExpression != null && rollExpression.trim().isNotEmpty)
          'roll_expression': rollExpression.trim(),
      });
      if (!res.ok) {
        lastSyncError = _extractErrorMessage(res.data, 'Erro ao enviar DM.');
        notifyListeners();
        return false;
      }
      if (res.data['message'] is Map<String, dynamic>) {
        final sent = _mapChatMessage(res.data['message'] as Map<String, dynamic>);
        dmThreads[peerUserId] = [...(dmThreads[peerUserId] ?? []), sent];
        notifyListeners();
        return true;
      }
    }
    final localMsg = ChatMessage(
      id: 'dm_${DateTime.now().millisecondsSinceEpoch}',
      channelId: 'dm:$peerUserId',
      senderId: currentUser.id,
      senderHandle: '@${currentUser.username}',
      senderRole: currentUser.role,
      content: content.trim(),
      timeText: 'agora',
      isMine: true,
      isRead: true,
      msgType: 'dm',
    );
    dmThreads[peerUserId] = [...(dmThreads[peerUserId] ?? []), localMsg];
    notifyListeners();
    return true;
  }

  Future<void> markAllNotificationsRead() async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      await edgeClient.postSync({'action': 'notifications.mark_read'});
    }
    notifications = notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  Future<void> markNotificationRead(String id) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      await edgeClient.postSync({
        'action': 'notifications.mark_read',
        'notification_id': id,
      });
    }
    notifications =
        notifications.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
    notifyListeners();
  }

  void toggleTutorialCompleted(String tutorialId, {bool? forceDone}) {
    tutorials = tutorials
        .map((t) => t.id == tutorialId
            ? t.copyWith(completed: forceDone ?? !t.completed)
            : t)
        .toList();
    notifyListeners();
  }

  Future<String?> addFriendByUsername(String rawHandle) async {
    final clean = rawHandle.replaceAll('@', '').trim().toLowerCase();
    if (clean.length < 3) {
      return 'Informe o @username valido (minimo 3 caracteres).';
    }

    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'social.add_friend',
        'username': clean,
      });
      if (!res.ok) {
        return _extractErrorMessage(res.data, 'Usuario nao localizado.');
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
        displayName: clean,
        presenceStatus: 'online',
        activity: 'Na Taverna',
        lastDm: 'Solicitacao enviada.',
      ),
      ...friends,
    ];
    notifyListeners();
    return null;
  }

  Future<void> respondFriendRequest(String friendUserId, String decision) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'social.respond_friend',
        'friend_user_id': friendUserId,
        'decision': decision,
      });
      if (res.ok && res.data['friends'] is List<dynamic>) {
        friends = (res.data['friends'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(_mapFriend)
            .toList();
        notifyListeners();
        return;
      }
    }
    if (decision == 'reject' || decision == 'remove') {
      friends = friends.where((f) => f.id != friendUserId).toList();
    } else if (decision == 'accept') {
      friends = friends
          .map((f) => f.id == friendUserId
              ? FriendContact(
                  id: f.id,
                  username: f.username,
                  displayName: f.displayName,
                  presenceStatus: f.presenceStatus,
                  activity: 'Aliado Confirmado',
                  lastDm: f.lastDm,
                  status: 'accepted',
                  avatarIcon: f.avatarIcon,
                )
              : f)
          .toList();
    }
    notifyListeners();
  }

  // ==================== DENUNCIA UNIVERSAL & GOVERNANCA ADMIN ====================

  Future<UniversalReport> submitUniversalReport({
    required String originType,
    required String originId,
    required String reasonCategory,
    required String description,
    String sessionContext = 'sessao_hub',
    String? targetUserId,
  }) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'report.submit',
        'origin_type': originType,
        'origin_id': originId,
        if (targetUserId != null && targetUserId.isNotEmpty)
          'target_user_id': targetUserId,
        'reason_category': reasonCategory,
        'description': description.trim(),
        'context_session': sessionContext,
      });
      if (res.ok) {
        final rawTags = (res.data['auto_tags'] as List<dynamic>?) ?? [];
        final report = UniversalReport(
          id: (res.data['report_id'] as String?) ??
              'rep_${DateTime.now().millisecondsSinceEpoch}',
          originType: originType,
          entityType: originType,
          originId: originId,
          targetUserId: targetUserId,
          reasonCategory: reasonCategory,
          description: '[TIPO: ${originType.toUpperCase()}] ${description.trim()}',
          autoTags: rawTags.map((e) => e.toString()).toList(),
          status: (res.data['status'] as String?) ?? 'pending',
          createdAtText: 'Agora',
          votesCount: 0,
          requiredVotes: 3,
        );
        reports = [report, ...reports];
        notifyListeners();
        return report;
      }
    }

    final report = _buildReport.execute(
      originType: originType,
      originId: originId,
      targetUserId: targetUserId,
      reasonCategory: reasonCategory,
      description: description,
      reporterRole: currentUser.role,
      sessionContext: sessionContext,
    );
    reports = [report, ...reports];
    notifyListeners();
    return report;
  }

  Future<String?> moderateReport({
    required String reportId,
    required String decision,
    bool applyHardwareBan = false,
    String? banFingerprint,
    String? banReason,
  }) async {
    final wireDecision = applyHardwareBan ? 'hardware_ban' : decision;
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'admin.moderate',
        'report_id': reportId,
        'decision': wireDecision,
        if (banFingerprint != null && banFingerprint.trim().isNotEmpty)
          'ban_device_fingerprint': banFingerprint.trim(),
        if (banReason != null && banReason.trim().isNotEmpty)
          'ban_reason': banReason.trim(),
      });
      if (!res.ok) {
        return _extractErrorMessage(res.data, 'Erro ao moderar denuncia.');
      }
      final newStatus = (res.data['status'] as String?) ?? 'resolved';
      final votes = (res.data['votes_count'] as num?)?.toInt() ?? 1;
      reports = reports
          .map((r) =>
              r.id == reportId ? r.copyWith(status: newStatus, votesCount: votes) : r)
          .toList();
      await hydrateAllFromBackend();
      return res.data['message'] as String?;
    }

    reports = reports
        .map((r) => r.id == reportId ? r.copyWith(status: 'resolved') : r)
        .toList();
    if (applyHardwareBan && banFingerprint != null && banFingerprint.trim().isNotEmpty) {
      hardwareBannedFingerprints = [banFingerprint.trim(), ...hardwareBannedFingerprints];
    }
    notifyListeners();
    return null;
  }

  Future<void> adminUnbanDevice(String deviceFingerprint) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      await edgeClient.postSync({
        'action': 'admin.unban_device',
        'device_fingerprint': deviceFingerprint,
      });
    }
    bannedDevices = bannedDevices
        .where((d) => d.deviceFingerprint != deviceFingerprint)
        .toList();
    hardwareBannedFingerprints = hardwareBannedFingerprints
        .where((fp) => fp != deviceFingerprint)
        .toList();
    notifyListeners();
  }

  Future<SystemCreationKey?> adminGenerateCreationKey({
    String? assignedToUserId,
  }) async {
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'admin.generate_creation_key',
        if (assignedToUserId != null && assignedToUserId.isNotEmpty)
          'assigned_to_user_id': assignedToUserId,
      });
      if (res.ok && res.data['key'] is Map<String, dynamic>) {
        final k = res.data['key'] as Map<String, dynamic>;
        final created = SystemCreationKey(
          code: (k['code'] as String?) ?? 'KEY-ARC-0000',
          createdBy: (k['created_by'] as String?) ?? currentUser.id,
          assignedToUserId: k['assigned_to_user_id'] as String?,
          isUsed: false,
          createdAt: (k['created_at'] as String?) ?? '',
        );
        systemCreationKeys = [created, ...systemCreationKeys];
        notifyListeners();
        return created;
      }
    }
    return null;
  }

  Future<List<ChatMessage>> adminAuditDms(String userA, String userB) async {
    if (currentUser.role != UserRole.superadmin) return const [];
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'admin.audit_dms',
        'user_a': userA,
        'user_b': userB,
      });
      if (res.ok) {
        final raw = (res.data['messages'] as List<dynamic>?) ?? [];
        return raw.whereType<Map<String, dynamic>>().map(_mapChatMessage).toList();
      }
    }
    return const [];
  }

  Future<String?> adminUpdateUserRole({
    required String targetUserId,
    required UserRole newRole,
  }) async {
    if (!RbacGuard.canAccessAdminPanel(currentUser.role)) {
      return 'Acesso negado.';
    }
    if (newRole == UserRole.admin && !RbacGuard.canManageAdmins(currentUser.role)) {
      return 'Apenas o Superadmin pode promover Administradores.';
    }
    if (edgeClient.bearerToken != null && edgeClient.bearerToken!.isNotEmpty) {
      final res = await edgeClient.postSync({
        'action': 'admin.update_role',
        'target_user_id': targetUserId,
        'role': newRole.wireKey,
      });
      if (!res.ok) {
        final msg = _extractErrorMessage(res.data, 'Nao foi possivel alterar o cargo.');
        lastSyncError = msg;
        notifyListeners();
        return msg;
      }
    }

    adminUsers = adminUsers
        .map((u) => u.id == targetUserId ? u.copyWith(role: newRole) : u)
        .toList();
    notifyListeners();
    return null;
  }

  // ==================== MAPEAMENTOS D1 -> ENTITIES ====================

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
    } else if (tableRole == 'assistente_mestre' && memberStatus == 'active') {
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

    var st = <String, dynamic>{};
    try {
      final stateRaw = c['state_json'] as String?;
      if (stateRaw != null && stateRaw.isNotEmpty) {
        final decoded = jsonDecode(stateRaw);
        if (decoded is Map<String, dynamic>) st = decoded;
      }
    } catch (_) {}

    final sysId = (c['system_id'] as String?) ?? 'sys_universal';
    final matchedSystem = systems.cast<RpgSystem?>().firstWhere(
          (s) => s?.id == sysId,
          orElse: () => null,
        );

    return Campaign(
      id: (c['id'] as String?) ?? '',
      ownerId: ownerId,
      title: (c['title'] as String?) ?? 'Campanha sem titulo',
      synopsis: (c['synopsis'] as String?) ?? '',
      masterHandle: ownerId == currentUser.id ? '@${currentUser.username}' : '@mestre',
      systemId: sysId,
      systemName: matchedSystem?.name ?? 'Motor Universal',
      quickJoinCode: (c['quick_join_code'] as String?) ?? 'ARC000',
      mode: mode,
      scheduleText: (c['schedule_text'] as String?) ?? 'Tempo Livre',
      maxSlots: (c['max_slots'] as int?) ?? 5,
      occupiedSlots: (c['occupied_slots'] as int?) ?? 1,
      userRelation: relation,
      chapterTitle: (st['chapter'] as String?) ?? 'Sessao 0',
      isPublic: ((c['visibility'] as String?) ?? 'publica') == 'publica',
      iconName: (st['icon_name'] as String?) ?? 'swords',
      bannerPreset: (st['banner_preset'] as String?) ?? 'cidadela_obsidiana',
      ageRating: (st['age_rating'] as String?) ?? '16+',
      tags: (st['tags'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      sessionsCount: (st['sessions_count'] as num?)?.toInt() ?? 0,
      noticeBoard: (st['notice_board'] as String?) ??
          'Bem-vindos a mesa! Aguardem as instrucoes do Mestre.',
      autoApproveActions: (st['auto_approve_actions'] as bool?) ?? false,
      sceneAccessMode: (st['scene_access_mode'] as String?) ?? 'free',
      xpMultiplier: (st['xp_multiplier'] as num?)?.toDouble() ?? 1.0,
      discordVoiceUrl: (st['discord_voice_url'] as String?) ?? '',
      discordWebhookUrl: (st['discord_webhook_url'] as String?) ?? '',
      isInactiveArchived: ((c['is_inactive_archived'] as num?)?.toInt() ?? 0) == 1,
      channels: (st['channels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .take(3)
              .toList() ??
          const ['#geral-mesa', '#off-topic', '#segredos-sussurros'],
      worldClock: WorldClockState.fromJson(st['world_clock'] as Map<String, dynamic>?),
      factions: (st['factions'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => FactionEntry.fromJson(Map<String, dynamic>.from(e.cast<String, dynamic>())))
          .toList(),
      worldMaps: (st['world_maps'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => WorldMapEntry.fromJson(Map<String, dynamic>.from(e.cast<String, dynamic>())))
          .toList(),
      diaryEntries: (st['diary_entries'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => DiaryEntry.fromJson(Map<String, dynamic>.from(e.cast<String, dynamic>())))
          .toList(),
    );
  }

  RpgSystem _mapSystem(Map<String, dynamic> s) {
    final seg = switch ((s['category_type'] as String?) ?? 'proprios') {
      'oficiais' => SystemSegment.oficiais,
      'meus' => SystemSegment.meus,
      'comunidade' => SystemSegment.comunidade,
      _ => SystemSegment.proprios,
    };
    var attrs = <String>['Corpo', 'Mente', 'Espirito'];
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
    final id = (s['id'] as String?) ?? '';
    return RpgSystem(
      id: id,
      authorId: (s['author_id'] as String?) ?? '',
      name: (s['name'] as String?) ?? 'Sistema',
      version: (s['version'] as String?) ?? 'v1.0',
      segment: seg,
      diceEngine: (s['dice_engine'] as String?) ?? 'universal',
      description: (s['description'] as String?) ?? '',
      attributes: attrs,
      downloadsCount: (s['downloads_count'] as int?) ?? 1,
      rating: ((s['rating'] as num?) ?? 5.0).toDouble(),
      isOfficial: ((s['is_official'] as int?) ?? 0) == 1,
      isFavorite: favoriteSystemIds.contains(id),
      isOfflineCached: offlineCachedSystemIds.contains(id),
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

    var props = <String, dynamic>{};
    try {
      final raw = i['properties_json'] as String?;
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) props = decoded;
      }
    } catch (_) {}

    final blocksRaw = (props['blocks'] as Map?)?.cast<String, dynamic>() ?? {};
    final blocks = blocksRaw.entries
        .where((e) => e.value is Map)
        .map((e) => CompendiumBlock.fromJson(
              e.key,
              Map<String, dynamic>.from((e.value as Map).cast<String, dynamic>()),
            ))
        .toList();

    return CompendiumItem(
      id: (i['id'] as String?) ?? '',
      systemId: (i['system_id'] as String?) ?? '',
      campaignId: i['campaign_id'] as String?,
      parentId: props['parent_id'] as String?,
      category: cat,
      name: (i['name'] as String?) ?? '',
      rarity: (i['rarity'] as String?) ?? 'Comum',
      slotsWeight: (i['slots_weight'] as int?) ?? 1,
      description: (i['description'] as String?) ?? '',
      baseAssetId: (props['base_asset_id'] as String?) ?? 'shield',
      equipSlot: props['equip_slot'] as String?,
      isAllHidden: (props['is_all_hidden'] as bool?) ?? false,
      authorId: (props['author_id'] as String?) ?? '',
      blocks: blocks,
    );
  }

  CampaignScene _mapScene(Map<String, dynamic> s) {
    Map<String, dynamic> parseMap(String? raw) {
      if (raw == null || raw.isEmpty) return {};
      try {
        final d = jsonDecode(raw);
        return d is Map ? Map<String, dynamic>.from(d.cast<String, dynamic>()) : {};
      } catch (_) {
        return {};
      }
    }

    List<Map<String, dynamic>> parseList(String? raw) {
      if (raw == null || raw.isEmpty) return const [];
      try {
        final d = jsonDecode(raw);
        if (d is List) {
          return d
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
              .toList();
        }
      } catch (_) {}
      return const [];
    }

    return CampaignScene(
      id: (s['id'] as String?) ?? '',
      campaignId: (s['campaign_id'] as String?) ?? '',
      name: (s['name'] as String?) ?? 'Cena',
      description: (s['description'] as String?) ?? '',
      modelType: SceneModelType.fromWire((s['model_type'] as String?) ?? 'grid_2d'),
      isActive: ((s['is_active'] as num?)?.toInt() ?? 0) == 1,
      maxPlayers: (s['max_players'] as num?)?.toInt() ?? 12,
      modelData: parseMap(s['model_data_json'] as String?),
      rulesData: parseList(s['rules_data_json'] as String?),
      stateData: parseMap(s['state_data_json'] as String?),
    );
  }

  Guild _mapGuild(Map<String, dynamic> g) {
    var w = <String, dynamic>{};
    try {
      final raw = g['shared_world_json'] as String?;
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) w = decoded;
      }
    } catch (_) {}

    return Guild(
      id: (g['id'] as String?) ?? '',
      leaderId: (g['leader_id'] as String?) ?? '',
      name: (g['name'] as String?) ?? 'Guilda',
      tag: (g['tag'] as String?) ?? 'ARC',
      leaderHandle: (g['leader_id'] as String?) == currentUser.id
          ? '@${currentUser.username}'
          : '@anfitriao',
      description: (g['description'] as String?) ?? '',
      memberCount: (g['member_count'] as int?) ?? 1,
      activeTablesCount: (g['active_tables_count'] as int?) ?? 0,
      boostPoints: (g['boost_points'] as int?) ?? 0,
      boostGoal: (g['boost_goal'] as int?) ?? 1000,
      sharedWorldName: (w['world'] as String?) ?? 'Mundo Compartilhado',
      currentSeason: (w['season'] as String?) ?? 'Temporada I',
      level: (w['level'] as num?)?.toInt() ?? 1,
      maxMembers: (w['max_members'] as num?)?.toInt() ?? 20,
      maxMasters: (w['max_masters'] as num?)?.toInt() ?? 2,
      maxChannels: (w['max_channels'] as num?)?.toInt() ?? 3,
      maxClans: (w['max_clans'] as num?)?.toInt() ?? 1,
      maxCustomRoles: (w['max_custom_roles'] as num?)?.toInt() ?? 3,
      clans: (w['clans'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
          .toList(),
      wikiArticles: (w['wiki'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
          .toList(),
      channels: (w['channels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['#taverna-guilda', '#world-wiki'],
    );
  }

  ForumTopic _mapForumTopic(Map<String, dynamic> t) {
    return ForumTopic(
      id: (t['id'] as String?) ?? '',
      authorHandle: (t['author_handle'] as String?) ?? '@heroi',
      category: (t['category'] as String?) ?? 'Regras',
      title: (t['title'] as String?) ?? '',
      content: (t['content'] as String?) ?? '',
      upvotes: (t['upvotes'] as int?) ?? 1,
      repliesCount: (t['replies_count'] as int?) ?? 0,
      pinned: ((t['pinned'] as int?) ?? 0) == 1,
      timeAgo: _formatTimeShort(t['created_at'] as String?),
      createdAtIso: (t['created_at'] as String?) ?? '',
    );
  }

  ChatMessage _mapChatMessage(Map<String, dynamic> m) {
    DiceRoll3d6? dice;
    var msgType = 'ic';
    String? npcName;
    String? whisperTarget;
    Map<String, dynamic>? actionCard;

    try {
      final rawDice = m['dice_roll_json'] as String?;
      if (rawDice != null && rawDice.isNotEmpty) {
        final decoded = jsonDecode(rawDice) as Map<String, dynamic>;
        msgType = (decoded['msg_type'] as String?) ?? msgType;
        npcName = decoded['npc_name'] as String?;
        whisperTarget = decoded['whisper_target'] as String?;
        if (decoded['action_card'] is Map) {
          actionCard = Map<String, dynamic>.from(
            (decoded['action_card'] as Map).cast<String, dynamic>(),
          );
        }
        final rollObj = decoded['roll'] is Map
            ? Map<String, dynamic>.from((decoded['roll'] as Map).cast<String, dynamic>())
            : (decoded.containsKey('dice') ? decoded : null);
        if (rollObj != null) {
          dice = DiceRoll3d6(
            label: (rollObj['label'] as String?) ?? 'ROLAGEM',
            dice: ((rollObj['dice'] as List<dynamic>?) ?? [])
                .map((e) => int.tryParse(e.toString()) ?? 1)
                .toList(),
            successes: (rollObj['successes'] as int?) ?? 0,
            outcome: (rollObj['outcome'] as String?) ?? '',
            expression: (rollObj['expression'] as String?) ?? '3d6',
            total: (rollObj['total'] as num?)?.toInt() ?? 0,
            engine: (rollObj['engine'] as String?) ?? 'formula',
            keptDice: ((rollObj['kept_dice'] as List<dynamic>?) ?? [])
                .map((e) => int.tryParse(e.toString()) ?? 1)
                .toList(),
          );
        }
      }
    } catch (_) {}

    final senderId = (m['sender_id'] as String?) ?? '';
    return ChatMessage(
      id: (m['id'] as String?) ?? '',
      channelId: (m['channel_id'] as String?) ?? 'taverna-dos-mestres',
      senderId: senderId,
      senderHandle: (m['sender_handle'] as String?) ?? '@heroi',
      senderRole: UserRole.fromWire((m['sender_role'] as String?) ?? 'jogador'),
      content: (m['content'] as String?) ?? '',
      timeText: _formatHourMinute(m['created_at'] as String?),
      isMine: senderId == currentUser.id,
      isRead: true,
      replyPreview: m['reply_preview'] as String?,
      diceRoll: dice,
      msgType: msgType,
      npcName: npcName,
      whisperTarget: whisperTarget,
      actionCard: actionCard,
    );
  }

  HeroCharacter _mapCharacter(Map<String, dynamic> c) {
    var corpo = 2;
    var mente = 2;
    var espirito = 2;
    final attrsMap = <String, int>{};
    try {
      final rawAttr = jsonDecode((c['attributes_json'] as String?) ?? '{}')
          as Map<String, dynamic>;
      corpo = (rawAttr['corpo'] as num?)?.toInt() ?? 2;
      mente = (rawAttr['mente'] as num?)?.toInt() ?? 2;
      espirito = (rawAttr['espirito'] as num?)?.toInt() ?? 2;
      rawAttr.forEach((k, v) {
        if (v is num) attrsMap[k] = v.toInt();
      });
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
    var equippedSlots = <String, String>{};
    var resourcesMap = <String, int>{};
    var specs = <String>[];
    var silverCoins = 25;
    var wealthTier = 'Comum';
    var powers = <String>[];
    var contacts = <String>[];
    var lore = '';
    var xpCurrent = 0;

    try {
      final rawSt = jsonDecode((c['statuses_json'] as String?) ?? '{}')
          as Map<String, dynamic>;
      hpCur = (rawSt['hp_current'] as num?)?.toInt() ?? 20;
      hpMax = (rawSt['hp_max'] as num?)?.toInt() ?? 20;
      animaCur = (rawSt['anima_current'] as num?)?.toInt() ?? 10;
      animaMax = (rawSt['anima_max'] as num?)?.toInt() ?? 10;
      exhaustion = (rawSt['exhaustion'] as num?)?.toInt() ?? 0;
      silverCoins = (rawSt['silver_coins'] as num?)?.toInt() ?? 25;
      wealthTier = (rawSt['wealth_tier'] as String?) ?? 'Comum';
      lore = (rawSt['lore'] as String?) ?? '';
      xpCurrent = (rawSt['xp_current'] as num?)?.toInt() ?? 0;
      if (rawSt['equipped_slots'] is Map) {
        (rawSt['equipped_slots'] as Map).forEach((k, v) {
          equippedSlots[k.toString()] = v.toString();
        });
      }
      if (rawSt['resources'] is Map) {
        (rawSt['resources'] as Map).forEach((k, v) {
          if (v is num) resourcesMap[k.toString()] = v.toInt();
        });
      }
      if (rawSt['specializations'] is List) {
        specs = (rawSt['specializations'] as List).map((e) => e.toString()).toList();
      }
      if (rawSt['powers'] is List) {
        powers = (rawSt['powers'] as List).map((e) => e.toString()).toList();
      }
      if (rawSt['contacts'] is List) {
        contacts = (rawSt['contacts'] as List).map((e) => e.toString()).toList();
      }
    } catch (_) {}

    final cmpId = (c['campaign_id'] as String?) ?? '';
    var resolvedTitle = 'Campanha Vinculada';
    for (final cmp in campaigns) {
      if (cmp.id == cmpId) {
        resolvedTitle = cmp.title;
        break;
      }
    }

    return HeroCharacter(
      id: (c['id'] as String?) ?? '',
      campaignId: cmpId,
      name: (c['name'] as String?) ?? 'Heroi',
      heroClass: (c['title'] as String?) ?? 'Aventureiro',
      campaignTitle: resolvedTitle,
      systemId: (c['system_id'] as String?) ?? 'sys_universal',
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
      attributesMap: attrsMap,
      resourcesMap: resourcesMap,
      equippedSlotsMap: equippedSlots,
      specializations: specs,
      silverCoins: silverCoins,
      wealthTier: wealthTier,
      powers: powers,
      contacts: contacts,
      lore: lore,
      xpCurrent: xpCurrent,
    );
  }

  CampaignMemberSummary _mapCampaignMember(Map<String, dynamic> m) {
    final uname = (m['username'] as String?) ??
        ((m['user_id'] as String?) ?? 'heroi').replaceAll('usr_', '');
    return CampaignMemberSummary(
      campaignId: (m['campaign_id'] as String?) ?? '',
      userId: (m['user_id'] as String?) ?? '',
      username: uname,
      displayName: (m['display_name'] as String?) ?? uname,
      tableRole: (m['table_role'] as String?) ?? 'jogador',
      status: (m['status'] as String?) ?? 'pending',
      applicationPitch: (m['application_pitch'] as String?) ?? '',
    );
  }

  AdminUserSummary _mapAdminUser(Map<String, dynamic> u) {
    final uname = (u['username'] as String?) ?? '';
    return AdminUserSummary(
      id: (u['id'] as String?) ?? '',
      email: (u['email'] as String?) ?? '',
      birthDate: (u['birth_date'] as String?) ?? '',
      role: UserRole.fromWire((u['role'] as String?) ?? 'jogador'),
      accountStatus: (u['account_status'] as String?) ?? 'active',
      username: uname,
      displayName: (u['display_name'] as String?) ?? uname,
      suspendedUntil: u['suspended_until'] as String?,
    );
  }

  FriendContact _mapFriend(Map<String, dynamic> f) {
    final uname = (f['friend_username'] as String?) ??
        (f['friend_id'] as String? ?? 'aliado');
    return FriendContact(
      id: (f['friend_id'] as String?) ?? '',
      username: uname,
      displayName: (f['friend_display_name'] as String?) ?? uname,
      presenceStatus: (f['presence_status'] as String?) ?? 'online',
      activity: (f['presence_activity'] as String?) ?? 'Na Taverna',
      lastDm: 'Clique para abrir DM privada.',
      status: (f['status'] as String?) ?? 'accepted',
    );
  }

  AppNotification _mapNotification(Map<String, dynamic> n) {
    String? campaignCode;
    String? campaignId;
    String? inviteId;
    try {
      final raw = n['action_payload_json'] as String?;
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        campaignCode = decoded['campaign_code'] as String?;
        campaignId = decoded['campaign_id'] as String?;
        inviteId = decoded['invite_id'] as String?;
      }
    } catch (_) {}
    return AppNotification(
      id: (n['id'] as String?) ?? '',
      category: (n['category'] as String?) ?? 'sistema',
      title: (n['title'] as String?) ?? '',
      body: (n['body'] as String?) ?? '',
      timeAgo: _formatTimeShort(n['created_at'] as String?),
      isRead: ((n['is_read'] as int?) ?? 0) == 1,
      campaignCode: campaignCode,
      campaignId: campaignId,
      inviteId: inviteId,
    );
  }

  UniversalReport _mapReport(Map<String, dynamic> r) {
    var tags = <String>[];
    try {
      final raw = jsonDecode((r['auto_tags_json'] as String?) ?? '[]')
          as List<dynamic>;
      tags = raw.map((e) => e.toString()).toList();
    } catch (_) {}

    var votesCount = 0;
    try {
      final rawV = jsonDecode((r['votes_json'] as String?) ?? '[]') as List<dynamic>;
      votesCount = rawV.length;
    } catch (_) {}

    return UniversalReport(
      id: (r['id'] as String?) ?? '',
      originType: (r['origin_type'] as String?) ?? 'chat',
      entityType: (r['entity_type'] as String?) ?? (r['origin_type'] as String?) ?? 'chat',
      originId: (r['origin_id'] as String?) ?? '',
      targetUserId: r['target_user_id'] as String?,
      reasonCategory: (r['reason_category'] as String?) ?? 'Outros',
      description: (r['description'] as String?) ?? '',
      autoTags: tags,
      status: (r['status'] as String?) ?? 'pending',
      createdAtText: _formatTimeShort(r['created_at'] as String?),
      votesCount: votesCount,
      requiredVotes: 3,
    );
  }

  String _formatHourMinute(String? iso) {
    if (iso == null || iso.isEmpty) return 'agora';
    final parsed = DateTime.tryParse(iso)?.toLocal();
    if (parsed == null) return 'agora';
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formatTimeShort(String? iso) {
    if (iso == null || iso.isEmpty) return 'agora';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return 'agora';
    final diff = DateTime.now().toUtc().difference(parsed.toUtc());
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inHours < 1) return 'ha ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'ha ${diff.inHours}h';
    return 'ha ${diff.inDays}d';
  }
}
