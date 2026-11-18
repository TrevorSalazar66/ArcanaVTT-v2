import 'dart:convert';
import 'package:http/http.dart' as http;

class EdgeResponse {
  final bool ok;
  final int statusCode;
  final Map<String, dynamic> data;

  const EdgeResponse({
    required this.ok,
    required this.statusCode,
    required this.data,
  });
}

/// Cliente HTTP oficial para comunicação Zero-Trust com o Cloudflare Worker (`/api/auth` e `/api/sync`).
class CloudflareEdgeClient {
  static const String defaultBaseUrl = String.fromEnvironment(
    'ARCANA_EDGE_URL',
    defaultValue: 'https://arcana-vtt-backend.testgamingdev.workers.dev',
  );

  String baseUrl;
  String? bearerToken;
  final http.Client _httpClient;

  CloudflareEdgeClient({
    String? baseUrl,
    this.bearerToken,
    http.Client? httpClient,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        _httpClient = httpClient ?? http.Client();

  Future<EdgeResponse> postAuth(Map<String, dynamic> payload) async {
    return _post('/api/auth', payload, authenticated: false);
  }

  Future<EdgeResponse> postSync(Map<String, dynamic> payload) async {
    return _post('/api/sync', payload, authenticated: true);
  }

  Future<EdgeResponse> checkHealth() async {
    try {
      final cleanBase = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
      final response = await _httpClient
          .get(Uri.parse('$cleanBase/api/health'))
          .timeout(const Duration(seconds: 8));
      final decoded = jsonDecode(response.body);
      final map = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'raw': decoded};
      return EdgeResponse(
        ok: response.statusCode >= 200 && response.statusCode < 300,
        statusCode: response.statusCode,
        data: map,
      );
    } catch (e) {
      return EdgeResponse(
        ok: false,
        statusCode: 0,
        data: {'offline_fallback': true, 'error': e.toString()},
      );
    }
  }

  Future<EdgeResponse> _post(
    String path,
    Map<String, dynamic> payload, {
    required bool authenticated,
  }) async {
    try {
      final cleanBase = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'X-Device-Fingerprint': 'android-keystore-arcana-v1',
      };
      if (authenticated && bearerToken != null && bearerToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $bearerToken';
      }

      final response = await _httpClient
          .post(
            Uri.parse('$cleanBase$path'),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      Map<String, dynamic> map;
      try {
        final decoded = jsonDecode(response.body);
        map = decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{'raw': decoded};
      } catch (_) {
        map = {'raw': response.body};
      }

      return EdgeResponse(
        ok: response.statusCode >= 200 && response.statusCode < 300,
        statusCode: response.statusCode,
        data: map,
      );
    } catch (e) {
      return EdgeResponse(
        ok: false,
        statusCode: 0,
        data: {
          'offline_fallback': true,
          'error': e.toString(),
        },
      );
    }
  }
}

