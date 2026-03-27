import 'package:dio/dio.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:8000/api/v1';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  // 항공권 검색
  Future<Map<String, dynamic>> searchFlights({
    required String origin,
    required String destination,
    required List<String> departDates,
    required List<String> returnDates,
    int adults = 1,
    String currency = 'KRW',
  }) async {
    final response = await _dio.post('/flights/search', data: {
      'origin': origin,
      'destination': destination,
      'depart_dates': departDates,
      'return_dates': returnDates,
      'adults': adults,
      'currency': currency,
    });
    return response.data;
  }

  // 모니터링 노선 등록
  Future<Map<String, dynamic>> addWatch({
    required int userId,
    required String origin,
    required String destination,
    required String departMonth,
    double alertThreshold = 10.0,
  }) async {
    final response = await _dio.post('/watch/', data: {
      'user_id': userId,
      'origin': origin,
      'destination': destination,
      'depart_month': departMonth,
      'alert_threshold': alertThreshold,
    });
    return response.data;
  }

  // 모니터링 노선 목록
  Future<List<dynamic>> getWatches(int userId) async {
    final response = await _dio.get('/watch/user/$userId');
    return response.data;
  }

  // 모니터링 노선 삭제
  Future<void> deleteWatch(int routeId) async {
    await _dio.delete('/watch/$routeId');
  }
}
