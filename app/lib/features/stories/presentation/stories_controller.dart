import 'package:flutter/services.dart';
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
  final Object? error;

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
    Object? error,
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
      state = state.copyWith(loadingFeed: false, error: e);
    }
  }

  Future<void> loadMine() async {
    state = state.copyWith(loadingMine: true);
    try {
      final mine = await ref.read(lifeStoriesApiProvider).mine();
      state = state.copyWith(mine: mine, loadingMine: false);
    } catch (e) {
      state = state.copyWith(loadingMine: false, error: e);
    }
  }

  /// Reacts optimistically: the row flips on tap and only rolls back if
  /// the request fails, because waiting on a round-trip to acknowledge a
  /// tap is the kind of lag that makes a feed feel broken. Tapping the
  /// reaction that's already picked clears it instead of re-sending it.
  Future<void> setReaction(String id, String reaction) async {
    final index = state.feed.indexWhere((s) => s.id == id);
    if (index < 0) return;

    final original = state.feed[index];
    final target = original.viewerReaction == reaction ? null : reaction;

    HapticFeedback.selectionClick();
    final optimistic = [...state.feed];
    optimistic[index] = original.withReaction(target);
    state = state.copyWith(feed: optimistic);

    try {
      await ref.read(lifeStoriesApiProvider).setReaction(id, reaction: target);
    } catch (_) {
      final rolledBack = [...state.feed];
      final current = rolledBack.indexWhere((s) => s.id == id);
      if (current >= 0) {
        rolledBack[current] = original;
        state = state.copyWith(feed: rolledBack);
      }
    }
  }

  /// Optimistic, the same way as [setReaction]. Returns `false` if the
  /// request failed and the row was rolled back, so the caller can say so.
  Future<bool> setMetoo(String id, {required bool on, String? note}) async {
    final index = state.feed.indexWhere((s) => s.id == id);
    if (index < 0) return false;

    final original = state.feed[index];
    HapticFeedback.selectionClick();
    final optimistic = [...state.feed];
    optimistic[index] = original.withMetoo(on);
    state = state.copyWith(feed: optimistic);

    try {
      await ref.read(lifeStoriesApiProvider).setMetoo(id, on: on, note: note);
      return true;
    } catch (_) {
      final rolledBack = [...state.feed];
      final current = rolledBack.indexWhere((s) => s.id == id);
      if (current >= 0) {
        rolledBack[current] = original;
        state = state.copyWith(feed: rolledBack);
      }
      return false;
    }
  }

  Future<bool> submit({
    required String body,
    required String diagnosisSlug,
    required bool consent,
    required bool anonymous,
  }) async {
    state = state.copyWith(submitting: true, submitted: false, error: null);
    try {
      await ref.read(lifeStoriesApiProvider).submit(
            body: body,
            diagnosisSlug: diagnosisSlug,
            consent: consent,
            anonymous: anonymous,
          );
      state = state.copyWith(submitting: false, submitted: true);
      await loadMine();
      return true;
    } catch (e) {
      state = state.copyWith(submitting: false, error: e);
      return false;
    }
  }

  /// Edits an owned story. The backend always sends it back to `pending`
  /// on a successful edit, so the refreshed `mine` list is what tells the
  /// screen that happened — no separate "submitted" flag needed here, the
  /// updated status in the list says it.
  Future<bool> update(
    String id, {
    required String body,
    required String diagnosisSlug,
    required bool anonymous,
  }) async {
    state = state.copyWith(submitting: true, error: null);
    try {
      await ref.read(lifeStoriesApiProvider).update(
            id,
            body: body,
            diagnosisSlug: diagnosisSlug,
            anonymous: anonymous,
          );
      state = state.copyWith(submitting: false);
      await loadMine();
      return true;
    } catch (e) {
      state = state.copyWith(submitting: false, error: e);
      return false;
    }
  }

  Future<void> withdraw(String id) async {
    try {
      await ref.read(lifeStoriesApiProvider).withdraw(id);
      await loadMine();
    } catch (e) {
      state = state.copyWith(error: e);
    }
  }

  /// Blocks the story's author (without learning who they are, if the story
  /// is anonymous) and reloads the feed so their stories disappear at once.
  Future<bool> blockAuthor(String id) async {
    try {
      await ref.read(lifeStoriesApiProvider).blockAuthor(id);
      await loadFeed();
      return true;
    } catch (_) {
      return false;
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
