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
import '../features/recap/presentation/recap_screen.dart';
import '../features/settings/presentation/privacy_settings_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/social/presentation/dm_inbox_screen.dart';
import '../features/social/presentation/dm_thread_screen.dart';
import '../features/social/presentation/follow_list_screen.dart';
import '../features/social/presentation/user_profile_screen.dart';
import '../features/stories/presentation/my_stories_screen.dart';
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
    initialLocation: ref.read(sessionTokenProvider) != null ? '/stories' : '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = ref.read(sessionTokenProvider) != null;
      final onLoginPage = state.matchedLocation == '/login';
      final onOnboarding = state.matchedLocation == '/onboarding';
      final justRegistered = ref.read(justRegisteredProvider);

      if (!loggedIn && !onLoginPage) return '/login';
      if (loggedIn && onLoginPage) return justRegistered ? '/onboarding' : '/stories';
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
            context.go('/stories');
          },
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(navigationShell: navigationShell),
        // Branch order is tab order (see `HomeShell._destinations`), with
        // the story feed deliberately in the middle and Messages right
        // beside it. Mood and the journal branches sit past the last tab:
        // both still are routes with their own preserved state, reachable
        // from the home screen's quick actions, just not a destination on
        // the bar. `/dm`'s own root isn't parameterized (only its
        // `:threadId` child is), so — unlike `/users/:id` — it's free to be
        // a branch; that also fixes Android back exiting the app straight
        // from the inbox, since a shell branch keeps its own back stack
        // instead of replacing the route history the way `context.go` did.
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
                  path: 'my-stories',
                  builder: (context, state) => const MyStoriesScreen(),
                ),
                GoRoute(
                  path: 'privacy',
                  builder: (context, state) => const PrivacySettingsScreen(),
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
      // The weekly recap sits outside the shell for the same reason the
      // social surfaces below do: it's pushed over whatever tab you were
      // on (from the report screen's recap card) and carries its own back
      // button, so the tab bar would only be a second, contradictory way
      // out.
      GoRoute(
        path: '/recap',
        builder: (context, state) => const RecapScreen(),
      ),
      // Social surfaces sit outside the shell: they're pushed over
      // whatever tab you were on (from a story author or a DM row) and
      // carry their own back button, so the tab bar would only be a
      // second, contradictory way out. A parameterized route also can't be
      // a shell branch's default location, which is why `/users/:id`
      // itself (unlike `/dm`, whose root is unparameterized) stays here.
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
});
