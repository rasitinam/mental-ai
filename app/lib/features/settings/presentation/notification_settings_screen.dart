import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/network/error_messages.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/data/profile_api.dart';

/// The hours the reminder can be set to — must match `REMINDER_HOURS` in
/// `backend/apps/server/src/routes/profile.rs`.
const _reminderHours = [17, 18, 19, 20, 21, 22, 23];

String reminderTimeLabel(int hour) => '${hour.toString().padLeft(2, '0')}:00';

/// Ayarlar → Bildirimler: the evening check-in reminder.
///
/// Every change saves immediately — a switch and a row of times don't
/// need a Save button, and a preview of the actual notification sits
/// underneath so there's no guessing what turning it on means.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool? _enabled;
  int? _hour;
  bool _saving = false;

  Future<void> _save({required bool enabled, required int hour}) async {
    final previous = (enabled: _enabled, hour: _hour);
    setState(() {
      _enabled = enabled;
      _hour = hour;
      _saving = true;
    });

    try {
      await ref.read(profileApiProvider).setCheckinReminder(enabled: enabled, hour: hour);
      ref.invalidate(myProfileProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enabled = previous.enabled;
        _hour = previous.hour;
      });
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(l10n, e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final profile = ref.watch(myProfileProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: profile.when(
          loading: () => Center(child: CircularProgressIndicator(color: palette.accent)),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(friendlyErrorMessage(l10n, e), style: TextStyle(color: palette.warning)),
            ),
          ),
          data: (data) {
            final enabled = _enabled ?? data.checkinReminderEnabled;
            final hour = _hour ?? data.checkinReminderHour;

            return ListView(
              padding: EdgeInsets.fromLTRB(22, 12, 22, bottomClearance(context)),
              children: [
                Row(
                  children: [
                    SquareIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 14),
                    Text(l10n.notificationsTitle,
                        style: AppTypography.title3.copyWith(color: palette.textPrimary)),
                    const Spacer(),
                    if (_saving)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: palette.accent),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                GlassSurface(
                  radius: 18,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: palette.accentSoft, shape: BoxShape.circle),
                        child: Icon(Icons.nights_stay_rounded, size: 20, color: palette.accent),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.notificationsCheckinTitle,
                                style: AppTypography.label
                                    .copyWith(color: palette.textPrimary, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(l10n.notificationsCheckinBody,
                                style: AppTypography.footnote
                                    .copyWith(color: palette.textSecondary, height: 1.5)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: enabled,
                        activeThumbColor: palette.accent,
                        onChanged: _saving ? null : (v) => _save(enabled: v, hour: hour),
                      ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: !enabled
                      ? const SizedBox(width: double.infinity)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            SectionLabel(l10n.notificationsTimeLabel),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final option in _reminderHours)
                                  _TimeChip(
                                    label: reminderTimeLabel(option),
                                    selected: option == hour,
                                    palette: palette,
                                    onTap: _saving || option == hour
                                        ? null
                                        : () => _save(enabled: true, hour: option),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 26),
                            SectionLabel(l10n.notificationsPreviewLabel),
                            const SizedBox(height: 10),
                            _NotificationPreview(
                              time: reminderTimeLabel(hour),
                              title: l10n.notificationsPreviewTitle,
                              body: l10n.notificationsPreviewBody,
                              palette: palette,
                            ),
                          ],
                        ),
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.phone_iphone_rounded, size: 18, color: palette.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(l10n.notificationsWebNote,
                              style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final AppPalette palette;
  final VoidCallback? onTap;

  const _TimeChip({required this.label, required this.selected, required this.palette, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? palette.accent : palette.glassFill,
      borderRadius: BorderRadius.circular(100),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: selected ? palette.accent : palette.separator),
          ),
          child: Text(
            label,
            style: AppTypography.label.copyWith(
              color: selected ? Colors.white : palette.textPrimary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

/// A lock-screen style mock of the notification itself.
class _NotificationPreview extends StatelessWidget {
  final String time;
  final String title;
  final String body;
  final AppPalette palette;

  const _NotificationPreview({
    required this.time,
    required this.title,
    required this.body,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: palette.accent, borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.local_fire_department_rounded, size: 19, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('HEARTH',
                        style: AppTypography.caption.copyWith(
                            color: palette.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    const Spacer(),
                    Text(time, style: AppTypography.caption.copyWith(color: palette.textTertiary)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(title,
                    style: AppTypography.label.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(body, style: AppTypography.footnote.copyWith(color: palette.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
