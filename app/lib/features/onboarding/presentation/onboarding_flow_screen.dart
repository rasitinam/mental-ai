import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../assessment/presentation/assessment_screen.dart';
import 'chat_boundaries_view.dart';
import 'onboarding_tour_view.dart';

/// What a new account sees between registering and the app itself, in
/// three phases: a short tour of what's here, then "what do you *not*
/// want from these conversations", then the screening battery.
///
/// Order is deliberate. The tour earns the right to ask anything at all;
/// the ground rules come before the questionnaire because the battery is
/// twenty-odd questions about what's wrong with you, and being asked how
/// you want to be spoken to *first* is the difference between an intake
/// form and a conversation. Every phase can be skipped on its own —
/// skipping the tour doesn't skip the questions, and skipping the
/// questions still leaves the ground rules set.
class OnboardingFlowScreen extends ConsumerStatefulWidget {
  /// Called once the whole run is over, however it ended — the router
  /// clears `justRegistered` and moves on from here.
  final VoidCallback onFinished;

  const OnboardingFlowScreen({super.key, required this.onFinished});

  @override
  ConsumerState<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

enum _Phase { tour, boundaries, assessment }

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  _Phase _phase = _Phase.tour;

  void _go(_Phase next) => setState(() => _phase = next);

  @override
  Widget build(BuildContext context) {
    // The battery brings its own Scaffold, progress bar and skip link —
    // handing off to it whole keeps one implementation of that flow
    // rather than a second copy wrapped in this screen's chrome.
    if (_phase == _Phase.assessment) {
      return AssessmentScreen(skippable: true, onDone: widget.onFinished);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (_phase) {
              _Phase.tour => OnboardingTourView(
                  key: const ValueKey('tour'),
                  onSkip: () => _go(_Phase.boundaries),
                  onFinished: () => _go(_Phase.boundaries),
                ),
              _Phase.boundaries => ChatBoundariesView(
                  key: const ValueKey('boundaries'),
                  onboarding: true,
                  onSaved: () => _go(_Phase.assessment),
                  onSkip: () => _go(_Phase.assessment),
                ),
              _Phase.assessment => const SizedBox.shrink(),
            },
          ),
        ),
      ),
    );
  }
}
