import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../storage/local_prefs.dart';

/// Thin wrapper around a configured [Dio] instance. Every feature's data
/// layer depends on this provider instead of constructing its own HTTP
/// client, so base URL / interceptors / timeouts are set in exactly one
/// place. The request interceptor attaches the signed-in session's
/// bearer token (if any) to every call — `/auth/register` and
/// `/auth/login` simply ignore it since they run before a session
/// exists.
final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(sessionTokenProvider);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // A 401 on an authenticated call means the session was revoked
        // or expired server-side since it was loaded — clear it so the
        // router's redirect logic takes the user back to /login instead
        // of leaving them stuck on a screen that can never load.
        if (error.response?.statusCode == 401 && ref.read(sessionTokenProvider) != null) {
          ref.read(sessionTokenProvider.notifier).state = null;
          final prefs = ref.read(sharedPreferencesProvider);
          clearSession(prefs);
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
