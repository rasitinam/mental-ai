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
    ),
  );

  return dio;
});
