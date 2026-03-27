import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'http://localhost:8000/api/v1';
  static const _keyToken = 'auth_token';
  static const _keyUserId = 'user_id';

  final Dio _dio = Dio(BaseOptions(baseUrl: _baseUrl));

  Future<void> register(String email, String password) async {
    final res = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
    });
    await _saveSession(res.data);
  }

  Future<void> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    await _saveSession(res.data);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  Future<bool> isLoggedIn() async {
    return (await getToken()) != null;
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, data['access_token']);
    await prefs.setInt(_keyUserId, data['user_id']);
  }
}
