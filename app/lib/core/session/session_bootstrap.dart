import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_prefs.dart';

/// Loads whatever session is already on disk into [sessionTokenProvider]
/// before the first frame — purely local, no network call, so it can't
/// block startup on connectivity. This is the "classic session" half of
/// the login flow: if a valid (non-expired) token is already stored, the
/// router's redirect logic sends the user straight past `/login`; if
/// not, they land on it. Registering/logging in is handled entirely by
/// `features/auth/presentation/auth_controller.dart`.
void loadStoredSession(ProviderContainer container) {
  final prefs = container.read(sharedPreferencesProvider);
  final existing = readStoredSession(prefs);
  if (existing != null) {
    container.read(sessionTokenProvider.notifier).state = existing.token;
  }
}
