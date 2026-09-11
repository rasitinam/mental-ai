import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/insights_api.dart';
import '../domain/insight.dart';

/// Which catalog category the insights feed is filtered to. `null` is the
/// unfiltered "Genel" view.
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

class InsightsState {
  final List<Insight> insights;
  final bool loading;
  final bool synthesizing;
  final Object? error;

  const InsightsState({
    this.insights = const [],
    this.loading = true,
    this.synthesizing = false,
    this.error,
  });

  InsightsState copyWith({
    List<Insight>? insights,
    bool? loading,
    bool? synthesizing,
    Object? error,
  }) =>
      InsightsState(
        insights: insights ?? this.insights,
        loading: loading ?? this.loading,
        synthesizing: synthesizing ?? this.synthesizing,
        error: error,
      );
}

final insightsControllerProvider = NotifierProvider<InsightsController, InsightsState>(InsightsController.new);

class InsightsController extends Notifier<InsightsState> {
  @override
  InsightsState build() {
    // Watched, so picking a different category rebuilds and refetches
    // instead of needing the screen to drive the reload.
    ref.watch(selectedCategoryProvider);
    Future.microtask(load);
    return const InsightsState();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final category = ref.read(selectedCategoryProvider);
      final insights = await ref.read(insightsApiProvider).recent(category: category);
      state = state.copyWith(insights: insights, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// Triggered from the empty state — asks the backend to summarize
  /// already-ingested articles right now instead of waiting for the next
  /// scheduled cycle (or for PubMed to publish something genuinely new).
  Future<void> synthesizeNow() async {
    state = state.copyWith(synthesizing: true, error: null);
    try {
      await ref.read(insightsApiProvider).synthesizeNow();
      final category = ref.read(selectedCategoryProvider);
      final insights = await ref.read(insightsApiProvider).recent(category: category);
      state = state.copyWith(insights: insights, synthesizing: false);
    } catch (e) {
      state = state.copyWith(synthesizing: false, error: e);
    }
  }
}
