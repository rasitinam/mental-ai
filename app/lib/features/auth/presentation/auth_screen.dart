import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/l10n/language_switch.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/network/error_messages.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_controller.dart';

/// Classifies the login/register-specific status codes into what they
/// actually mean in this one context — a 401 here is "wrong password",
/// not the generic "something went wrong" [friendlyErrorMessage] would
/// give it, since it doesn't know it's looking at a login attempt.
/// Everything else (network trouble, server errors, the plain validation
/// strings `AuthController._validate` sets directly) falls through to the
/// shared classifier.
String authErrorMessage(AppLocalizations l10n, Object error) {
  if (error is DioException && error.type == DioExceptionType.badResponse) {
    switch (error.response?.statusCode) {
      case 401:
        return l10n.authErrorWrongCredentials;
      case 409:
        return l10n.authErrorEmailTaken;
      case 400:
        return l10n.authErrorCheckDetails;
    }
  }
  return friendlyErrorMessage(l10n, error);
}

/// The app's one auth surface — a login form by default, toggling in
/// place to a register form rather than routing to a second screen
/// (there's no state worth preserving across the switch). Router-level
/// redirect logic (see `app/router.dart`) sends anyone without a valid
/// session here and away from here the moment one exists — this screen
/// itself doesn't navigate on success, it just triggers that.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isRegister = false;
  bool _showPassword = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (_isRegister) {
      final name = _displayNameController.text.trim();
      ref.read(authControllerProvider.notifier).register(
            email: email,
            password: password,
            displayName: name.isEmpty ? null : name,
          );
    } else {
      ref.read(authControllerProvider.notifier).login(email: email, password: password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final state = ref.watch(authControllerProvider);
    final language = ref.watch(localeControllerProvider).languageCode;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 40, 26, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
              // IntrinsicHeight gives the column a definite height inside a
              // scroll view, which is what lets the disclaimer sit at the
              // bottom via Spacer without unbounded-height errors.
              child: IntrinsicHeight(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(color: palette.accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        'Hearth',
                        style: AppTypography.label.copyWith(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.28,
                        ),
                      ),
                      const Spacer(),
                      LanguageSwitch(
                        selected: language,
                        onChanged: (code) => ref.read(localeControllerProvider.notifier).setLanguage(code),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    _isRegister ? l10n.authRegisterTitle : l10n.authWelcomeBack,
                    style: AppTypography.largeTitle.copyWith(color: palette.textPrimary),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _isRegister ? l10n.authRegisterNote : l10n.authWelcomeNote,
                    style: AppTypography.subheadline.copyWith(color: palette.textSecondary),
                  ),
                  const SizedBox(height: 26),
                  if (_isRegister) ...[
                    _FieldLabel(text: l10n.authDisplayNameLabel, palette: palette),
                    const SizedBox(height: 6),
                    _AuthField(
                      controller: _displayNameController,
                      palette: palette,
                      hint: l10n.authDisplayNameHint,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _FieldLabel(text: l10n.profileEmail, palette: palette),
                  const SizedBox(height: 6),
                  _AuthField(
                    controller: _emailController,
                    palette: palette,
                    keyboardType: TextInputType.emailAddress,
                    hint: 'ornek@eposta.com',
                  ),
                  const SizedBox(height: 12),
                  _FieldLabel(text: l10n.authPasswordLabel, palette: palette),
                  const SizedBox(height: 6),
                  _AuthField(
                    controller: _passwordController,
                    palette: palette,
                    obscureText: !_showPassword,
                    onSubmitted: (_) => _submit(),
                    trailing: InkWell(
                      onTap: () => setState(() => _showPassword = !_showPassword),
                      child: Text(
                        _showPassword ? l10n.authHidePassword : l10n.authShowPassword,
                        style: AppTypography.footnote
                            .copyWith(color: palette.accent, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.authPasswordRule,
                      style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
                  if (state.error != null) ...[
                    const SizedBox(height: 14),
                    Text(authErrorMessage(l10n, state.error!),
                        style: TextStyle(color: palette.warning), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 26),
                  AppPrimaryButton(
                    label: _isRegister ? l10n.authRegisterCta : l10n.authLoginCta,
                    loading: state.submitting,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: InkWell(
                      onTap: state.submitting
                          ? null
                          : () {
                              setState(() => _isRegister = !_isRegister);
                              ref.read(authControllerProvider.notifier).clearError();
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text.rich(
                          TextSpan(
                            style: AppTypography.subheadline
                                .copyWith(color: palette.textSecondary),
                            children: [
                              TextSpan(
                                  text: _isRegister
                                      ? '${l10n.authHaveAccount} '
                                      : '${l10n.authNoAccount} '),
                              TextSpan(
                                text: _isRegister ? l10n.authLoginCta : l10n.authRegisterCta,
                                style: TextStyle(
                                    color: palette.accent, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: palette.warning, width: 2),
                          ),
                          child: Text(
                            '!',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              color: palette.warning,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.authDisclaimer,
                            style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final AppPalette palette;
  const _FieldLabel({required this.text, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.footnote
          .copyWith(color: palette.textSecondary, fontWeight: FontWeight.w500, fontSize: 12),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final AppPalette palette;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;
  final String? hint;

  const _AuthField({
    required this.controller,
    required this.palette,
    this.obscureText = false,
    this.keyboardType,
    this.onSubmitted,
    this.trailing,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: palette.glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.separator),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              onSubmitted: onSubmitted,
              style: AppTypography.body.copyWith(color: palette.textPrimary),
              cursorColor: palette.accent,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppTypography.body.copyWith(color: palette.textTertiary),
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}
