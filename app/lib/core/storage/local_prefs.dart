import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('overridden in main() before runApp');
});

class StoredSession {
  final String userId;
  final String token;
  final DateTime? expiresAt;
  const StoredSession({required this.userId, required this.token, this.expiresAt});
}

StoredSession? readStoredSession(SharedPreferences prefs) {
  final userId = prefs.getString(AppConstants.prefsUserIdKey);
  final token = prefs.getString(AppConstants.prefsSessionTokenKey);
  if (userId == null || token == null) return null;

  final expiresAtRaw = prefs.getString(AppConstants.prefsSessionExpiresAtKey);
  final expiresAt = expiresAtRaw != null ? DateTime.tryParse(expiresAtRaw) : null;

  // A locally-expired session is treated the same as no session — the
  // classic-session behavior the user asked for ("önceden giriş yaptıysa
  // uygulama direkt açılsın") only applies while the token is still good.
  if (expiresAt != null && expiresAt.isBefore(DateTime.now())) return null;

  return StoredSession(userId: userId, token: token, expiresAt: expiresAt);
}

Future<void> saveSession(SharedPreferences prefs, StoredSession session) async {
  await prefs.setString(AppConstants.prefsUserIdKey, session.userId);
  await prefs.setString(AppConstants.prefsSessionTokenKey, session.token);
  if (session.expiresAt != null) {
    await prefs.setString(AppConstants.prefsSessionExpiresAtKey, session.expiresAt!.toIso8601String());
  }
}

Future<void> clearSession(SharedPreferences prefs) async {
  await prefs.remove(AppConstants.prefsUserIdKey);
  await prefs.remove(AppConstants.prefsSessionTokenKey);
  await prefs.remove(AppConstants.prefsSessionExpiresAtKey);
}

/// In-memory copy of the current bearer token. `null` means "not signed
/// in" and is what `app/router.dart`'s redirect logic and
/// `apiClientProvider`'s request interceptor both key off of — set once
/// at startup from the stored session (see `main.dart`), updated on
/// login/register (`AuthController`) and cleared on logout or a 401
/// response (`apiClientProvider`'s response interceptor).
final sessionTokenProvider = StateProvider<String?>((ref) => null);

/// The signed-in account's id, for display only (Settings screen).
/// Actual requests never send this explicitly — the backend derives the
/// user from the bearer token (see `apps/server/src/auth.rs::AuthUser`).
final currentUserIdProvider = Provider<String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return readStoredSession(prefs)?.userId;
});
