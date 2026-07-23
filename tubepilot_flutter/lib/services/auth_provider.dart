import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: AppConfig.googleServerClientId,
  );

  Map<String, dynamic>? _user;
  bool _loading = true;

  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _loading;
  bool get isAdmin => _user?['role'] == 'admin';

  Future<void> loadSession() async {
    _loading = true;
    notifyListeners();
    final token = await StorageService.getAccessToken();
    if (token == null) {
      _loading = false;
      notifyListeners();
      return;
    }
    try {
      final res = await _api.me();
      _user = res['user'];
    } catch (_) {
      await StorageService.clearTokens();
      _user = null;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _saveSessionFromAuthResponse(Map<String, dynamic> res) async {
    await StorageService.setAccessToken(res['accessToken']);
    if (res['refreshToken'] != null) {
      await StorageService.setRefreshToken(res['refreshToken']);
    }
    _user = res['user'];
    notifyListeners();
  }

  Future<void> emailSignup({required String name, required String email, required String password}) async {
    final res = await _api.signup(name: name, email: email, password: password);
    await _saveSessionFromAuthResponse(res);
  }

  Future<void> emailLogin({required String email, required String password}) async {
    final res = await _api.login(email: email, password: password);
    await _saveSessionFromAuthResponse(res);
  }

  /// Real Google Sign-In flow using the google_sign_in plugin, verified
  /// server-side by POST /api/auth/google (same backend endpoint the web app uses).
  Future<void> googleLogin() async {
    try {
      await _googleSignIn.signOut(); // clear any cached account so account picker always shows
      final account = await _googleSignIn.signIn();
      if (account == null) throw Exception('Google sign-in cancelled');

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw Exception('Could not get Google ID token. Check googleServerClientId in config.dart');
      }

      final res = await _api.googleLogin(idToken);
      await _saveSessionFromAuthResponse(res);
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_failed' && (e.message?.contains('10') ?? false)) {
        throw Exception(
            'Google Sign-In setup issue (ApiException 10): the SHA-1 fingerprint or package name registered '
            'in Firebase/Google Cloud doesn\'t match this build. Re-check android/app/build.gradle applicationId, '
            'the SHA-1 in Firebase, and that google-services.json was re-downloaded after adding it.');
      }
      rethrow;
    }
  }

  Future<void> setupUsername({required String username, required String language, String? avatar}) async {
    final res = await _api.setupUsername(username: username, language: language, avatar: avatar);
    _user = res['user'];
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      final res = await _api.me();
      _user = res['user'];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await StorageService.clearTokens();
    _user = null;
    notifyListeners();
  }
}
