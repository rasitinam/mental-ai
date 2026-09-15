import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/components.dart';
import '../../../app/theme/glass.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/error_messages.dart';
import '../../../core/storage/local_prefs.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/auth_api.dart';
import '../../catalog/data/catalog_api.dart';
import '../../catalog/domain/disorder_category.dart';
import '../../notifications/push_service.dart';
import '../../settings/presentation/notification_settings_screen.dart' show reminderTimeLabel;
import '../../social/data/social_api.dart';
import '../../stories/domain/life_story.dart';
import '../../stories/presentation/moderation_controller.dart';
import '../../stories/presentation/stories_controller.dart';
import '../../stories/presentation/story_detail_screen.dart';
import '../../stories/presentation/story_grid_tile.dart';
import '../../stories/presentation/story_submit_screen.dart';
import '../data/profile_api.dart';

/// Ben — the profile and every setting, in one scrolling page. Nothing
/// sits behind a gear icon any more: the reminder switch, chat and message
/// preferences, appearance, Hearth Plus and moderation are all rows here.
class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  /// The switch's position while its save is in flight.
  bool? _reminderOverride;

  @override
  void initState() {
    super.initState();
    // A story withdrawn or edited elsewhere shows up the next time this tab
    // opens, not on a stale first load.
    Future.microtask(() => ref.read(storiesControllerProvider.notifier).loadMine());
  }

  Future<void> _setReminder(bool enabled, int hour) async {
    setState(() => _reminderOverride = enabled);
    try {
      await ref.read(profileApiProvider).setCheckinReminder(enabled: enabled, hour: hour);
      ref.invalidate(myProfileProvider);
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
      await ref.read(pushServiceProvider).unregister();
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
                await ref.read(authApiProvider).deleteAccount(password: passwordController.text);
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } on DioException catch (e) {
                setState(() {
                  busy = false;
                  error = e.response?.statusCode == 401 ? l10n.deleteAccountWrongPassword : l10n.commonError;
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
                  onPressed: busy || passwordController.text.isEmpty ? null : confirm,
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
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <DisorderCategory>[];
    final themeMode = ref.watch(themeModeControllerProvider);
    final isAdmin = data?.isAdmin ?? false;
    final moderation = isAdmin ? ref.watch(moderationControllerProvider) : null;

    final reminderOn = _reminderOverride ?? data?.checkinReminderEnabled ?? false;
    final reminderHour = data?.checkinReminderHour ?? 21;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(22, 10, 22, bottomClearance(context)),
          children: [
            Text(l10n.navMe, style: AppTypography.title2.copyWith(color: palette.textPrimary)),
            const SizedBox(height: 18),
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/settings/profile'),
                  child: Container(
                    width: 76,
                    height: 76,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: palette.lilac),
                    child: avatar.when(
                      data: (bytes) => bytes != null
                          ? Image.memory(bytes, fit: BoxFit.cover, width: 76, height: 76)
                          : Center(
                              child: Text(
                                (data?.displayName.isNotEmpty ?? false) ? data!.displayName.characters.first.toUpperCase() : '',
                                style: AppTypography.title1.copyWith(color: palette.textPrimary),
                              ),
                            ),
                      loading: () => const SkeletonBox(width: 76, height: 76, radius: 38),
                      error: (_, _) => Icon(Icons.person_rounded, size: 38, color: palette.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: profile.when(
                    data: (p) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.displayName, style: AppTypography.title3.copyWith(color: palette.textPrimary)),
                        if (p.email != null) ...[
                          const SizedBox(height: 2),
                          Text(p.email!,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
                        ],
                      ],
                    ),
                    loading: () => const SkeletonBox(width: 140, height: 22, radius: 6),
                    error: (_, _) => Text(l10n.commonError, style: TextStyle(color: palette.warning)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatCard(
                  value: stats?.storyCount,
                  label: l10n.profileStatStories,
                  onTap: () => context.push('/settings/my-stories'),
                ),
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
            const SizedBox(height: 12),
            OutlineBlockButton(
              icon: Icons.edit_outlined,
              label: l10n.myProfileEdit,
              height: 48,
              onTap: () => context.push('/settings/profile'),
            ),
            const SizedBox(height: 28),
            SectionHeader(
              title: l10n.myProfileStories,
              action: l10n.discoveriesSeeAll,
              onAction: () => context.push('/settings/my-stories'),
            ),
            const SizedBox(height: 8),
            _StoryGrid(
              loading: stories.loadingMine,
              stories: stories.mine,
              categories: categories,
              onAdd: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StorySubmitScreen())),
              onOpen: (id) =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoryDetailScreen(storyId: id))),
            ),
            const SizedBox(height: 28),
            SectionHeader(title: l10n.meReminders),
            const SizedBox(height: 10),
            ListGroup(
              children: [
                ListRow(
                  icon: Icons.notifications_none_rounded,
                  tint: palette.sun,
                  label: l10n.notificationsCheckinTitle,
                  subtitle: data == null
                      ? null
                      : (reminderOn ? l10n.meReminderOn(reminderTimeLabel(reminderHour)) : l10n.meReminderOff),
                  trailing: Switch(
                    value: reminderOn,
                    onChanged: data == null || _reminderOverride != null
                        ? null
                        : (value) => _setReminder(value, reminderHour),
                  ),
                  onTap: () => context.push('/settings/notifications'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SectionHeader(title: l10n.meChatAndMessages),
            const SizedBox(height: 10),
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
              ],
            ),
            const SizedBox(height: 28),
            SectionHeader(title: l10n.settingsAppearance),
            const SizedBox(height: 10),
            _ThemeSegments(
              mode: themeMode,
              onChanged: (mode) => ref.read(themeModeControllerProvider.notifier).setMode(mode),
            ),
            const SizedBox(height: 28),
            Material(
              color: palette.lilac,
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/premium'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium_outlined, size: 28, color: palette.textPrimary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.settingsPremiumRow,
                                style: AppTypography.label.copyWith(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                            Text(l10n.mePlusBody, style: AppTypography.footnote.copyWith(color: palette.textPrimary)),
                          ],
                        ),
                      ),
                      Text(l10n.mePlusCta,
                          style: AppTypography.label.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                      Icon(Icons.chevron_right_rounded, color: palette.textPrimary),
                    ],
                  ),
                ),
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 28),
              SectionHeader(title: l10n.settingsCommunity),
              const SizedBox(height: 10),
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
            const SizedBox(height: 28),
            SectionHeader(title: l10n.settingsPrivacy),
            const SizedBox(height: 10),
            ListGroup(
              children: [
                ListRow(
                  icon: Icons.lock_outline_rounded,
                  label: l10n.settingsDataLocation,
                  subtitle: l10n.settingsDataLocationBody,
                ),
                ListRow(
                  icon: Icons.shield_outlined,
                  label: l10n.settingsLegal,
                  subtitle: l10n.settingsLegalBody,
                ),
              ],
            ),
            const SizedBox(height: 28),
            SectionHeader(title: l10n.settingsConnection),
            const SizedBox(height: 10),
            ListGroup(
              children: [
                ListRow(label: l10n.settingsServer, subtitle: AppConstants.apiBaseUrl),
                ListRow(label: l10n.settingsDeviceId, subtitle: myUserId ?? '—'),
              ],
            ),
            const SizedBox(height: 28),
            SectionHeader(title: l10n.settingsAccount),
            const SizedBox(height: 10),
            ListGroup(
              children: [
                ListRow(icon: Icons.logout_rounded, label: l10n.settingsLogout, onTap: _logout),
                ListRow(
                  icon: Icons.delete_outline_rounded,
                  tint: palette.warningSoft,
                  label: l10n.settingsDeleteAccount,
                  labelColor: palette.warning,
                  onTap: _deleteAccount,
                ),
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
            constraints: const BoxConstraints(minHeight: 66),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                value == null
                    ? const SkeletonBox(width: 26, height: 20, radius: 6)
                    : Text('$value', style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 22)),
                Text(label, style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeSegments extends StatelessWidget {
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeSegments({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final options = [
      (ThemeMode.system, l10n.settingsThemeSystem),
      (ThemeMode.light, l10n.settingsThemeLight),
      (ThemeMode.dark, l10n.settingsThemeDark),
    ];

    return GlassSurface(
      radius: 18,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final (value, label) in options)
            Expanded(
              child: Semantics(
                selected: value == mode,
                button: true,
                child: Material(
                  color: value == mode ? palette.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onChanged(value),
                    child: SizedBox(
                      height: 46,
                      child: Center(
                        child: Text(
                          label,
                          style: AppTypography.label.copyWith(
                            color: value == mode ? palette.onAccent : palette.textSecondary,
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
      ),
    );
  }
}

/// The first few of the person's own stories, with the "write a new one"
/// tile first; "Tümü" opens the full list.
class _StoryGrid extends StatelessWidget {
  final bool loading;
  final List<LifeStory> stories;
  final List<DisorderCategory> categories;
  final VoidCallback onAdd;
  final void Function(String storyId) onOpen;

  const _StoryGrid({
    required this.loading,
    required this.stories,
    required this.categories,
    required this.onAdd,
    required this.onOpen,
  });

  ({String emoji, String name})? _resolve(String diagnosisSlug) {
    for (final category in categories) {
      for (final disorder in category.disorders) {
        if (disorder.slug == diagnosisSlug) return (emoji: category.emoji, name: disorder.name);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final shown = loading ? 2 : math.min(stories.length, 5);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 1 + shown,
      itemBuilder: (context, i) {
        if (i == 0) return AddStoryTile(palette: palette, onTap: onAdd);
        if (loading) return const SkeletonBox(radius: 14, height: double.infinity);

        final story = stories[i - 1];
        return StoryGridTile(
          story: story,
          tag: _resolve(story.diagnosisSlug),
          palette: palette,
          onTap: () => onOpen(story.id),
        );
      },
    );
  }
}
