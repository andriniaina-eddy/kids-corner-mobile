import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/api_exception.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;

  AppUser? _user;
  String? _token;
  bool _isLoading = true;

  AuthProvider(this._api) {
    _restoreSession();
  }

  AppUser? get user => _user;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isLoading => _isLoading;

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userJson = prefs.getString('auth_user');

    if (token != null && userJson != null) {
      _token = token;
      _api.setToken(token);
      try {
        _user = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {
        await _clearSession();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final response = await _api.post('/login', {
      'email': email,
      'password': password,
      'device_name': 'android-app',
    });

    _token = response['token'] as String;
    _user = AppUser.fromJson(response['user'] as Map<String, dynamic>);
    _api.setToken(_token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    await prefs.setString('auth_user', jsonEncode(_user!.toJson()));

    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _api.post('/logout');
    } on ApiException {
      // Même si l'appel réseau échoue, on déconnecte localement.
    }
    await _clearSession();
  }

  Future<void> _clearSession() async {
    _token = null;
    _user = null;
    _api.setToken(null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');

    notifyListeners();
  }

  /// Appelé par l'intercepteur d'écran quand l'API renvoie 401 (token expiré/révoqué).
  Future<void> forceLogout() async {
    await _clearSession();
  }
}
