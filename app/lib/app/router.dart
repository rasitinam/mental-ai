import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/storage/local_prefs.dart';
import '../core/ui/keyboard.dart';
import '../features/assessment/presentation/assessment_screen.dart';
import '../features/assessment/presentation/assessment_summary_screen.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/catalog/presentation/disorder_detail_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/consent/presentation/privacy_consent_screen.dart';
import '../features/daily_report/presentation/daily_report_screen.dart';
import '../features/home/presentation/home_shell.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/journal/presentation/journal_screen.dart';
import '../features/life_analysis/presentation/life_analysis_screen.dart';
import '../features/mood_tracking/presentation/mood_screen.dart';
import '../features/onboarding/presentation/chat_boundaries_screen.dart';
import '../features/onboarding/presentation/onboarding_flow_screen.dart';
import '../features/premium/presentation/premium_screen.dart';
import '../features/profile/presentation/diagnoses_screen.dart';
import '../features/profile/presentation/my_profile_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/recap/presentation/recap_screen.dart';
import '../features/session_summary/presentation/session_summary_screen.dart';
import '../features/settings/presentation/notification_settings_screen.dart';
import '../features/settings/presentation/blocked_people_screen.dart';
import '../features/settings/presentation/privacy_settings_screen.dart';
import '../features/social/presentation/dm_inbox_screen.dart';
import '../features/social/presentation/dm_thread_screen.dart';
import '../features/social/presentation/follow_list_screen.dart';
import '../features/social/presentation/user_profile_screen.dart';
import '../features/stories/presentation/my_stories_screen.dart';
import '../features/stories/presentation/stories_screen.dart';
import '../features/stories/presentation/story_moderation_screen.dart';
import '../features/stories/presentation/story_submit_screen.dart';

/// Notifies [GoRouter] whenever the signed-in session changes, so
/// `redirect` re-runs the moment someone logs in, registers, or logs out.
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

/// Classic session gate: no valid token → `/login`; a valid token → Bugün,
/// or `/onboarding` first for someone who just registered.
///
/// Branch order matters — `HomeShell` maps branches to its five tabs:
/// 0 Bugün, 1 Sohbet, 2 Hikayeler, 5 Yolum, 6 Ben are tabs; 3 Messages
/// (under Hikayeler), 4 Rehber (under Yolum), 7 mood and 8 journal (under
/// Bugün) are branches that light their parent tab.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionRefreshNotifier(ref);

  final router = GoRouter(
    initialLocation: ref.read(sessionTokenProvider) != null ? '/report' : '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = ref.read(sessionTokenProvider) != null;
      final onLoginPage = state.matchedLocation == '/login';
      final onOnboarding = state.matchedLocation == '/onboarding';
      final onConsent = state.matchedLocation == '/before-you-go';
      final justRegistered = ref.read(justRegisteredProvider);

      // The privacy summary comes before everything else, once per policy
      // version — including for people already signed in when it ships.
      if (!hasAcceptedPrivacy(ref.read(sharedPreferencesProvider))) {
        return onConsent ? null : '/before-you-go';
      }
      if (onConsent) return loggedIn ? '/report' : '/login';

      if (!loggedIn && !onLoginPage) return '/login';
      if (loggedIn && onLoginPage) return justRegistered ? '/onboarding' : '/report';
      if (loggedIn && justRegistered && !onOnboarding) return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(
        path: '/before-you-go',
        builder: (context, state) => PrivacyConsentScreen(onAccepted: () => context.go('/login')),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingFlowScreen(
          onFinished: () {
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
            GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/stories',
              builder: (context, state) => const StoriesScreen(),
              routes: [
                GoRoute(path: 'new', builder: (context, state) => const StorySubmitScreen()),
                GoRoute(
                    path: 'moderation', builder: (context, state) => const StoryModerationScreen()),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dm',
              builder: (context, state) => const DmInboxScreen(),
              routes: [
                GoRoute(
                  path: ':threadId',
                  builder: (context, state) =>
                      DmThreadScreen(threadId: state.pathParameters['threadId']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/insights',
              builder: (context, state) => const InsightsScreen(),
              routes: [
                GoRoute(
                  path: 'disorder/:slug',
                  builder: (context, state) =>
                      DisorderDetailScreen(slug: state.pathParameters['slug']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/life-analysis',
              builder: (context, state) => const LifeAnalysisScreen(),
              routes: [
                GoRoute(
                  path: 'session-summary',
                  builder: (context, state) => const SessionSummaryScreen(),
                ),
                GoRoute(
                  path: 'assessment',
                  builder: (context, state) => const AssessmentSummaryScreen(),
                  routes: [
                    GoRoute(
                      path: 'take',
                      builder: (context, state) => AssessmentScreen(
                        skippable: false,
                        onDone: () => context.go('/life-analysis/assessment'),
                      ),
                    ),
                  ],
                ),
                GoRoute(path: 'diagnoses', builder: (context, state) => const DiagnosesScreen()),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const MyProfileScreen(),
              routes: [
                GoRoute(
                  path: 'notifications',
                  builder: (context, state) => const NotificationSettingsScreen(),
                ),
                GoRoute(path: 'profile', builder: (context, state) => const ProfileScreen()),
                GoRoute(
                  path: 'chat-boundaries',
                  builder: (context, state) => const ChatBoundariesScreen(),
                ),
                GoRoute(path: 'diagnoses', builder: (context, state) => const DiagnosesScreen()),
                GoRoute(
                  path: 'my-stories',
                  builder: (context, state) => const MyStoriesScreen(),
                ),
                GoRoute(
                  path: 'privacy',
                  builder: (context, state) => const PrivacySettingsScreen(),
                ),
                GoRoute(
                  path: 'blocked',
                  builder: (context, state) => const BlockedPeopleScreen(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/mood', builder: (context, state) => const MoodScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/journal', builder: (context, state) => const JournalScreen()),
          ]),
        ],
      ),
      // Pushed over whatever tab you were on, with their own back button —
      // the tab bar would only be a second, contradictory way out.
      GoRoute(
        path: '/recap',
        builder: (context, state) => const RecapScreen(),
      ),
      GoRoute(
        path: '/premium',
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: '/users/:id',
        builder: (context, state) => UserProfileScreen(userId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'followers',
            builder: (context, state) =>
                FollowListScreen(userId: state.pathParameters['id']!, followers: true),
          ),
          GoRoute(
            path: 'following',
            builder: (context, state) =>
                FollowListScreen(userId: state.pathParameters['id']!, followers: false),
          ),
        ],
      ),
    ],
  );

  // Moving to another page hides the keyboard, so it is not left hanging over
  // the next screen (or animating along with the page transition).
  router.routerDelegate.addListener(dismissKeyboard);
  ref.onDispose(() => router.routerDelegate.removeListener(dismissKeyboard));
  return router;
});
