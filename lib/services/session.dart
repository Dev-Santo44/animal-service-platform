import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static Map<String, dynamic>? currentUser;

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    currentUser = user;
    await prefs.setString('user_email', user['email'] ?? '');
    await prefs.setString('user_role', user['role'] ?? '');
    if (user['token'] != null) {
      await prefs.setString('jwt_token', user['token']);
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    currentUser = null;
  }

  static Future<bool> isMfaVerified(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('mfa_verified_$email') ?? false;
  }

  static Future<void> setMfaVerified(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mfa_verified_$email', true);
  }

  static Future<void> clearMfaVerified(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mfa_verified_$email');
  }
}
