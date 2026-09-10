import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/storage/local_prefs.dart';
import '../features/assessment/presentation/assessment_screen.dart';
import '../features/assessment/presentation/assessment_summary_screen.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/catalog/presentation/disorder_detail_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/daily_report/presentation/daily_report_screen.dart';
import '../features/home/presentation/home_shell.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/journal/presentation/journal_screen.dart';
import '../features/life_analysis/presentation/life_analysis_screen.dart';
import '../features/mood_tracking/presentation/mood_screen.dart';
import '../features/profile/presentation/diagnoses_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/stories/presentation/stories_screen.dart';
import '../features/stories/presentation/story_moderation_screen.dart';
import '../features/stories/presentation/story_submit_screen.dart';

/// Notifies [GoRouter] whenever the signed-in session changes, so
/// `redirect` below re-runs the moment someone logs in, registers, or
/// logs out — without this, go_router only re-evaluates `redirect` on
/// navigation, and login doesn't navigate anywhere on its own.
class _SessionRefreshNotifier extends ChangeNotifier {
  _SessionRefreshNotifier(Ref ref) {
    ref.listen(sessionTokenProvider, (previous, next) {
      if (previous != next) notifyListeners();
    });
    ref.listen(justRegisteredProvider, (previous, next) {
      if (previous != next) notifyListeners();
    });
  }
}

/// Classic session gate: no valid token → every route redirects to
/// `/login`; a valid token → `/login` itself redirects into the app — or,
/// for someone who just registered, into `/onboarding` first (the PHQ-9 +
/// GAD-7 screening flow) rather than straight to `/report`. That flow
/// clears `justRegisteredProvider` itself before navigating on, whether
/// finished or skipped, so this only ever fires once per registration.
/// Every top-level destination past the gate lives on the shell's
/// `StatefulShellRoute` so the bottom nav bar preserves each tab's state
/// (scroll position, in-progress journal draft, ...) when switching tabs.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionRefreshNotifier(ref);

  return GoRouter(
    initialLocation: ref.read(sessionTokenProvider) != null ? '/report' : '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = ref.read(sessionTokenProvider) != null;
      final onLoginPage = state.matchedLocation == '/login';
      final onOnboarding = state.matchedLocation == '/onboarding';
      final justRegistered = ref.read(justRegisteredProvider);

      if (!loggedIn && !onLoginPage) return '/login';
      if (loggedIn && onLoginPage) return justRegistered ? '/onboarding' : '/report';
      if (loggedIn && justRegistered && !onOnboarding) return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => AssessmentScreen(
          skippable: true,
          onDone: () {
            ref.read(justRegisteredProvider.notifier).state = false;
            context.go('/report');
          },
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/report', builder: (context, state) => const DailyReportScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/mood', builder: (context, state) => const MoodScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/journal', builder: (context, state) => const JournalScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/insights',
              builder: (context, state) => const InsightsScreen(),
              routes: [
                // Nested so the tab bar stays and Back returns to the
                // category the person was browsing.
                GoRoute(
                  path: 'disorder/:slug',
                  builder: (context, state) =>
                      DisorderDetailScreen(slug: state.pathParameters['slug']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/life-analysis', builder: (context, state) => const LifeAnalysisScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(path: 'profile', builder: (context, state) => const ProfileScreen()),
                GoRoute(path: 'diagnoses', builder: (context, state) => const DiagnosesScreen()),
                GoRoute(
                  path: 'assessment',
                  builder: (context, state) => const AssessmentSummaryScreen(),
                  routes: [
                    GoRoute(
                      path: 'take',
                      builder: (context, state) => AssessmentScreen(
                        skippable: false,
                        onDone: () => context.go('/settings/assessment'),
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'stories',
                  builder: (context, state) => const StoriesScreen(),
                  routes: [
                    GoRoute(path: 'new', builder: (context, state) => const StorySubmitScreen()),
                    GoRoute(
                        path: 'moderation', builder: (context, state) => const StoryModerationScreen()),
                  ],
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});
