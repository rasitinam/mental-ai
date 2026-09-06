import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/insights_api.dart';
import '../domain/insight.dart';

class InsightsState {
  final List<Insight> insights;
  final bool loading;
  final bool synthesizing;
  final String? error;

  const InsightsState({this.insights = const [], this.loading = true, this.synthesizing = false, this.error});

  InsightsState copyWith({List<Insight>? insights, bool? loading, bool? synthesizing, String? error}) =>
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
    Future.microtask(load);
    return const InsightsState();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final insights = await ref.read(insightsApiProvider).recent();
      state = state.copyWith(insights: insights, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// Triggered from the empty state — asks the backend to summarize
  /// already-ingested articles right now instead of waiting for the next
  /// scheduled cycle (or for PubMed to publish something genuinely new).
  Future<void> synthesizeNow() async {
    state = state.copyWith(synthesizing: true, error: null);
    try {
      await ref.read(insightsApiProvider).synthesizeNow();
      final insights = await ref.read(insightsApiProvider).recent();
      state = state.copyWith(insights: insights, synthesizing: false);
    } catch (e) {
      state = state.copyWith(synthesizing: false, error: e.toString());
    }
  }
}
