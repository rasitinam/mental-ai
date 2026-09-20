import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Sign in with Apple is offered on iOS only. On Android the plugin needs a
/// web "Services ID" and a redirect page this app doesn't have, and the
/// buttons would be a dead end, so the option isn't shown there at all.
bool get appleSignInSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// What one Apple authorization hands back: the signed identity token the
/// backend verifies, and the *raw* nonce it was bound to (Apple only ever
/// sees the SHA-256 of it — see `AppleKeys::verify` in the backend).
class AppleCredential {
  final String identityToken;
  final String nonce;

  /// Only present on the very first authorization between this app and this
  /// Apple ID; Apple never repeats it.
  final String? displayName;

  const AppleCredential({required this.identityToken, required this.nonce, this.displayName});
}

String _randomNonce([int length = 32]) {
  final random = Random.secure();
  return base64UrlEncode(List<int>.generate(length, (_) => random.nextInt(256))).replaceAll('=', '');
}

/// Shows the native Apple sheet. Returns `null` when the person dismisses it
/// (not an error worth showing); throws for anything else.
Future<AppleCredential?> requestAppleCredential() async {
  final rawNonce = _randomNonce();
  try {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
    );
    final token = credential.identityToken;
    if (token == null) throw StateError('Apple returned no identity token');

    final name = [credential.givenName, credential.familyName]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(' ');
    return AppleCredential(
      identityToken: token,
      nonce: rawNonce,
      displayName: name.isEmpty ? null : name,
    );
  } on SignInWithAppleAuthorizationException catch (e) {
    if (e.code == AuthorizationErrorCode.canceled) return null;
    rethrow;
  }
}
