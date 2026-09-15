import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/chat/presentation/chat_controller.dart';
import '../features/daily_report/presentation/daily_report_controller.dart';
import '../features/daily_report/presentation/state_controller.dart';
import '../features/discoveries/data/discoveries_api.dart';
import '../features/life_analysis/presentation/life_analysis_controller.dart';

/// Everything on screen that the AI wrote for this account. The server
/// returns it in the account's current language — translating what was
/// generated in another one — while what the person wrote themselves
/// (journal entries, their own chat messages) stays as written.
///
/// Invalidated once a new language is saved on the account, so these
/// reload in it right away instead of after the next app start.
final languageDependentProviders = <ProviderOrFamily>[
  stateControllerProvider,
  dailyReportControllerProvider,
  discoveriesProvider,
  lifeAnalysisControllerProvider,
  chatControllerProvider,
];
