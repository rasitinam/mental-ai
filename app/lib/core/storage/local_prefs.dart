import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('overridden in main() before runApp');
});

/// Resolves (and persists, on first run) the local device's user id.
/// There is no server-side auth in v1 — the app is local-first and the
/// id is only used to namespace a person's own data in the backend's
/// SQLite database.
final currentUserIdProvider = Provider<String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final existing = prefs.getString(AppConstants.prefsUserIdKey);
  if (existing != null) return existing;

  final generated = const Uuid().v4();
  prefs.setString(AppConstants.prefsUserIdKey, generated);
  return generated;
});
