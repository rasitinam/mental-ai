import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_prefs.dart';
import '../data/profile_api.dart';

class ProfileState {
  /// Catalog slugs currently selected in the editor. Held locally while the
  /// person is ticking boxes and only sent on save.
  final Set<String> diagnoses;
  final bool loading;
  final bool saving;
  final bool saved;
  final String? error;

  const ProfileState({
    this.diagnoses = const {},
    this.loading = true,
    this.saving = false,
    this.saved = false,
    this.error,
  });

  ProfileState copyWith({
    Set<String>? diagnoses,
    bool? loading,
    bool? saving,
    bool? saved,
    String? error,
  }) =>
      ProfileState(
        diagnoses: diagnoses ?? this.diagnoses,
        loading: loading ?? this.loading,
        saving: saving ?? this.saving,
        saved: saved ?? this.saved,
        error: error,
      );
}

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);

class ProfileController extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    ref.watch(sessionTokenProvider);
    Future.microtask(load);
    return const ProfileState();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final profile = await ref.read(profileApiProvider).profile();
      state = state.copyWith(diagnoses: profile.diagnoses.toSet(), loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void toggle(String slug) {
    final next = Set<String>.from(state.diagnoses);
    if (!next.remove(slug)) next.add(slug);
    state = state.copyWith(diagnoses: next, saved: false);
  }

  Future<void> save() async {
    state = state.copyWith(saving: true, error: null);
    try {
      final profile = await ref.read(profileApiProvider).setDiagnoses(state.diagnoses.toList());
      state = state.copyWith(diagnoses: profile.diagnoses.toSet(), saving: false, saved: true);
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
    }
  }
}
