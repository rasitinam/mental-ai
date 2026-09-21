import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_prefs.dart';
import '../../../core/l10n/locale_controller.dart';
import '../data/apple_sign_in.dart';
import '../data/auth_api.dart';
import '../domain/session.dart';

class AuthState {
  final bool submitting;
  /// A `DioException` (classified and localized for display by
  /// `auth_screen.dart`'s `authErrorMessage`), or a plain already-worded
  /// `String` for the local validation checks in `_validate` below —
  /// `friendlyErrorMessage` passes a `String` through unchanged, so both
  /// shapes render correctly without this needing to know which one it has.
  final Object? error;
  const AuthState({this.submitting = false, this.error});

  AuthState copyWith({bool? submitting, Object? error}) =>
      AuthState(submitting: submitting ?? this.submitting, error: error);
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

/// True for the one moment between a successful registration and the
/// onboarding flow it routes into (see `app/router.dart`) — cleared the
/// instant that flow finishes or is skipped. `login()` resets it up front
/// so a stale `true` from an earlier registration attempt can never leak
/// into a plain sign-in.
final justRegisteredProvider = StateProvider<bool>((ref) => false);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  void clearError() => state = state.copyWith(error: null);

  /// Step one of signing up: checks the form and emails a 6-digit code to
  /// [email]. Returns the seconds to wait before another code can be
  /// requested, or null when it did not go out (the reason is in
  /// `state.error`).
  Future<int?> sendRegisterCode({required String email, required String password}) async {
    if (!_validate(email, password)) return null;
    state = state.copyWith(submitting: true, error: null);
    try {
      final wait = await ref.read(authApiProvider).requestRegisterCode(
            email: email,
            language: ref.read(localeControllerProvider).languageCode,
          );
      state = state.copyWith(submitting: false);
      return wait;
    } catch (e) {
      state = state.copyWith(submitting: false, error: e);
      return null;
    }
  }

  /// Step two: creates the account with the code that was emailed.
  Future<void> register({
    required String email,
    required String password,
    required String code,
    String? displayName,
  }) async {
    if (!_validate(email, password)) return;
    await _submit(
      () => ref.read(authApiProvider).register(
            email: email,
            password: password,
            code: code,
            displayName: displayName,
            language: ref.read(localeControllerProvider).languageCode,
          ),
      registering: true,
    );
  }

  Future<void> login({required String email, required String password}) async {
    if (!_validate(email, password)) return;
    ref.read(justRegisteredProvider.notifier).state = false;
    await _submit(() => ref.read(authApiProvider).login(email: email, password: password));
  }

  /// Native Apple sheet, then the backend verifies the token it returns.
  /// Dismissing the sheet is not an error — nothing changes on screen.
  Future<void> signInWithApple() async {
    ref.read(justRegisteredProvider.notifier).state = false;
    state = state.copyWith(submitting: true, error: null);

    final AppleCredential? credential;
    try {
      credential = await requestAppleCredential();
    } catch (e) {
      state = state.copyWith(submitting: false, error: e);
      return;
    }
    if (credential == null) {
      state = state.copyWith(submitting: false);
      return;
    }

    await _submit(
      () => ref.read(authApiProvider).apple(
            identityToken: credential!.identityToken,
            nonce: credential.nonce,
            displayName: credential.displayName,
            language: ref.read(localeControllerProvider).languageCode,
          ),
    );
  }

  bool _validate(String email, String password) {
    final tr = ref.read(localeControllerProvider).languageCode != 'en';
    if (!email.contains('@') || email.trim().length < 3) {
      state = state.copyWith(
        error: tr ? 'Geçerli bir e-posta adresi gir.' : 'Enter a valid email address.',
      );
      return false;
    }
    if (password.length < 8) {
      state = state.copyWith(
        error: tr ? 'Şifre en az 8 karakter olmalı.' : 'Password must be at least 8 characters.',
      );
      return false;
    }
    return true;
  }

  Future<void> _submit(Future<Session> Function() action, {bool registering = false}) async {
    state = state.copyWith(submitting: true, error: null);
    try {
      final session = await action();
      final prefs = ref.read(sharedPreferencesProvider);
      await saveSession(prefs, StoredSession(userId: session.userId, token: session.token));
      // Strictly before the token: publishing the token is what makes the
      // router leave `/login`, and it reads `justRegistered` in the same
      // pass to decide between the app and the onboarding flow. Set
      // afterwards (as it used to be), a new account was first routed into
      // the app and only bounced into onboarding on a second redirect —
      // one extra frame of the wrong screen, and one more ordering
      // assumption than this needs to rest on.
      if (registering || session.isNewAccount) ref.read(justRegisteredProvider.notifier).state = true;
      ref.read(sessionTokenProvider.notifier).state = session.token;
      state = state.copyWith(submitting: false);
    } catch (e) {
      // Stored raw (a `DioException`, or whatever else went wrong) rather
      // than stringified here — `auth_screen.dart`'s `authErrorMessage`
      // classifies 401/409/400 into "wrong password" / "email taken" /
      // "check your details" at display time, in whatever language the
      // interface is currently showing.
      state = state.copyWith(submitting: false, error: e);
    }
  }
}
