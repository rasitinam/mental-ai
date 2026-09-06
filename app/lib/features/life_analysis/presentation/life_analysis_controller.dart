import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_prefs.dart';
import '../data/life_analysis_api.dart';
import '../domain/life_analysis.dart';

class LifeAnalysisState {
  final LifeAnalysis? analysis;
  final bool loading;
  final String? error;

  const LifeAnalysisState({this.analysis, this.loading = false, this.error});

  LifeAnalysisState copyWith({LifeAnalysis? analysis, bool? loading, String? error}) => LifeAnalysisState(
        analysis: analysis ?? this.analysis,
        loading: loading ?? this.loading,
        error: error,
      );
}

final lifeAnalysisControllerProvider =
    NotifierProvider<LifeAnalysisController, LifeAnalysisState>(LifeAnalysisController.new);

class LifeAnalysisController extends Notifier<LifeAnalysisState> {
  @override
  LifeAnalysisState build() {
    // Watched so an account switch resets to a blank state and reloads
    // that account's own analysis instead of showing the previous one.
    ref.watch(sessionTokenProvider);
    Future.microtask(loadLatest);
    return const LifeAnalysisState(loading: true);
  }

  Future<void> loadLatest() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final analysis = await ref.read(lifeAnalysisApiProvider).latest();
      state = state.copyWith(analysis: analysis, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> generateNow() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final analysis = await ref.read(lifeAnalysisApiProvider).generate();
      state = state.copyWith(analysis: analysis, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}
