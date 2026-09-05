import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/local_prefs.dart';
import '../../auth/data/auth_api.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authApiProvider).logout();
    } catch (_) {
      // Best-effort: even if the network call fails, clearing the local
      // session still logs the person out of this device.
    }
    final prefs = ref.read(sharedPreferencesProvider);
    await clearSession(prefs);
    ref.read(sessionTokenProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final palette = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
        children: [
          _SettingsGroup(
            title: 'Bağlantı',
            rows: [
              _SettingsRow(icon: Icons.dns_outlined, label: 'Sunucu adresi', value: AppConstants.apiBaseUrl),
              _SettingsRow(icon: Icons.fingerprint_rounded, label: 'Cihaz kimliği', value: userId),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Gizlilik ve Güvenlik',
            rows: const [
              _SettingsRow(
                icon: Icons.lock_outline_rounded,
                label: 'Verilerin nerede duruyor',
                description: 'Yalnızca kendi bilgisayarındaki yerel veritabanında saklanır.',
              ),
              _SettingsRow(
                icon: Icons.shield_outlined,
                label: 'Yasal uyarı',
                description: 'Mental AI lisanslı bir sağlık uzmanının yerini tutmaz. '
                    'Acil bir durumdaysan 112\'yi ara.',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Hesap',
            rows: [
              _SettingsRow(
                icon: Icons.logout_rounded,
                label: 'Çıkış yap',
                iconColor: palette.warning,
                onTap: () => _logout(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingsRow> rows;
  const _SettingsGroup({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.caption.copyWith(color: palette.textTertiary, letterSpacing: 0.6),
          ),
        ),
        GlassSurface(
          radius: 22,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                rows[i],
                if (i != rows.length - 1) Divider(height: 1, indent: 56, color: palette.separator),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String? description;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.value,
    this.description,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: iconColor ?? palette.accent),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.headline.copyWith(color: iconColor ?? palette.textPrimary),
                  ),
                  if (value != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      value!,
                      style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (description != null) ...[
                    const SizedBox(height: 3),
                    Text(description!, style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
