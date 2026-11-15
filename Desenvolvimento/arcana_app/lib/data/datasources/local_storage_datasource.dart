import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/arcana_colors.dart';

/// Persistência local Offline-First em Keystore/SharedPreferences (sessão 15–30 dias, tema e escala).
class LocalStorageDatasource {
  static const _keyTheme = 'arcana_theme_mode';
  static const _keyFontScale = 'arcana_font_scale';
  static const _keyTrustedDevice = 'arcana_trusted_device';
  static const _keySessionActive = 'arcana_session_active';
  static const _keyUsername = 'arcana_username';
  static const _keyDisplayName = 'arcana_display_name';
  static const _keyEdgeUrl = 'arcana_edge_url';

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
    required String username,
    required String displayName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySessionActive, active);
    await prefs.setBool(_keyTrustedDevice, trustedDevice);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyDisplayName, displayName);
  }

  Future<Map<String, dynamic>> loadSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'active': prefs.getBool(_keySessionActive) ?? false,
      'trusted': prefs.getBool(_keyTrustedDevice) ?? true,
      'username': prefs.getString(_keyUsername) ?? 'valen_bard',
      'displayName': prefs.getString(_keyDisplayName) ?? 'Valen Voss',
      'edgeUrl': prefs.getString(_keyEdgeUrl) ?? 'https://arcana-vtt-backend.workers.dev',
    };
  }

  Future<void> saveEdgeUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEdgeUrl, url);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySessionActive, false);
  }
}

