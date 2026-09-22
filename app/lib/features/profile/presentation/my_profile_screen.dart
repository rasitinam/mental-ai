import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/settings_jump.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/components.dart';
import '../../../app/theme/glass.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/network/error_messages.dart';
import '../../../core/storage/local_prefs.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/apple_sign_in.dart';
import '../../auth/data/auth_api.dart';
import '../../notifications/push_service.dart';
import '../../settings/presentation/notification_settings_screen.dart' show reminderTimeLabel;
import '../../social/data/social_api.dart';
import '../../stories/presentation/moderation_controller.dart';
import '../../stories/presentation/stories_controller.dart';
import '../../stories/presentation/story_detail_screen.dart';
import '../../stories/presentation/story_grid_tile.dart';
import '../../stories/presentation/story_submit_screen.dart';
import '../data/profile_api.dart';
import '../domain/user_profile.dart';
import 'profile_controller.dart';

/// Ben — the profile and every setting, in one scrolling page. Nothing
/// sits behind a gear icon: the reminder switch, chat and message
/// preferences, appearance, Hearth Plus and moderation are all rows here.
class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  /// The switch's position while its save is in flight.
  bool? _reminderOverride;

  /// Where the settings start, for the Ayarlar buttons on this tab and on
  /// Bugün.
  final _settingsKey = GlobalKey();
  int _handledSettingsJump = 0;

  void _jumpToSettings() {
    final target = _settingsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
  }

  @override
  void initState() {
    super.initState();
    // fireImmediately covers the tap on Bugün that builds this tab for the
    // first time: the counter is already bumped by then.
    ref.listenManual(settingsJumpProvider, (_, next) {
      if (next <= _handledSettingsJump) return;
      _handledSettingsJump = next;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _jumpToSettings();
      });
    }, fireImmediately: true);
    // A story withdrawn or edited elsewhere shows up the next time this tab
    // opens, not on a stale first load.
    Future.microtask(() => ref.read(storiesControllerProvider.notifier).loadMine());
  }

  Future<void> _setReminder(bool enabled, int hour) async {
    setState(() => _reminderOverride = enabled);
    try {
      await ref.read(profileApiProvider).setCheckinReminder(enabled: enabled, hour: hour);
      ref.invalidate(myProfileProvider);
      await ref.read(myProfileProvider.future);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(l10n, e))));
      }
    } finally {
      if (mounted) setState(() => _reminderOverride = null);
    }
  }

  Future<void> _logout() async {
    // Before the session goes away — unregistering needs the token that's
    // about to be cleared, or this device keeps getting pushes for an
    // account no longer signed in on it.
    if (!kIsWeb) {
      try {
        await ref.read(pushServiceProvider).unregister();
      } catch (_) {
        // A push service that can't be reached must not keep someone signed in.
      }
    }
    try {
      await ref.read(authApiProvider).logout();
    } catch (_) {
      // Best-effort: clearing the local session still logs this device out.
    }
    final prefs = ref.read(sharedPreferencesProvider);
    await clearSession(prefs);
    ref.read(sessionTokenProvider.notifier).state = null;
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final passwordController = TextEditingController();
    // Accounts created with Sign in with Apple have no password to type:
    // they confirm by signing in with Apple again, right here.
    final usesApple = ref.read(myProfileProvider).valueOrNull?.signsInWithApple ?? false;

    final deleted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        String? error;
        var busy = false;

        return StatefulBuilder(
          builder: (dialogContext, setState) {
            Future<void> confirm() async {
              setState(() {
                busy = true;
                error = null;
              });
              try {
                if (usesApple) {
                  final credential = await requestAppleCredential();
                  if (credential == null) {
                    // Dismissed the Apple sheet: nothing was confirmed.
                    setState(() => busy = false);
                    return;
                  }
                  await ref.read(authApiProvider).deleteAccount(
                        appleIdentityToken: credential.identityToken,
                        appleNonce: credential.nonce,
                      );
                } else {
                  await ref.read(authApiProvider).deleteAccount(password: passwordController.text);
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } on DioException catch (e) {
                setState(() {
                  busy = false;
                  error = e.response?.statusCode == 401
                      ? (usesApple ? l10n.authErrorApple : l10n.deleteAccountWrongPassword)
                      : l10n.commonError;
                });
              } catch (_) {
                setState(() {
                  busy = false;
                  error = usesApple ? l10n.authErrorApple : l10n.commonError;
                });
              }
            }

            return AlertDialog(
              title: Text(l10n.deleteAccountTitle, style: AppTypography.headline.copyWith(color: palette.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.deleteAccountBody, style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
                  const SizedBox(height: 14),
                  if (usesApple) ...[
                    Text(l10n.deleteAccountAppleNote,
                        style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(error!, style: AppTypography.footnote.copyWith(color: palette.warning)),
                    ],
                  ] else
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      onChanged: (_) => setState(() {}),
                      style: AppTypography.body.copyWith(color: palette.textPrimary),
                      decoration: InputDecoration(
                        hintText: l10n.deleteAccountPasswordHint,
                        hintStyle: AppTypography.body.copyWith(color: palette.textTertiary),
                        errorText: error,
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: busy ? null : () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.commonCancel),
                ),
                TextButton(
                  onPressed: busy || (!usesApple && passwordController.text.isEmpty) ? null : confirm,
                  child: Text(l10n.deleteAccountConfirm, style: TextStyle(color: palette.warning)),
                ),
              ],
            );
          },
        );
      },
    );
    if (deleted != true || !mounted) return;

    // Queued before the token clears, on this still-current screen, rather
    // than racing the redirect to the login screen.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.deleteAccountDone)));

    final prefs = ref.read(sharedPreferencesProvider);
    await clearSession(prefs);
    ref.read(sessionTokenProvider.notifier).state = null;
  }

  void _showInfo(String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final palette = AppPalette.of(sheetContext);
        final l10n = AppLocalizations.of(sheetContext)!;
        return SheetFrame(
          children: [
            Text(title, style: AppTypography.title3.copyWith(color: palette.textPrimary)),
            const SizedBox(height: 10),
            Text(body, style: AppTypography.body.copyWith(color: palette.textSecondary)),
            const SizedBox(height: 20),
            AppPrimaryButton(label: l10n.commonClose, onPressed: () => Navigator.of(sheetContext).pop()),
          ],
        );
      },
    );
  }

  String? _memberLine(AppLocalizations l10n, UserProfile? profile) {
    final created = profile?.createdAt?.toLocal();
    if (created == null) return profile?.email;
    final now = DateTime.now();
    var months = (now.year - created.year) * 12 + now.month - created.month;
    if (now.day < created.day) months--;
    return months < 1 ? l10n.meMemberNew : l10n.meMemberMonths(months);
  }

  /// Switches the interface right away and stores the choice on the
  /// account, which reports and chat replies are written in. A failed save
  /// puts the old language back (see `ProfileController.savePreferences`)
  /// and says why.
  Future<void> _setLanguage(String code) async {
    if (code == ref.read(localeControllerProvider).languageCode) return;

    final controller = ref.read(profileControllerProvider.notifier);
    await controller.savePreferences(language: code);
    if (!mounted) return;

    final error = ref.read(profileControllerProvider).error;
    if (error != null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(l10n, error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final myUserId = ref.watch(currentUserIdProvider);
    final profile = ref.watch(myProfileProvider);
    final data = profile.valueOrNull;
    final avatar = ref.watch(avatarBytesProvider);
    final stats = myUserId == null ? null : ref.watch(publicProfileProvider(myUserId)).valueOrNull;
    final stories = ref.watch(storiesControllerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final isAdmin = data?.isAdmin ?? false;
    final moderation = isAdmin ? ref.watch(moderationControllerProvider) : null;

    final reminderOn = _reminderOverride ?? data?.checkinReminderEnabled ?? false;
    final reminderHour = data?.checkinReminderHour ?? 21;
    final initial = (data?.displayName.trim().isNotEmpty ?? false) ? data!.displayName.trim().characters.first.toUpperCase() : '';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          // Builds the whole page up front, so the Ayarlar button can
          // scroll to a section that hasn't been on screen yet.
          scrollCacheExtent: const ScrollCacheExtent.pixels(100000),
          padding: EdgeInsets.fromLTRB(22, 10, 22, bottomClearance(context)),
          children: [
            Row(
              children: [
                Expanded(child: Text(l10n.navMe, style: AppTypography.title2.copyWith(color: palette.textPrimary))),
                PillButton(icon: Icons.settings_outlined, label: l10n.settingsTitle, onTap: _jumpToSettings),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Semantics(
                  button: true,
                  label: l10n.myProfileEdit,
                  child: GestureDetector(
                    onTap: () => context.push('/settings/profile'),
                    child: Container(
                      width: 76,
                      height: 76,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: palette.lilac),
                      alignment: Alignment.center,
                      child: avatar.when(
                        data: (bytes) => bytes != null
                            ? Image.memory(bytes, fit: BoxFit.cover, width: 76, height: 76)
                            : Text(initial, style: AppTypography.title1.copyWith(color: palette.onTint, fontSize: 34)),
                        loading: () => const SkeletonBox(width: 76, height: 76, radius: 38),
                        error: (_, _) => Text(initial, style: AppTypography.title1.copyWith(color: palette.onTint, fontSize: 34)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: profile.when(
                    data: (p) {
                      final line = _memberLine(l10n, p);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.displayName, style: AppTypography.title3.copyWith(color: palette.textPrimary, fontSize: 23)),
                          if (line != null) ...[
                            const SizedBox(height: 2),
                            Text(line,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.subheadline.copyWith(color: palette.textSecondary, fontSize: 14.5)),
                          ],
                        ],
                      );
                    },
                    loading: () => const SkeletonBox(width: 140, height: 22, radius: 6),
                    error: (_, _) => Text(l10n.commonError, style: TextStyle(color: palette.warning)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _StatCard(value: stats?.storyCount, label: l10n.profileStatStories, onTap: () => context.push('/settings/my-stories')),
                const SizedBox(width: 8),
                _StatCard(
                  value: stats?.followerCount,
                  label: l10n.profileStatFollowers,
                  onTap: myUserId == null ? null : () => context.push('/users/$myUserId/followers'),
                ),
                const SizedBox(width: 8),
                _StatCard(
                  value: stats?.followingCount,
                  label: l10n.profileStatFollowing,
                  onTap: myUserId == null ? null : () => context.push('/users/$myUserId/following'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            OutlineBlockButton(
              icon: Icons.edit_outlined,
              label: l10n.myProfileEdit,
              height: 48,
              onTap: () => context.push('/settings/profile'),
            ),
            const SizedBox(height: 30),
            SectionHeader(
              title: l10n.myProfileStories,
              action: l10n.discoveriesSeeAll,
              onAction: () => context.push('/settings/my-stories'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: i == 0
                          ? AddStoryTile(
                              palette: palette,
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StorySubmitScreen())),
                            )
                          : stories.loadingMine
                              ? const SkeletonBox(radius: 18, height: double.infinity)
                              : i - 1 < stories.mine.length
                                  ? StoryGridTile(
                                      story: stories.mine[i - 1],
                                      palette: palette,
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => StoryDetailScreen(storyId: stories.mine[i - 1].id)),
                                      ),
                                    )
                                  : const SizedBox(),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 40),
            Row(
              key: _settingsKey,
              children: [
                Icon(Icons.settings_outlined, size: 26, color: palette.textPrimary),
                const SizedBox(width: 10),
                Text(l10n.settingsTitle, style: AppTypography.title2.copyWith(color: palette.textPrimary, fontSize: 28)),
              ],
            ),
            const SizedBox(height: 18),
            SectionHeader(title: l10n.meReminders),
            const SizedBox(height: 8),
            ListGroup(
              children: [
                ListRow(
                  icon: Icons.notifications_none_rounded,
                  tint: palette.sun,
                  label: l10n.notificationsCheckinTitle,
                  subtitle: data == null ? null : (reminderOn ? l10n.meReminderOn(reminderTimeLabel(reminderHour)) : l10n.meReminderOff),
                  trailing: AppToggle(
                    value: reminderOn,
                    semanticLabel: l10n.notificationsCheckinTitle,
                    onChanged: data == null || _reminderOverride != null ? null : (value) => _setReminder(value, reminderHour),
                  ),
                  onTap: () => context.push('/settings/notifications'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SectionHeader(title: l10n.meChatAndMessages),
            const SizedBox(height: 8),
            ListGroup(
              children: [
                ListRow(
                  icon: Icons.tune_rounded,
                  tint: palette.sky,
                  label: l10n.settingsChatBoundaries,
                  subtitle: l10n.settingsChatBoundariesBody,
                  onTap: () => context.push('/settings/chat-boundaries'),
                ),
                ListRow(
                  icon: Icons.mail_outline_rounded,
                  tint: palette.peach,
                  label: l10n.settingsDmPrivacy,
                  subtitle: data?.dmPolicy == 'following' ? l10n.meDmPolicyFollowing : l10n.meDmPolicyEveryone,
                  onTap: () => context.push('/settings/privacy'),
                ),
                ListRow(
                  icon: Icons.block_rounded,
                  tint: palette.lilac,
                  label: l10n.settingsBlocked,
                  subtitle: l10n.settingsBlockedBody,
                  onTap: () => context.push('/settings/blocked'),
                ),
                ListRow(
                  icon: Icons.psychology_alt_outlined,
                  tint: palette.mint,
                  label: l10n.memoryTitle,
                  subtitle: l10n.memoryRowBody,
                  onTap: () => context.push('/settings/memory'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SectionHeader(title: l10n.settingsAppearance),
            const SizedBox(height: 8),
            _Segments(
              options: [
                (ThemeMode.system, l10n.settingsThemeSystem),
                (ThemeMode.light, l10n.settingsThemeLight),
                (ThemeMode.dark, l10n.settingsThemeDark),
              ],
              selected: themeMode,
              onChanged: (mode) => ref.read(themeModeControllerProvider.notifier).setMode(mode),
            ),
            const SizedBox(height: 30),
            SectionHeader(title: l10n.profileLanguage),
            const SizedBox(height: 8),
            // Each language is named in itself, so someone stuck in the
            // other one can still recognize their own.
            _Segments(
              options: const [('tr', 'Türkçe'), ('en', 'English')],
              selected: ref.watch(localeControllerProvider).languageCode,
              onChanged: _setLanguage,
            ),
            const SizedBox(height: 30),
            Semantics(
              button: true,
              child: Material(
                color: palette.lilac,
                borderRadius: BorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => context.push('/premium'),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: Row(
                      children: [
                        Icon(Icons.star_outline_rounded, size: 28, color: palette.onTint),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.settingsPremiumRow,
                                  style: AppTypography.label.copyWith(color: palette.onTint, fontSize: 16, fontWeight: FontWeight.w700)),
                              Text(l10n.mePlusBody,
                                  style: AppTypography.subheadline.copyWith(color: palette.onTint.withValues(alpha: 0.8), fontSize: 14.5)),
                            ],
                          ),
                        ),
                        Text(l10n.mePlusCta,
                            style: AppTypography.label.copyWith(color: palette.onTint, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 30),
              SectionHeader(
                title: l10n.settingsCommunity,
                trailing: TintTag(label: l10n.meAdminTag, color: palette.glassFill, outlined: true),
              ),
              const SizedBox(height: 8),
              ListGroup(
                children: [
                  ListRow(
                    icon: Icons.verified_user_outlined,
                    label: l10n.meModeration,
                    subtitle: moderation == null || moderation.loading
                        ? null
                        : l10n.meModerationCounts(moderation.pending.length, moderation.reports.length),
                    onTap: () => context.go('/stories/moderation'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 30),
            SectionHeader(title: l10n.mePrivacyTitle),
            const SizedBox(height: 8),
            ListGroup(
              children: [
                ListRow(
                  icon: Icons.lock_outline_rounded,
                  label: l10n.settingsDataLocation,
                  onTap: () => _showInfo(l10n.settingsDataLocation, l10n.settingsDataLocationBody),
                ),
                ListRow(
                  icon: Icons.shield_outlined,
                  label: l10n.settingsLegal,
                  onTap: () => _showInfo(l10n.settingsLegal, l10n.settingsLegalBody),
                ),
              ],
            ),
            const SizedBox(height: 30),
            ListGroup(
              children: [
                ListRow(icon: Icons.logout_rounded, label: l10n.settingsLogout, onTap: _logout, showChevron: false),
                ListRow(label: l10n.settingsDeleteAccount, labelColor: palette.warning, onTap: _deleteAccount, showChevron: false),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int? value;
  final String label;
  final VoidCallback? onTap;

  const _StatCard({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Expanded(
      child: Material(
        color: palette.glassFill,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                value == null
                    ? const SkeletonBox(width: 26, height: 20, radius: 6)
                    : Text('$value', style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 22, height: 1.1)),
                Text(label, style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of mutually exclusive choices on one card — the theme and the
/// language pickers.
class _Segments<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const _Segments({required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return GlassSurface(
      radius: 16,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final (value, label) in options) ...[
            if (value != options.first.$1) const SizedBox(width: 4),
            Expanded(
              child: Semantics(
                selected: value == selected,
                button: true,
                child: Material(
                  color: value == selected ? palette.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onChanged(value),
                    child: SizedBox(
                      height: 44,
                      child: Center(
                        child: Text(
                          label,
                          style: AppTypography.label.copyWith(
                            color: value == selected ? palette.onAccent : palette.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
