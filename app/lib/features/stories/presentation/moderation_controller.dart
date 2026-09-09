import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/life_stories_api.dart';
import '../domain/life_story.dart';

class ModerationState {
  final List<AdminStoryView> pending;
  final List<ReportedStory> reports;
  final bool loading;
  /// Ids currently being approved/rejected/dismissed — lets a single row
  /// show its own spinner instead of blocking the whole queue.
  final Set<String> processing;
  final String? error;

  const ModerationState({
    this.pending = const [],
    this.reports = const [],
    this.loading = true,
    this.processing = const {},
    this.error,
  });

  ModerationState copyWith({
    List<AdminStoryView>? pending,
    List<ReportedStory>? reports,
    bool? loading,
    Set<String>? processing,
    String? error,
  }) =>
      ModerationState(
        pending: pending ?? this.pending,
        reports: reports ?? this.reports,
        loading: loading ?? this.loading,
        processing: processing ?? this.processing,
        error: error,
      );
}

final moderationControllerProvider =
    NotifierProvider<ModerationController, ModerationState>(ModerationController.new);

class ModerationController extends Notifier<ModerationState> {
  @override
  ModerationState build() {
    Future.microtask(load);
    return const ModerationState();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final api = ref.read(lifeStoriesApiProvider);
      final results = await Future.wait([api.pending(), api.reports()]);
      state = state.copyWith(
        pending: results[0] as List<AdminStoryView>,
        reports: results[1] as List<ReportedStory>,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> approve(String id) async {
    await _act(id, () => ref.read(lifeStoriesApiProvider).approve(id));
  }

  Future<void> reject(String id) async {
    await _act(id, () => ref.read(lifeStoriesApiProvider).reject(id));
  }

  Future<void> _act(String id, Future<void> Function() action) async {
    state = state.copyWith(processing: {...state.processing, id});
    try {
      await action();
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(processing: state.processing.difference({id}));
    }
  }
}
