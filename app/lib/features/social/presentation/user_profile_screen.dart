import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/storage/local_prefs.dart';
import '../../stories/presentation/stories_controller.dart';
import '../data/dm_badge.dart';
import '../data/social_api.dart';
import '../domain/social_models.dart';
import 'block_dialog.dart';

/// Someone else's account: their name, what they've shared, and the two
/// things you can do about it — follow, or ask to talk. No diagnoses, no
/// scores, nothing from the clinical half of the app.
class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _busy = false;

  Future<void> _toggleFollow(PublicProfile profile) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(socialApiProvider)
          .setFollow(widget.userId, following: !profile.viewerFollows);
      ref.invalidate(publicProfileProvider(widget.userId));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Blocks this person and leaves their profile: from here on neither side
  /// sees the other's stories or profile, and neither can message the other.
  Future<void> _block(PublicProfile profile) async {
    final l10n = AppLocalizations.of(context)!;
    if (!await confirmBlock(context) || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(socialApiProvider).blockUser(profile.userId);
      ref.invalidate(dmThreadsProvider);
      ref.invalidate(dmRequestsProvider);
      await ref.read(storiesControllerProvider.notifier).loadFeed();
      messenger.showSnackBar(SnackBar(content: Text(l10n.blockDone)));
      navigator.maybePop();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.commonError)));
    }
  }

  Future<void> _openDm(PublicProfile profile) async {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final controller = TextEditingController();

    final send = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.glassFill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.dmRequestTitle(profile.displayName),
            style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dmRequestBody,
                style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              autofocus: true,
              style: AppTypography.subheadline.copyWith(color: palette.textPrimary),
              cursorColor: palette.accent,
              decoration: InputDecoration(
                hintText: l10n.dmRequestHint,
                hintStyle: AppTypography.subheadline.copyWith(color: palette.textTertiary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.dmSend)),
        ],
      ),
    );

    final body = controller.text.trim();
    if (send != true || body.isEmpty || !mounted) return;

    try {
      final threadId = await ref.read(socialApiProvider).openThread(widget.userId, body);
      await ref.read(dmBadgeProvider.notifier).markSeen(threadId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.dmRequestSent)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.commonError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final profile = ref.watch(publicProfileProvider(widget.userId));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: profile.when(
          loading: () => Center(child: CircularProgressIndicator(color: palette.accent)),
          error: (_, _) => Center(
            child: Text(l10n.commonError,
                style: AppTypography.subheadline.copyWith(color: palette.warning)),
          ),
          data: (data) => ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(22, 12, 22, bottomClearance(context)),
            children: [
              Row(
                children: [
                  SquareIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  // Someone else's profile only: you can't block yourself.
                  if (data.userId != ref.watch(currentUserIdProvider))
                    TextButton.icon(
                      onPressed: () => _block(data),
                      icon: Icon(Icons.block_rounded, size: 18, color: palette.warning),
                      label: Text(l10n.blockAction,
                          style: AppTypography.footnote.copyWith(color: palette.warning, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Center(child: UserAvatar(userId: data.userId, size: 88, hasAvatar: data.hasAvatar)),
              const SizedBox(height: 14),
              Text(
                data.displayName,
                textAlign: TextAlign.center,
                style: AppTypography.title2.copyWith(color: palette.textPrimary),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Stat(value: data.storyCount, label: l10n.profileStatStories, palette: palette),
                  _Stat(
                    value: data.followerCount,
                    label: l10n.profileStatFollowers,
                    palette: palette,
                    onTap: () => context.push('/users/${data.userId}/followers'),
                  ),
                  _Stat(
                    value: data.followingCount,
                    label: l10n.profileStatFollowing,
                    palette: palette,
                    onTap: () => context.push('/users/${data.userId}/following'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              AppPrimaryButton(
                label: data.viewerFollows ? l10n.profileUnfollow : l10n.profileFollow,
                loading: _busy,
                onPressed: () => _toggleFollow(data),
              ),
              const SizedBox(height: 10),
              // Shown but disabled when their policy blocks it, so the
              // absence of the button never reads as "this app can't do
              // messages".
              _SecondaryButton(
                label: data.acceptsDm ? l10n.dmMessage : l10n.dmFollowersOnly,
                enabled: data.acceptsDm,
                palette: palette,
                onTap: () => _openDm(data),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular avatar for any account, falling back to a person glyph. Used
/// on profiles, DM rows and follower lists alike.
class UserAvatar extends ConsumerWidget {
  final String userId;
  final double size;
  final bool hasAvatar;

  const UserAvatar({
    super.key,
    required this.userId,
    required this.size,
    required this.hasAvatar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final placeholder = Icon(Icons.person_rounded, size: size * 0.5, color: palette.textTertiary);

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(shape: BoxShape.circle, color: palette.surfaceMuted),
      child: !hasAvatar
          ? placeholder
          : ref.watch(userAvatarProvider(userId)).when(
                data: (bytes) => bytes == null
                    ? placeholder
                    : Image.memory(bytes, fit: BoxFit.cover, width: size, height: size),
                loading: () => placeholder,
                error: (_, _) => placeholder,
              ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  final AppPalette palette;
  final VoidCallback? onTap;

  const _Stat({required this.value, required this.label, required this.palette, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text('$value',
                  style: AppTypography.title3.copyWith(color: palette.textPrimary)),
              const SizedBox(height: 2),
              Text(label,
                  style: AppTypography.caption.copyWith(color: palette.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final AppPalette palette;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.label,
    required this.enabled,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Material(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Center(
            child: Text(
              label,
              style: AppTypography.label.copyWith(
                color: enabled ? palette.textPrimary : palette.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
