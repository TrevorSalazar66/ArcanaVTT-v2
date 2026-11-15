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
  String baseUrl;
  String? bearerToken;
  final http.Client _httpClient;

  CloudflareEdgeClient({
    this.baseUrl = 'https://arcana-vtt-backend.workers.dev',
    this.bearerToken,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  Future<EdgeResponse> postAuth(Map<String, dynamic> payload) async {
    return _post('/api/auth', payload, authenticated: false);
  }

  Future<EdgeResponse> postSync(Map<String, dynamic> payload) async {
    return _post('/api/sync', payload, authenticated: true);
  }

  Future<EdgeResponse> _post(
    String path,
    Map<String, dynamic> payload, {
    required bool authenticated,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'X-Device-Fingerprint': 'android-keystore-arcana-v1',
      };
      if (authenticated && bearerToken != null && bearerToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $bearerToken';
      }

      final response = await _httpClient
          .post(
            Uri.parse('$baseUrl$path'),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 3));

      final decoded = jsonDecode(response.body);
      final map = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'raw': decoded};

      return EdgeResponse(
        ok: response.statusCode >= 200 && response.statusCode < 300,
        statusCode: response.statusCode,
        data: map,
      );
    } catch (_) {
      // Fallback Offline-First silencioso quando sem rede ou antes do deploy do Worker.
      return const EdgeResponse(
        ok: false,
        statusCode: 0,
        data: {'offline_fallback': true},
      );
    }
  }
}

