import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/arcana_colors.dart';
import 'cloudflare_edge_client.dart';

/// Persistencia local Offline-First em Keystore/SharedPreferences (sessao 15-30 dias, fingerprint unico, tema, preferências e onboarding).
class LocalStorageDatasource {
  static const String defaultGoogleServerClientId = String.fromEnvironment(
    'ARCANA_GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '411573114471-lf15tft9ps4ethpdlqm0gr0irmr0dgjg.apps.googleusercontent.com',
  );

  static const String defaultGoogleAndroidClientId =
      '411573114471-0fpqopqcgvgrj1moc8vgga04pvmebsmu.apps.googleusercontent.com';

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
  static const _keyAvatarIcon = 'arcana_avatar_icon';
  static const _keyRole = 'arcana_role';
  static const _keyOnboardingCompleted = 'arcana_onboarding_completed';
  static const _keyDeviceFingerprint = 'arcana_device_fingerprint_v1';
  static const _keyGeneralSettingsJson = 'arcana_general_settings_v1';
  static const _keyTrustedDaysRemaining = 'arcana_trusted_days_remaining';

  Future<String> getOrCreateDeviceFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_keyDeviceFingerprint);
    if (existing != null && existing.trim().length >= 8) {
      return existing;
    }
    final rng = Random.secure();
    final hex = List<String>.generate(
      16,
      (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final fp = 'arcana_dev_$hex';
    await prefs.setString(_keyDeviceFingerprint, fp);
    return fp;
  }

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
    await prefs.setDouble(_keyFontScale, scale.clamp(0.85, 1.45));
  }

  Future<double> loadFontScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyFontScale) ?? 1.0;
  }

  Future<void> saveGeneralSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGeneralSettingsJson, jsonEncode(settings));
  }

  Future<Map<String, dynamic>> loadGeneralSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyGeneralSettingsJson);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
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
    String avatarIcon = 'shield',
    bool onboardingCompleted = false,
    int trustedDaysRemaining = 15,
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
    await prefs.setString(_keyAvatarIcon, avatarIcon);
    await prefs.setString(_keyRole, role);
    await prefs.setBool(_keyOnboardingCompleted, onboardingCompleted);
    await prefs.setInt(_keyTrustedDaysRemaining, trustedDaysRemaining);
    if (bearerToken != null) {
      await prefs.setString(_keyBearerToken, bearerToken);
    }
  }

  Future<Map<String, dynamic>> loadSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    final fp = await getOrCreateDeviceFingerprint();
    return {
      'active': prefs.getBool(_keySessionActive) ?? false,
      'trusted': prefs.getBool(_keyTrustedDevice) ?? true,
      'bearerToken': prefs.getString(_keyBearerToken),
      'userId': prefs.getString(_keyUserId) ?? '',
      'email': prefs.getString(_keyEmail) ?? '',
      'username': prefs.getString(_keyUsername) ?? '',
      'displayName': prefs.getString(_keyDisplayName) ?? 'Aventureiro',
      'bio': prefs.getString(_keyBio) ?? '',
      'avatarIcon': prefs.getString(_keyAvatarIcon) ?? 'shield',
      'role': prefs.getString(_keyRole) ?? 'jogador',
      'onboardingCompleted': prefs.getBool(_keyOnboardingCompleted) ?? false,
      'trustedDaysRemaining': prefs.getInt(_keyTrustedDaysRemaining) ?? 15,
      'deviceFingerprint': fp,
      'edgeUrl': CloudflareEdgeClient.defaultBaseUrl,
      'googleClientId': defaultGoogleServerClientId,
    };
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySessionActive, false);
    await prefs.remove(_keyBearerToken);
    await prefs.remove(_keyOnboardingCompleted);
  }
}
