import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import '../data/dm_badge.dart';
import '../data/social_api.dart';
import '../domain/social_models.dart';
import 'user_profile_screen.dart' show UserAvatar;

/// One conversation. A pending request the viewer received shows
/// accept/decline instead of a composer — replying *is* accepting, so the
/// buttons are only there for someone who wants to decide without
/// answering.
class DmThreadScreen extends ConsumerStatefulWidget {
  final String threadId;
  const DmThreadScreen({super.key, required this.threadId});

  @override
  ConsumerState<DmThreadScreen> createState() => _DmThreadScreenState();
}

class _DmThreadScreenState extends ConsumerState<DmThreadScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Opening the thread is what "read" means here — see `DmBadgeNotifier`.
    Future.microtask(() => ref.read(dmBadgeProvider.notifier).markSeen(widget.threadId));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  DmThread? _thread() {
    for (final source in [dmThreadsProvider, dmRequestsProvider]) {
      final list = ref.read(source).valueOrNull;
      final match = list?.where((t) => t.id == widget.threadId);
      if (match != null && match.isNotEmpty) return match.first;
    }
    return null;
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await ref.read(socialApiProvider).send(widget.threadId, body);
      _input.clear();
      ref.invalidate(dmMessagesProvider(widget.threadId));
      ref.invalidate(dmThreadsProvider);
      ref.invalidate(dmRequestsProvider);
      await ref.read(dmBadgeProvider.notifier).markSeen(widget.threadId);
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dmSendFailed)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _accept() async {
    await ref.read(socialApiProvider).accept(widget.threadId);
    ref.invalidate(dmThreadsProvider);
    ref.invalidate(dmRequestsProvider);
    await ref.read(dmBadgeProvider.notifier).refresh();
  }

  Future<void> _decline() async {
    await ref.read(socialApiProvider).discard(widget.threadId);
    ref.invalidate(dmThreadsProvider);
    ref.invalidate(dmRequestsProvider);
    await ref.read(dmBadgeProvider.notifier).refresh();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final messages = ref.watch(dmMessagesProvider(widget.threadId));
    final thread = _thread();

    // A request the viewer received: they decide before a composer appears.
    final awaitingMyAnswer =
        thread != null && thread.status == DmStatus.pending && !thread.startedByMe;
    // One the viewer sent: nothing more to say until it's accepted.
    final waitingOnThem =
        thread != null && thread.status == DmStatus.pending && thread.startedByMe;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
              child: Row(
                children: [
                  SquareIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 14),
                  if (thread != null) ...[
                    UserAvatar(
                      userId: thread.otherUserId,
                      size: 36,
                      hasAvatar: thread.otherHasAvatar,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push('/users/${thread.otherUserId}'),
                        borderRadius: BorderRadius.circular(8),
                        child: Text(
                          thread.otherDisplayName,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headline
                              .copyWith(color: palette.textPrimary, fontSize: 17),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _decline,
                      tooltip: l10n.dmLeave,
                      icon: Icon(Icons.delete_outline_rounded, size: 20, color: palette.warning),
                    ),
                  ] else
                    Text(l10n.dmTitle,
                        style: AppTypography.title3.copyWith(color: palette.textPrimary)),
                ],
              ),
            ),
            Expanded(
              child: messages.when(
                loading: () => Center(child: CircularProgressIndicator(color: palette.accent)),
                error: (_, _) => Center(
                  child: Text(l10n.commonError,
                      style: AppTypography.subheadline.copyWith(color: palette.warning)),
                ),
                data: (list) => ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _Bubble(message: list[i], palette: palette),
                ),
              ),
            ),
            if (awaitingMyAnswer)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                child: Column(
                  children: [
                    Text(l10n.dmAcceptPrompt,
                        textAlign: TextAlign.center,
                        style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppPrimaryButton(label: l10n.dmAccept, onPressed: _accept),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: Material(
                              color: palette.surfaceMuted,
                              borderRadius: BorderRadius.circular(18),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: _decline,
                                child: Center(
                                  child: Text(l10n.dmDecline,
                                      style: AppTypography.label.copyWith(
                                        color: palette.warning,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else if (waitingOnThem)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                child: Text(l10n.dmWaitingBody,
                    textAlign: TextAlign.center,
                    style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 52),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        decoration: BoxDecoration(
                          color: palette.glassFill,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: palette.separator),
                        ),
                        child: TextField(
                          controller: _input,
                          maxLines: 4,
                          minLines: 1,
                          style: AppTypography.subheadline.copyWith(color: palette.textPrimary),
                          cursorColor: palette.accent,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: l10n.dmComposerHint,
                            hintStyle:
                                AppTypography.subheadline.copyWith(color: palette.textTertiary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: palette.accent,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _sending ? null : _send,
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: _sending
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final DmMessage message;
  final AppPalette palette;

  const _Bubble({required this.message, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.mine ? palette.accent : palette.glassFill,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.mine ? 20 : 6),
            bottomRight: Radius.circular(message.mine ? 6 : 20),
          ),
          border: message.mine ? null : Border.all(color: palette.separator),
        ),
        child: Text(
          message.body,
          style: AppTypography.label.copyWith(
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: message.mine ? Colors.white : palette.textPrimary,
          ),
        ),
      ),
    );
  }
}
