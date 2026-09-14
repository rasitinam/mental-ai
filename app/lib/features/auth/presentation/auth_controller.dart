import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_prefs.dart';
import '../../../core/l10n/locale_controller.dart';
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

  Future<void> register({required String email, required String password, String? displayName}) async {
    if (!_validate(email, password)) return;
    await _submit(
      () => ref.read(authApiProvider).register(
            email: email,
            password: password,
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
      if (registering) ref.read(justRegisteredProvider.notifier).state = true;
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
