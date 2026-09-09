import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/life_stories_api.dart';
import '../domain/life_story.dart';

class StoriesState {
  final List<LifeStory> feed;
  final List<LifeStory> mine;
  final bool loadingFeed;
  final bool loadingMine;
  final bool submitting;
  final bool submitted;
  final String? error;

  const StoriesState({
    this.feed = const [],
    this.mine = const [],
    this.loadingFeed = true,
    this.loadingMine = true,
    this.submitting = false,
    this.submitted = false,
    this.error,
  });

  StoriesState copyWith({
    List<LifeStory>? feed,
    List<LifeStory>? mine,
    bool? loadingFeed,
    bool? loadingMine,
    bool? submitting,
    bool? submitted,
    String? error,
  }) =>
      StoriesState(
        feed: feed ?? this.feed,
        mine: mine ?? this.mine,
        loadingFeed: loadingFeed ?? this.loadingFeed,
        loadingMine: loadingMine ?? this.loadingMine,
        submitting: submitting ?? this.submitting,
        submitted: submitted ?? this.submitted,
        error: error,
      );
}

final storiesControllerProvider =
    NotifierProvider<StoriesController, StoriesState>(StoriesController.new);

class StoriesController extends Notifier<StoriesState> {
  @override
  StoriesState build() {
    Future.microtask(loadFeed);
    Future.microtask(loadMine);
    return const StoriesState();
  }

  Future<void> loadFeed() async {
    state = state.copyWith(loadingFeed: true, error: null);
    try {
      final feed = await ref.read(lifeStoriesApiProvider).feed();
      state = state.copyWith(feed: feed, loadingFeed: false);
    } catch (e) {
      state = state.copyWith(loadingFeed: false, error: e.toString());
    }
  }

  Future<void> loadMine() async {
    state = state.copyWith(loadingMine: true);
    try {
      final mine = await ref.read(lifeStoriesApiProvider).mine();
      state = state.copyWith(mine: mine, loadingMine: false);
    } catch (e) {
      state = state.copyWith(loadingMine: false, error: e.toString());
    }
  }

  Future<bool> submit({required String body, required bool consent}) async {
    state = state.copyWith(submitting: true, submitted: false, error: null);
    try {
      await ref.read(lifeStoriesApiProvider).submit(body: body, consent: consent);
      state = state.copyWith(submitting: false, submitted: true);
      await loadMine();
      return true;
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
      return false;
    }
  }

  Future<void> withdraw(String id) async {
    try {
      await ref.read(lifeStoriesApiProvider).withdraw(id);
      await loadMine();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> report(String id, {String? note}) async {
    try {
      await ref.read(lifeStoriesApiProvider).report(id, note: note);
      return true;
    } catch (_) {
      return false;
    }
  }
}
