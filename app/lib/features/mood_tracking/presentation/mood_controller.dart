import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mood_api.dart';

class MoodState {
  final double valence;
  final double arousal;
  final bool submitting;
  final bool submitted;
  final String? error;

  const MoodState({
    this.valence = 0,
    this.arousal = 0,
    this.submitting = false,
    this.submitted = false,
    this.error,
  });

  MoodState copyWith({
    double? valence,
    double? arousal,
    bool? submitting,
    bool? submitted,
    String? error,
  }) =>
      MoodState(
        valence: valence ?? this.valence,
        arousal: arousal ?? this.arousal,
        submitting: submitting ?? this.submitting,
        submitted: submitted ?? this.submitted,
        error: error,
      );
}

final moodControllerProvider = NotifierProvider<MoodController, MoodState>(MoodController.new);

class MoodController extends Notifier<MoodState> {
  @override
  MoodState build() => const MoodState();

  void setValence(double v) => state = state.copyWith(valence: v, submitted: false);
  void setArousal(double v) => state = state.copyWith(arousal: v, submitted: false);

  Future<void> submit({String? note}) async {
    state = state.copyWith(submitting: true, error: null);
    try {
      await ref.read(moodApiProvider).addMood(
            valence: state.valence,
            arousal: state.arousal,
            note: note,
          );
      state = state.copyWith(submitting: false, submitted: true);
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
    }
  }
}
