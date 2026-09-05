import 'package:go_router/go_router.dart';

import '../features/chat/presentation/chat_screen.dart';
import '../features/daily_report/presentation/daily_report_screen.dart';
import '../features/home/presentation/home_shell.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/journal/presentation/journal_screen.dart';
import '../features/life_analysis/presentation/life_analysis_screen.dart';
import '../features/mood_tracking/presentation/mood_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

/// Every top-level destination lives directly on the shell's
/// `StatefulShellRoute` so the bottom nav bar preserves each tab's state
/// (scroll position, in-progress journal draft, ...) when switching tabs.
final appRouter = GoRouter(
  initialLocation: '/report',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
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
          GoRoute(path: '/insights', builder: (context, state) => const InsightsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/life-analysis', builder: (context, state) => const LifeAnalysisScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
        ]),
      ],
    ),
  ],
);
