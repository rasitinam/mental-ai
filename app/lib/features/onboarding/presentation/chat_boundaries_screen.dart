import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/data/profile_api.dart';
import 'chat_boundaries_view.dart';

/// The profile's entry into the same ground rules set during onboarding.
/// Someone who skipped the question, or whose needs changed three weeks
/// in, has to be able to answer it later — a preference you can only set
/// once is a trap, not a setting.
class ChatBoundariesScreen extends ConsumerWidget {
  const ChatBoundariesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(myProfileProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          // Inside the shell: clear the floating tab bar (see `bottomClearance`).
          padding: EdgeInsets.fromLTRB(22, 12, 22, bottomClearance(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SquareIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: profile.when(
                  loading: () => Center(child: CircularProgressIndicator(color: palette.accent)),
                  error: (_, _) => Center(
                    child: Text(l10n.commonError, style: TextStyle(color: palette.warning)),
                  ),
                  data: (data) => ChatBoundariesView(
                    initialBoundaries: data.chatBoundaries,
                    initialNote: data.chatBoundaryNote,
                    onSaved: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
                      Navigator.of(context).maybePop();
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
