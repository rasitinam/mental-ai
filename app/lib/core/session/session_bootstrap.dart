import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../features/auth/data/auth_api.dart';
import '../storage/local_prefs.dart';

/// Ensures a signed-in session exists before the app's first frame.
///
/// There is no visible sign-up/login screen yet — on first launch this
/// silently registers a throwaway account (a random local-only email
/// and a strong random password, both meaningless to the person using
/// the app) purely so every request is backed by a real, server-verified
/// account instead of a client-trusted id, closing the hole where anyone
/// could claim to be any user by passing their id. A real login/register
/// UI (so the same account can be reached from another device, or a
/// person can choose their own email) is a natural next step — see
/// docs/ARCHITECTURE.md.
Future<void> ensureSession(ProviderContainer container) async {
  final prefs = container.read(sharedPreferencesProvider);
  final existing = readStoredSession(prefs);
  if (existing != null) {
    container.read(sessionTokenProvider.notifier).state = existing.token;
    return;
  }

  final deviceId = const Uuid().v4();
  final email = 'local-$deviceId@device.mental-ai.local';
  final password = _generateRandomPassword();

  final session = await container.read(authApiProvider).register(email: email, password: password);

  await saveSession(prefs, StoredSession(userId: session.userId, token: session.token));
  container.read(sessionTokenProvider.notifier).state = session.token;
}

String _generateRandomPassword() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
  final random = Random.secure();
  return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
}
