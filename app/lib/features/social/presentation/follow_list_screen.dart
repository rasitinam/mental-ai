import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import '../data/social_api.dart';
import '../domain/social_models.dart';
import 'user_profile_screen.dart' show UserAvatar;

/// Followers or following for one account — the same list either way,
/// so one screen with a flag rather than two near-identical ones.
class FollowListScreen extends ConsumerWidget {
  final String userId;
  final bool followers;

  const FollowListScreen({super.key, required this.userId, required this.followers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final api = ref.watch(socialApiProvider);
    final future = followers ? api.followers(userId) : api.following(userId);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
              child: Row(
                children: [
                  SquareIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    followers ? l10n.profileStatFollowers : l10n.profileStatFollowing,
                    style: AppTypography.title3.copyWith(color: palette.textPrimary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<UserCard>>(
                future: future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator(color: palette.accent));
                  }
                  final list = snapshot.data!;
                  if (list.isEmpty) {
                    return Center(
                      child: Text(l10n.profileNobodyYet,
                          style: AppTypography.subheadline
                              .copyWith(color: palette.textSecondary)),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final card = list[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassSurface(
                          radius: 16,
                          padding: EdgeInsets.zero,
                          child: InkWell(
                            onTap: () => context.push('/users/${card.userId}'),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  UserAvatar(
                                    userId: card.userId,
                                    size: 40,
                                    hasAvatar: card.hasAvatar,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      card.displayName,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.label
                                          .copyWith(color: palette.textPrimary),
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded,
                                      size: 20, color: palette.textTertiary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
