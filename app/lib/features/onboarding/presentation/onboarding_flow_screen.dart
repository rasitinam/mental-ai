import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../assessment/presentation/assessment_screen.dart';
import 'onboarding_intro_chat_view.dart';
import 'onboarding_tour_view.dart';

/// What a new account sees between registering and the app itself, in
/// three phases: one real exchange with Hearth about how it should talk
/// to them, then the screening battery, then a tour of what's here.
///
/// Order is deliberate. The app opens by asking *them* something and
/// answering — before any questionnaire and before any feature pitch —
/// because that first minute is what tells someone whether this is a
/// conversation or an intake form. The tour comes last: a walkthrough of
/// tabs means something once there's a reason to care about them, and
/// nothing at all as a cold open. Every phase can be skipped on its own;
/// skipping one never skips the next.
class OnboardingFlowScreen extends ConsumerStatefulWidget {
  /// Called once the whole run is over, however it ended — the router
  /// clears `justRegistered` and moves on from here.
  final VoidCallback onFinished;

  const OnboardingFlowScreen({super.key, required this.onFinished});

  @override
  ConsumerState<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

enum _Phase { intro, assessment, tour }

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  _Phase _phase = _Phase.intro;

  void _go(_Phase next) => setState(() => _phase = next);

  @override
  Widget build(BuildContext context) {
    // The battery brings its own Scaffold, progress bar and skip link —
    // handing off to it whole keeps one implementation of that flow
    // rather than a second copy wrapped in this screen's chrome.
    if (_phase == _Phase.assessment) {
      return AssessmentScreen(skippable: true, onDone: () => _go(_Phase.tour));
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (_phase) {
              _Phase.intro => OnboardingIntroChatView(
                  key: const ValueKey('intro'),
                  onDone: () => _go(_Phase.assessment),
                ),
              _Phase.tour => OnboardingTourView(
                  key: const ValueKey('tour'),
                  onSkip: widget.onFinished,
                  onFinished: widget.onFinished,
                ),
              _Phase.assessment => const SizedBox.shrink(),
            },
          ),
        ),
      ),
    );
  }
}
