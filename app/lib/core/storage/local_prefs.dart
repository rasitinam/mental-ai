import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('overridden in main() before runApp');
});

class StoredSession {
  final String userId;
  final String token;
  const StoredSession({required this.userId, required this.token});
}

StoredSession? readStoredSession(SharedPreferences prefs) {
  final userId = prefs.getString(AppConstants.prefsUserIdKey);
  final token = prefs.getString(AppConstants.prefsSessionTokenKey);
  if (userId == null || token == null) return null;
  return StoredSession(userId: userId, token: token);
}

Future<void> saveSession(SharedPreferences prefs, StoredSession session) async {
  await prefs.setString(AppConstants.prefsUserIdKey, session.userId);
  await prefs.setString(AppConstants.prefsSessionTokenKey, session.token);
}

Future<void> clearSession(SharedPreferences prefs) async {
  await prefs.remove(AppConstants.prefsUserIdKey);
  await prefs.remove(AppConstants.prefsSessionTokenKey);
}

/// In-memory copy of the current bearer token, set once by
/// `ensureSession()` before the app's first frame (see
/// `core/session/session_bootstrap.dart`) and read synchronously by
/// `apiClientProvider`'s request interceptor on every call. The
/// source of truth is still `SharedPreferences` (`saveSession`) — this
/// just avoids an async read on every single HTTP request.
final sessionTokenProvider = StateProvider<String?>((ref) => null);

/// The signed-in account's id, for display only (Settings screen).
/// Actual requests never send this explicitly — the backend derives the
/// user from the bearer token (see `apps/server/src/auth.rs::AuthUser`).
final currentUserIdProvider = Provider<String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return readStoredSession(prefs)?.userId;
});
