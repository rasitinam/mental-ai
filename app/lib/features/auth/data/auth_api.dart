import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/session.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));

class AuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  /// Emails a 6-digit verification code to [email] — step one of signing up;
  /// the account itself is created by [register] once the code comes back.
  /// Returns how many seconds to wait before another code can be requested.
  Future<int> requestRegisterCode({required String email, String? language}) async {
    final response = await _dio.post('/auth/register/code', data: {
      'email': email,
      'language': ?language,
    });
    final wait = (response.data as Map<String, dynamic>)['resend_after_seconds'];
    return wait is num ? wait.toInt() : 60;
  }

  Future<Session> register({
    required String email,
    required String password,
    required String code,
    String? displayName,
    String? language,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'code': code,
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

  /// Signs in (or creates the account) with a Sign in with Apple identity
  /// token. The backend verifies it against Apple's keys; nothing here is
  /// trusted on its own.
  Future<Session> apple({
    required String identityToken,
    required String nonce,
    String? displayName,
    String? language,
  }) async {
    final response = await _dio.post('/auth/apple', data: {
      'identity_token': identityToken,
      'nonce': nonce,
      'display_name': ?displayName,
      'language': ?language,
    });
    return Session.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }

  /// Permanently deletes the signed-in account and everything it owns.
  /// Requires the current password — a session token alone (which could be
  /// left open on a shared or lost device) isn't enough to authorize
  /// something this irreversible. Throws [DioException] with a 401 for a
  /// wrong password. Accounts created with Sign in with Apple have no
  /// password: they re-verify with a fresh Apple identity token instead.
  Future<void> deleteAccount({
    String? password,
    String? appleIdentityToken,
    String? appleNonce,
  }) async {
    await _dio.delete('/account', data: {
      'password': ?password,
      'apple_identity_token': ?appleIdentityToken,
      'apple_nonce': ?appleNonce,
    });
  }
}
