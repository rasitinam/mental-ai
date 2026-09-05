import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/journal_api.dart';

class JournalState {
  final bool submitting;
  final bool submitted;
  final String? error;

  const JournalState({this.submitting = false, this.submitted = false, this.error});

  JournalState copyWith({bool? submitting, bool? submitted, String? error}) => JournalState(
        submitting: submitting ?? this.submitting,
        submitted: submitted ?? this.submitted,
        error: error,
      );
}

final journalControllerProvider =
    NotifierProvider<JournalController, JournalState>(JournalController.new);

class JournalController extends Notifier<JournalState> {
  @override
  JournalState build() => const JournalState();

  Future<void> submit(String body) async {
    if (body.trim().isEmpty) return;
    state = state.copyWith(submitting: true, error: null);
    try {
      await ref.read(journalApiProvider).addEntry(body: body.trim());
      state = state.copyWith(submitting: false, submitted: true);
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
    }
  }

  void reset() => state = const JournalState();
}
