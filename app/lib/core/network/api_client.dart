import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';

/// Thin wrapper around a configured [Dio] instance. Every feature's data
/// layer depends on this provider instead of constructing its own HTTP
/// client, so base URL / interceptors / timeouts are set in exactly one
/// place.
final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
    ),
  );
  return dio;
});
