import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/network/error_messages.dart';
import '../../../l10n/app_localizations.dart';
import '../../social/data/social_api.dart';
import '../../social/domain/social_models.dart';
import '../../social/presentation/user_profile_screen.dart' show UserAvatar;
import '../../stories/presentation/stories_controller.dart';

/// Everyone the signed-in account has blocked, with a way to undo each one.
/// A block made from an anonymous story shows as "Anonymous author": the app
/// never learned who wrote it, so this list doesn't either.
class BlockedPeopleScreen extends ConsumerWidget {
  const BlockedPeopleScreen({super.key});

  Future<void> _unblock(BuildContext context, WidgetRef ref, BlockedPerson person) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(socialApiProvider).unblock(person.id);
      ref.invalidate(blockedPeopleProvider);
      // Their stories can come back into the feed straight away.
      await ref.read(storiesControllerProvider.notifier).loadFeed();
      messenger.showSnackBar(SnackBar(content: Text(l10n.blockedUnblockDone)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.commonError)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final blocked = ref.watch(blockedPeopleProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SquareIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(l10n.settingsBlocked,
                        style: AppTypography.title3.copyWith(color: palette.textPrimary)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: blocked.when(
                  loading: () => Center(child: CircularProgressIndicator(color: palette.accent)),
                  error: (error, _) => Center(
                    child: Text(friendlyErrorMessage(l10n, error),
                        style: AppTypography.subheadline.copyWith(color: palette.warning)),
                  ),
                  data: (people) => people.isEmpty
                      ? Center(
                          child: Text(l10n.blockedEmpty,
                              style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.only(bottom: bottomClearance(context)),
                          itemCount: people.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final person = people[index];
                            return GlassSurface(
                              radius: 18,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  if (person.anonymous || person.userId == null)
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: palette.surfaceMuted,
                                      child: Icon(Icons.person_outline_rounded, size: 20, color: palette.textTertiary),
                                    )
                                  else
                                    UserAvatar(userId: person.userId!, size: 36, hasAvatar: person.hasAvatar),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      person.displayName ?? l10n.blockedAnonymousAuthor,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 16),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _unblock(context, ref, person),
                                    child: Text(l10n.blockedUnblock,
                                        style: AppTypography.footnote
                                            .copyWith(color: palette.accent, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
