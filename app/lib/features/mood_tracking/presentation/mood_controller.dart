import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_prefs.dart';
import '../data/mood_api.dart';
import '../domain/mood_emotion.dart';

class MoodState {
  final double valence;
  final double arousal;
  /// Which words are currently picked. Kept alongside the two axes
  /// rather than instead of them: the words are how someone answers,
  /// the axes are what gets stored and compared over time.
  final Set<String> emotions;
  final bool submitting;
  final bool submitted;
  final Object? error;
  /// When the next check-in becomes available. `null` while unknown
  /// (still loading) or once the cooldown has passed.
  final DateTime? cooldownUntil;
  final bool loadingCooldown;

  const MoodState({
    this.valence = 0,
    this.arousal = 0,
    this.emotions = const {},
    this.submitting = false,
    this.submitted = false,
    this.error,
    this.cooldownUntil,
    this.loadingCooldown = true,
  });

  bool get isOnCooldown => cooldownUntil != null && cooldownUntil!.isAfter(DateTime.now());

  MoodState copyWith({
    double? valence,
    double? arousal,
    Set<String>? emotions,
    bool? submitting,
    bool? submitted,
    Object? error,
    DateTime? cooldownUntil,
    bool clearCooldown = false,
    bool? loadingCooldown,
  }) =>
      MoodState(
        valence: valence ?? this.valence,
        arousal: arousal ?? this.arousal,
        emotions: emotions ?? this.emotions,
        submitting: submitting ?? this.submitting,
        submitted: submitted ?? this.submitted,
        error: error,
        cooldownUntil: clearCooldown ? null : (cooldownUntil ?? this.cooldownUntil),
        loadingCooldown: loadingCooldown ?? this.loadingCooldown,
      );
}

final moodControllerProvider = NotifierProvider<MoodController, MoodState>(MoodController.new);

class MoodController extends Notifier<MoodState> {
  @override
  MoodState build() {
    // Watched so an account switch re-checks that account's own cooldown
    // instead of carrying over the previous account's.
    ref.watch(sessionTokenProvider);
    Future.microtask(_loadCooldown);
    return const MoodState();
  }

  Future<void> _loadCooldown() async {
    try {
      final latest = await ref.read(moodApiProvider).latest();
      state = state.copyWith(
        cooldownUntil: latest?.recordedAt.add(const Duration(hours: 24)),
        loadingCooldown: false,
      );
    } catch (_) {
      // Unknown cooldown state shouldn't block the form — worst case the
      // backend rejects the submit with the real answer.
      state = state.copyWith(loadingCooldown: false);
    }
  }

  /// Both axes in one write. A drag moves along one axis at a time but
  /// the same call covers both, and setting them separately emitted two
  /// states per pointer event — at drag speed that was over a hundred
  /// rebuilds a second for one gesture.
  void setMood(double valence, double arousal) =>
      state = state.copyWith(valence: valence, arousal: arousal, submitted: false);

  /// Picking words re-derives the two axes from their average. Dragging
  /// afterwards still wins — [setMood] doesn't clear the words, so the
  /// selection stays visible as the reason the dot started where it did.
  void toggleEmotion(String key) {
    HapticFeedback.selectionClick();
    final next = Set<String>.from(state.emotions);
    if (!next.remove(key)) next.add(key);

    final position = averageOf(next);
    state = state.copyWith(
      emotions: next,
      valence: position.valence,
      arousal: position.arousal,
      submitted: false,
    );
  }

  Future<void> submit({String? note}) async {
    state = state.copyWith(submitting: true, error: null);
    try {
      await ref.read(moodApiProvider).addMood(
            valence: state.valence,
            arousal: state.arousal,
            note: note,
          );
      HapticFeedback.mediumImpact();
      state = state.copyWith(
        submitting: false,
        submitted: true,
        cooldownUntil: DateTime.now().add(const Duration(hours: 24)),
      );
    } on MoodCooldownException catch (e) {
      state = state.copyWith(submitting: false, cooldownUntil: e.retryAfter);
    } catch (e) {
      state = state.copyWith(submitting: false, error: e);
    }
  }
}
