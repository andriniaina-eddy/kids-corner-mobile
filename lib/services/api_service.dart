import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exception.dart';

/// Point unique de configuration de l'URL du backend.
///
/// - Émulateur Android : 10.0.2.2 pointe vers le "localhost" de la machine hôte.
/// - Appareil physique : remplacez par l'adresse IP locale de votre serveur
///   (ex: http://192.168.1.20:8000/api) ou par l'URL de production.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
}

class ApiService {
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(_uri(path), headers: _headers);
    return _handle(response);
  }

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) async {
    final response = await http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {}));
    return _handle(response);
  }

  Future<Map<String, dynamic>> put(String path, [Map<String, dynamic>? body]) async {
    final response = await http.put(_uri(path), headers: _headers, body: jsonEncode(body ?? {}));
    return _handle(response);
  }

  Future<Map<String, dynamic>> patch(String path, [Map<String, dynamic>? body]) async {
    final response = await http.patch(_uri(path), headers: _headers, body: jsonEncode(body ?? {}));
    return _handle(response);
  }

  /// Envoi multipart pour l'upload de fichiers (ex: photo produit).
  /// Laravel attend une requête POST avec `_method=PUT` en champ caché
  /// quand la route cible est en réalité un PUT, mais ici la route d'upload
  /// est une vraie route POST, donc pas besoin de ce contournement.
  Future<Map<String, dynamic>> postMultipart(String path, String filePath, {String fileField = 'image'}) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll({'Accept': 'application/json', if (_token != null) 'Authorization': 'Bearer $_token'});
    request.files.add(await http.MultipartFile.fromPath(fileField, filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handle(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await http.delete(_uri(path), headers: _headers);
    return _handle(response);
  }

  Map<String, dynamic> _handle(http.Response response) {
    Map<String, dynamic> decoded = {};
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        // Réponse non-JSON (ex: erreur serveur HTML) : on la traite ci-dessous.
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    if (response.statusCode == 401) {
      throw ApiException('Session expirée, merci de vous reconnecter.', statusCode: 401);
    }

    if (response.statusCode == 403) {
      throw ApiException(
        decoded['message'] as String? ?? "Vous n'avez pas accès à cette ressource.",
        statusCode: 403,
      );
    }

    if (response.statusCode == 422) {
      final rawErrors = decoded['errors'] as Map<String, dynamic>? ?? {};
      final errors = rawErrors.map(
        (key, value) => MapEntry(key, (value as List<dynamic>).map((e) => e.toString()).toList()),
      );
      throw ApiException(
        decoded['message'] as String? ?? 'Données invalides.',
        errors: errors,
        statusCode: 422,
      );
    }

    throw ApiException(
      decoded['message'] as String? ?? 'Une erreur est survenue (code ${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }
}
