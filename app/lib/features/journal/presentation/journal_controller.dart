import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_prefs.dart';
import '../data/journal_api.dart';
import '../domain/journal_entry.dart';

class JournalState {
  final List<JournalEntry> entries;
  final bool loading;
  final bool submitting;
  final bool submitted;
  final String? error;

  /// When the next entry becomes available. `null` means no cooldown is
  /// known (nothing written yet, or the last one is older than a day).
  final DateTime? cooldownUntil;

  const JournalState({
    this.entries = const [],
    this.loading = true,
    this.submitting = false,
    this.submitted = false,
    this.error,
    this.cooldownUntil,
  });

  bool get isOnCooldown => cooldownUntil != null && cooldownUntil!.isAfter(DateTime.now());

  JournalState copyWith({
    List<JournalEntry>? entries,
    bool? loading,
    bool? submitting,
    bool? submitted,
    String? error,
    DateTime? cooldownUntil,
  }) =>
      JournalState(
        entries: entries ?? this.entries,
        loading: loading ?? this.loading,
        submitting: submitting ?? this.submitting,
        submitted: submitted ?? this.submitted,
        error: error,
        cooldownUntil: cooldownUntil ?? this.cooldownUntil,
      );
}

final journalControllerProvider =
    NotifierProvider<JournalController, JournalState>(JournalController.new);

class JournalController extends Notifier<JournalState> {
  @override
  JournalState build() {
    // Watched so an account switch reloads that account's own archive.
    ref.watch(sessionTokenProvider);
    Future.microtask(load);
    return const JournalState();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final entries = await ref.read(journalApiProvider).list();
      state = state.copyWith(
        entries: entries,
        loading: false,
        // The archive is newest-first, so the head is also what the
        // cooldown is measured from — no separate request needed.
        cooldownUntil:
            entries.isEmpty ? null : entries.first.createdAt.add(const Duration(hours: 24)),
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> submit(String body) async {
    if (body.trim().isEmpty) return;
    state = state.copyWith(submitting: true, error: null);
    try {
      await ref.read(journalApiProvider).addEntry(body: body.trim());
      await load();
      state = state.copyWith(submitting: false, submitted: true);
    } on JournalCooldownException catch (e) {
      state = state.copyWith(submitting: false, cooldownUntil: e.retryAfter);
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
    }
  }

  /// Clears the one-shot "saved" flag after the screen has reacted to it,
  /// without discarding the loaded archive.
  void acknowledgeSubmitted() => state = state.copyWith(submitted: false);
}
