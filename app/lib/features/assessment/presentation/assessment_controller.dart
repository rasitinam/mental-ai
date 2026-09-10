import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/assessment_api.dart';
import '../domain/assessment_result.dart';

const int kPhq9QuestionCount = 9;
const int kGad7QuestionCount = 7;
const int kAssessmentQuestionCount = kPhq9QuestionCount + kGad7QuestionCount;

class AssessmentState {
  final List<int?> answers;
  final int step;
  final bool submitting;
  final String? error;
  final AssessmentResult? result;

  const AssessmentState({
    required this.answers,
    this.step = 0,
    this.submitting = false,
    this.error,
    this.result,
  });

  factory AssessmentState.initial() =>
      AssessmentState(answers: List<int?>.filled(kAssessmentQuestionCount, null));

  int? get currentAnswer => answers[step];
  bool get isFirstStep => step == 0;
  bool get isLastStep => step == kAssessmentQuestionCount - 1;

  AssessmentState copyWith({
    List<int?>? answers,
    int? step,
    bool? submitting,
    String? error,
    bool clearError = false,
    AssessmentResult? result,
  }) =>
      AssessmentState(
        answers: answers ?? this.answers,
        step: step ?? this.step,
        submitting: submitting ?? this.submitting,
        error: clearError ? null : (error ?? this.error),
        result: result ?? this.result,
      );
}

final assessmentControllerProvider =
    NotifierProvider.autoDispose<AssessmentController, AssessmentState>(AssessmentController.new);

/// Drives the 16-question PHQ-9 + GAD-7 flow: one question on screen at a
/// time, answers held locally until the last one is picked, then submitted
/// as a single call — there's no partial-progress save, since re-entering
/// the flow from the top costs at most sixteen taps. `autoDispose` so
/// leaving the flow (skip, back button, completing it) always starts the
/// next visit fresh rather than resuming a half-answered attempt.
class AssessmentController extends AutoDisposeNotifier<AssessmentState> {
  @override
  AssessmentState build() => AssessmentState.initial();

  /// Records the current step's answer, then advances to the next
  /// question — or, on the last question, submits the whole set.
  Future<void> selectAndAdvance(int value) async {
    final next = [...state.answers];
    next[state.step] = value;
    state = state.copyWith(answers: next, clearError: true);

    if (state.isLastStep) {
      await submit();
    } else {
      await Future.delayed(const Duration(milliseconds: 180));
      state = state.copyWith(step: state.step + 1);
    }
  }

  void goBack() {
    if (state.step > 0) {
      state = state.copyWith(step: state.step - 1);
    }
  }

  Future<void> submit() async {
    final answers = state.answers;
    if (answers.any((a) => a == null)) return;

    state = state.copyWith(submitting: true, clearError: true);
    try {
      final result = await ref.read(assessmentApiProvider).submit(
            phq9Answers: answers.sublist(0, kPhq9QuestionCount).cast<int>(),
            gad7Answers: answers.sublist(kPhq9QuestionCount).cast<int>(),
          );
      state = state.copyWith(submitting: false, result: result);
      ref.invalidate(latestAssessmentProvider);
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
    }
  }
}
