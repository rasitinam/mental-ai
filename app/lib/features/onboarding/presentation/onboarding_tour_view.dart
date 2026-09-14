import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';

/// One page of the first-run tour.
class _TourPage {
  final IconData icon;
  final String title;
  final String body;
  const _TourPage({required this.icon, required this.title, required this.body});
}

List<_TourPage> _pages(AppLocalizations l10n) => [
      _TourPage(
        icon: Icons.local_fire_department_rounded,
        title: l10n.tourWelcomeTitle,
        body: l10n.tourWelcomeBody,
      ),
      _TourPage(
        icon: Icons.forum_rounded,
        title: l10n.tourChatTitle,
        body: l10n.tourChatBody,
      ),
      _TourPage(
        icon: Icons.favorite_rounded,
        title: l10n.tourMoodJournalTitle,
        body: l10n.tourMoodJournalBody,
      ),
      _TourPage(
        icon: Icons.event_note_rounded,
        title: l10n.tourReportTitle,
        body: l10n.tourReportBody,
      ),
      _TourPage(
        icon: Icons.auto_stories_rounded,
        title: l10n.tourCommunityTitle,
        body: l10n.tourCommunityBody,
      ),
      _TourPage(
        icon: Icons.lock_rounded,
        title: l10n.tourPrivacyTitle,
        body: l10n.tourPrivacyBody,
      ),
    ];

/// The guided walkthrough shown once, immediately after registering.
/// Every page carries the same skip affordance — the person who wants to
/// be in the app right now should never have to tap "next" six times to
/// get there, and the tour is worth nothing to someone who resents it.
class OnboardingTourView extends StatefulWidget {
  /// Leaves the tour entirely (any page) and moves on to the next phase.
  final VoidCallback onSkip;

  /// Finished the last page.
  final VoidCallback onFinished;

  const OnboardingTourView({super.key, required this.onSkip, required this.onFinished});

  @override
  State<OnboardingTourView> createState() => _OnboardingTourViewState();
}

class _OnboardingTourViewState extends State<OnboardingTourView> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next(int total) {
    if (_index >= total - 1) {
      widget.onFinished();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final pages = _pages(l10n);
    final isLast = _index == pages.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: widget.onSkip,
            child: Text(l10n.onboardingSkipTour,
                style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: pages.length,
            itemBuilder: (context, i) => _TourPageView(page: pages[i], palette: palette),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < pages.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _index ? palette.accent : palette.separator,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        AppPrimaryButton(
          label: isLast ? l10n.tourStart : l10n.tourNext,
          onPressed: () => _next(pages.length),
        ),
      ],
    );
  }
}

class _TourPageView extends StatelessWidget {
  final _TourPage page;
  final AppPalette palette;

  const _TourPageView({required this.page, required this.palette});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(22)),
            child: Icon(page.icon, size: 30, color: palette.accent),
          ),
          const SizedBox(height: 26),
          Text(page.title, style: AppTypography.largeTitle.copyWith(color: palette.textPrimary)),
          const SizedBox(height: 12),
          Text(
            page.body,
            style: AppTypography.body.copyWith(color: palette.textSecondary, height: 1.65),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
