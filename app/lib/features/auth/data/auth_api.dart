import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/session.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));

class AuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  Future<Session> register({
    required String email,
    required String password,
    String? displayName,
    String? language,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'display_name': ?displayName,
      // Sent at sign-up so the very first generated report comes back in
      // the language the app is already showing.
      'language': ?language,
    });
    return Session.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Session> login({required String email, required String password}) async {
    final response = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    return Session.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }
}
