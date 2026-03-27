import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'http://localhost:8000/api/v1';
  static const _keyToken = 'auth_token';
  static const _keyUserId = 'user_id';

  final Dio _dio = Dio(BaseOptions(baseUrl: _baseUrl));

  Future<void> register(String email, String password) async {
    await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
    });
    // 인증 코드 확인 후 세션 저장 (verifyEmail에서 처리)
  }

  Future<void> verifyEmail(String email, String code) async {
    final res = await _dio.post('/auth/verify-email', data: {
      'email': email,
      'code': code,
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

  Future<void> deleteAccount(String password) async {
    final token = await getToken();
    if (token == null) throw Exception('Not logged in');
    await _dio.delete(
      '/auth/me',
      queryParameters: {'password': password},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    await logout();
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
