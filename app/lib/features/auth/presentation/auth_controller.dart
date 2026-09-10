import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_prefs.dart';
import '../../../core/l10n/locale_controller.dart';
import '../data/auth_api.dart';
import '../domain/session.dart';

class AuthState {
  final bool submitting;
  final String? error;
  const AuthState({this.submitting = false, this.error});

  AuthState copyWith({bool? submitting, String? error}) =>
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
    await _submit(() => ref.read(authApiProvider).register(
          email: email,
          password: password,
          displayName: displayName,
          language: ref.read(localeControllerProvider).languageCode,
        ));
    if (state.error == null) {
      ref.read(justRegisteredProvider.notifier).state = true;
    }
  }

  Future<void> login({required String email, required String password}) async {
    if (!_validate(email, password)) return;
    ref.read(justRegisteredProvider.notifier).state = false;
    await _submit(() => ref.read(authApiProvider).login(email: email, password: password));
  }

  bool _validate(String email, String password) {
    if (!email.contains('@') || email.trim().length < 3) {
      state = state.copyWith(error: 'Geçerli bir e-posta adresi gir.');
      return false;
    }
    if (password.length < 8) {
      state = state.copyWith(error: 'Şifre en az 8 karakter olmalı.');
      return false;
    }
    return true;
  }

  Future<void> _submit(Future<Session> Function() action) async {
    state = state.copyWith(submitting: true, error: null);
    try {
      final session = await action();
      final prefs = ref.read(sharedPreferencesProvider);
      await saveSession(prefs, StoredSession(userId: session.userId, token: session.token));
      ref.read(sessionTokenProvider.notifier).state = session.token;
      state = state.copyWith(submitting: false);
    } on DioException catch (e) {
      state = state.copyWith(submitting: false, error: _messageFor(e));
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
    }
  }

  String _messageFor(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) return 'E-posta veya şifre hatalı.';
    if (status == 409) return 'Bu e-posta ile zaten bir hesap var.';
    if (status == 400) return 'Bilgileri kontrol et.';
    return 'Bağlantı hatası: ${e.message ?? 'sunucuya ulaşılamadı'}';
  }
}
