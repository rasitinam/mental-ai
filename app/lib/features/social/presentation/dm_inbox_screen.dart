import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import '../data/social_api.dart';
import '../domain/social_models.dart';
import 'user_profile_screen.dart' show UserAvatar;

/// Messages: accepted conversations on one tab, pending requests on the
/// other. The request tab is where the gate lives — nobody lands in the
/// inbox proper without having been let in.
class DmInboxScreen extends ConsumerStatefulWidget {
  const DmInboxScreen({super.key});

  @override
  ConsumerState<DmInboxScreen> createState() => _DmInboxScreenState();
}

class _DmInboxScreenState extends ConsumerState<DmInboxScreen> {
  bool _showRequests = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final threads = ref.watch(_showRequests ? dmRequestsProvider : dmThreadsProvider);
    final requestCount = ref.watch(dmRequestsProvider).valueOrNull?.length ?? 0;

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
                  Text(l10n.dmTitle,
                      style: AppTypography.title3.copyWith(color: palette.textPrimary)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _tab(l10n.dmTabInbox, !_showRequests, () => setState(() => _showRequests = false),
                        palette),
                    _tab(
                      requestCount > 0 ? '${l10n.dmTabRequests} ($requestCount)' : l10n.dmTabRequests,
                      _showRequests,
                      () => setState(() => _showRequests = true),
                      palette,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: palette.accent,
                onRefresh: () async {
                  ref.invalidate(dmThreadsProvider);
                  ref.invalidate(dmRequestsProvider);
                },
                child: threads.when(
                  loading: () => Center(child: CircularProgressIndicator(color: palette.accent)),
                  error: (_, _) => ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(l10n.commonError,
                            textAlign: TextAlign.center,
                            style: AppTypography.subheadline.copyWith(color: palette.warning)),
                      ),
                    ],
                  ),
                  data: (list) => list.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.fromLTRB(28, 60, 28, 0),
                          children: [
                            Icon(Icons.forum_outlined, size: 28, color: palette.accent),
                            const SizedBox(height: 14),
                            Text(
                              _showRequests ? l10n.dmNoRequests : l10n.dmNoThreads,
                              textAlign: TextAlign.center,
                              style: AppTypography.headline
                                  .copyWith(color: palette.textPrimary, fontSize: 17),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                          itemCount: list.length,
                          itemBuilder: (context, i) => _ThreadRow(
                            thread: list[i],
                            palette: palette,
                            l10n: l10n,
                            onTap: () => context.push('/dm/${list[i].id}'),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, bool selected, VoidCallback onTap, AppPalette palette) {
    return Expanded(
      child: Material(
        color: selected ? palette.glassFill : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: AppTypography.footnote.copyWith(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? palette.textPrimary : palette.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThreadRow extends StatelessWidget {
  final DmThread thread;
  final AppPalette palette;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _ThreadRow({
    required this.thread,
    required this.palette,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pending = thread.status == DmStatus.pending;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassSurface(
        radius: 16,
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                UserAvatar(
                  userId: thread.otherUserId,
                  size: 44,
                  hasAvatar: thread.otherHasAvatar,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              thread.otherDisplayName,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label.copyWith(
                                color: palette.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (pending) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: palette.accentSoft,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                thread.startedByMe ? l10n.dmWaiting : l10n.dmNewRequest,
                                style: AppTypography.caption
                                    .copyWith(color: palette.accent, fontSize: 11),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (thread.lastMessage != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          thread.lastMessage!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  DateFormat.Md(Localizations.localeOf(context).languageCode)
                      .format(thread.lastMessageAt),
                  style: AppTypography.caption.copyWith(color: palette.textTertiary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
