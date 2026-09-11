import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_prefs.dart';
import '../data/state_api.dart';
import '../domain/user_state.dart';

class HomeStateData {
  final UserState? state;

  /// True only while a *reassessment* is in flight, so the screen can say
  /// "reassessing" rather than showing a bare spinner over stale numbers.
  final bool refreshing;
  final bool loading;
  final Object? error;

  const HomeStateData({
    this.state,
    this.refreshing = false,
    this.loading = true,
    this.error,
  });

  HomeStateData copyWith({
    UserState? state,
    bool? refreshing,
    bool? loading,
    Object? error,
  }) =>
      HomeStateData(
        state: state ?? this.state,
        refreshing: refreshing ?? this.refreshing,
        loading: loading ?? this.loading,
        error: error,
      );
}

final stateControllerProvider =
    NotifierProvider<StateController, HomeStateData>(StateController.new);

class StateController extends Notifier<HomeStateData> {
  @override
  HomeStateData build() {
    // Watched so an account switch shows that account's own reading rather
    // than carrying the previous one over.
    ref.watch(sessionTokenProvider);
    Future.microtask(load);
    return const HomeStateData();
  }

  /// Cheap read of the stored assessment, for opening the screen.
  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final latest = await ref.read(stateApiProvider).latest();
      state = HomeStateData(state: latest, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// Full reassessment — an LLM call, so it only runs when the person asks
  /// for it (pull-to-refresh) rather than on every screen build.
  Future<void> refresh() async {
    state = state.copyWith(refreshing: true, error: null);
    try {
      final assessed = await ref.read(stateApiProvider).refresh();
      state = HomeStateData(state: assessed, loading: false);
    } catch (e) {
      state = state.copyWith(refreshing: false, loading: false, error: e);
    }
  }
}
