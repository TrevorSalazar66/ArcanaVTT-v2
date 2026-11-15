import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/arcana_colors.dart';
import 'cloudflare_edge_client.dart';

/// Persistência local Offline-First em Keystore/SharedPreferences (sessão 15–30 dias, tema, escala e endpoint edge).
class LocalStorageDatasource {
  static const String defaultGoogleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static const _keyTheme = 'arcana_theme_mode';
  static const _keyFontScale = 'arcana_font_scale';
  static const _keyTrustedDevice = 'arcana_trusted_device';
  static const _keySessionActive = 'arcana_session_active';
  static const _keyBearerToken = 'arcana_bearer_token';
  static const _keyUserId = 'arcana_user_id';
  static const _keyEmail = 'arcana_email';
  static const _keyUsername = 'arcana_username';
  static const _keyDisplayName = 'arcana_display_name';
  static const _keyBio = 'arcana_bio';
  static const _keyRole = 'arcana_role';
  static const _keyEdgeUrl = 'arcana_edge_url';
  static const _keyGoogleClientId = 'arcana_google_client_id';

  Future<void> saveTheme(ArcanaThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, mode.wireKey);
  }

  Future<ArcanaThemeMode> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTheme);
    switch (raw) {
      case 'oled':
        return ArcanaThemeMode.oled;
      case 'alto_contraste_solar':
        return ArcanaThemeMode.altoContrasteSolar;
      default:
        return ArcanaThemeMode.escuroHeraldico;
    }
  }

  Future<void> saveFontScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontScale, scale.clamp(0.8, 1.5));
  }

  Future<double> loadFontScale() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getDouble(_keyFontScale) ?? 1.0).clamp(0.8, 1.5);
  }

  Future<void> saveSessionState({
    required bool active,
    required bool trustedDevice,
    required String userId,
    required String email,
    required String username,
    required String displayName,
    required String bio,
    required String role,
    String? bearerToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySessionActive, active);
    await prefs.setBool(_keyTrustedDevice, trustedDevice);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyDisplayName, displayName);
    await prefs.setString(_keyBio, bio);
    await prefs.setString(_keyRole, role);
    if (bearerToken != null) {
      await prefs.setString(_keyBearerToken, bearerToken);
    }
  }

  Future<Map<String, dynamic>> loadSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'active': prefs.getBool(_keySessionActive) ?? false,
      'trusted': prefs.getBool(_keyTrustedDevice) ?? true,
      'bearerToken': prefs.getString(_keyBearerToken),
      'userId': prefs.getString(_keyUserId) ?? '',
      'email': prefs.getString(_keyEmail) ?? '',
      'username': prefs.getString(_keyUsername) ?? '',
      'displayName': prefs.getString(_keyDisplayName) ?? 'Aventureiro',
      'bio': prefs.getString(_keyBio) ?? '',
      'role': prefs.getString(_keyRole) ?? 'mestre',
      'edgeUrl': prefs.getString(_keyEdgeUrl) ?? CloudflareEdgeClient.defaultBaseUrl,
      'googleClientId':
          prefs.getString(_keyGoogleClientId) ?? defaultGoogleServerClientId,
    };
  }

  Future<void> saveEdgeUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEdgeUrl, url.trim());
  }

  Future<void> saveGoogleClientId(String clientId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGoogleClientId, clientId.trim());
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySessionActive, false);
    await prefs.remove(_keyBearerToken);
  }
}

