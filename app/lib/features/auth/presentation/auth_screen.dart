import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import 'auth_controller.dart';

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (_isRegister) {
      ref.read(authControllerProvider.notifier).register(email: email, password: password);
    } else {
      ref.read(authControllerProvider.notifier).login(email: email, password: password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(20)),
                  alignment: Alignment.center,
                  child: Icon(Icons.self_improvement_rounded, size: 32, color: palette.accent),
                ),
                const SizedBox(height: 24),
                Text('Mental AI', style: AppTypography.largeTitle.copyWith(color: palette.textPrimary)),
                const SizedBox(height: 8),
                Text(
                  _isRegister ? 'Hesabını oluştur' : 'Hesabına giriş yap',
                  style: AppTypography.body.copyWith(color: palette.textSecondary),
                ),
                const SizedBox(height: 28),
                GlassSurface(
                  radius: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AuthField(
                        controller: _emailController,
                        label: 'E-posta',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _AuthField(
                        controller: _passwordController,
                        label: 'Şifre (en az 8 karakter)',
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
                if (_isRegister) ...[
                  const SizedBox(height: 14),
                  GlassSurface(
                    radius: 20,
                    blurSigma: 18,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: palette.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Mental AI lisanslı bir psikolog, psikiyatrist ya da tıbbi bir '
                            'cihaz değildir; tanı koymaz. Kriz anında lütfen 112\'yi veya '
                            'bir uzmanı ara.',
                            style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (state.error != null) ...[
                  const SizedBox(height: 14),
                  Text(state.error!, style: TextStyle(color: palette.warning), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 20),
                AppPrimaryButton(
                  label: _isRegister ? 'Hesap oluştur' : 'Giriş yap',
                  loading: state.submitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: state.submitting
                      ? null
                      : () {
                          setState(() => _isRegister = !_isRegister);
                          ref.read(authControllerProvider.notifier).clearError();
                        },
                  child: Text(
                    _isRegister ? 'Zaten hesabın var mı? Giriş yap' : 'Hesabın yok mu? Kayıt ol',
                    style: AppTypography.subheadline.copyWith(color: palette.accent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: palette.textTertiary),
        const SizedBox(width: 10),
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
              border: InputBorder.none,
              hintText: label,
              hintStyle: AppTypography.body.copyWith(color: palette.textTertiary),
            ),
          ),
        ),
      ],
    );
  }
}
