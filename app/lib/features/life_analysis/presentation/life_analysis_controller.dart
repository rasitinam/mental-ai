import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_prefs.dart';
import '../data/life_analysis_api.dart';
import '../domain/life_analysis.dart';

class LifeAnalysisState {
  final LifeAnalysis? analysis;
  final bool loading;
  final Object? error;

  /// When the next generation becomes available (weekly cooldown).
  final DateTime? cooldownUntil;

  const LifeAnalysisState({this.analysis, this.loading = false, this.error, this.cooldownUntil});

  bool get isOnCooldown => cooldownUntil != null && cooldownUntil!.isAfter(DateTime.now());

  LifeAnalysisState copyWith({
    LifeAnalysis? analysis,
    bool? loading,
    Object? error,
    DateTime? cooldownUntil,
  }) =>
      LifeAnalysisState(
        analysis: analysis ?? this.analysis,
        loading: loading ?? this.loading,
        error: error,
        cooldownUntil: cooldownUntil ?? this.cooldownUntil,
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
      state = state.copyWith(
        analysis: analysis,
        loading: false,
        // The cooldown is measured from the last generation, so the loaded
        // analysis is enough to know it without a second request.
        cooldownUntil: analysis?.generatedAt.add(const Duration(days: 7)),
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> generateNow() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final analysis = await ref.read(lifeAnalysisApiProvider).generate();
      state = state.copyWith(
        analysis: analysis,
        loading: false,
        cooldownUntil: analysis.generatedAt.add(const Duration(days: 7)),
      );
    } on LifeAnalysisCooldownException catch (e) {
      state = state.copyWith(loading: false, cooldownUntil: e.retryAfter);
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }
}
