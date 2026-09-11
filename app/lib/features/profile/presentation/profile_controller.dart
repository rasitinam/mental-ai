import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/locale_controller.dart';
import '../../../core/storage/local_prefs.dart';
import '../data/profile_api.dart';
import '../domain/user_profile.dart';

class ProfileState {
  /// Catalog slugs currently selected in the editor. Held locally while the
  /// person is ticking boxes and only sent on save.
  final Set<String> diagnoses;
  final String displayName;
  final String? email;
  final String language;
  final int? birthYear;
  final int? age;
  final bool loading;
  final bool saving;
  final bool saved;
  final Object? error;

  const ProfileState({
    this.diagnoses = const {},
    this.displayName = '',
    this.email,
    this.language = 'tr',
    this.birthYear,
    this.age,
    this.loading = true,
    this.saving = false,
    this.saved = false,
    this.error,
  });

  ProfileState copyWith({
    Set<String>? diagnoses,
    String? displayName,
    String? email,
    String? language,
    int? birthYear,
    int? age,
    bool? loading,
    bool? saving,
    bool? saved,
    Object? error,
  }) =>
      ProfileState(
        diagnoses: diagnoses ?? this.diagnoses,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        language: language ?? this.language,
        birthYear: birthYear ?? this.birthYear,
        age: age ?? this.age,
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
      state = _fromProfile(profile);
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
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
      state = _fromProfile(profile).copyWith(saved: true);
      ref.invalidate(myProfileProvider);
    } catch (e) {
      state = state.copyWith(saving: false, error: e);
    }
  }

  /// Language switches locally first so the UI changes immediately, then is
  /// stored on the account — the backend needs it to generate reports and
  /// chat replies in the same language, not just to label them.
  Future<void> savePreferences({
    String? displayName,
    String? language,
    int? birthYear,
    String? dmPolicy,
  }) async {
    state = state.copyWith(saving: true, error: null);

    final previousLanguage = ref.read(localeControllerProvider).languageCode;
    if (language != null) {
      await ref.read(localeControllerProvider.notifier).setLanguage(language);
    }

    try {
      final profile = await ref
          .read(profileApiProvider)
          .setPreferences(
            displayName: displayName,
            language: language,
            birthYear: birthYear,
            dmPolicy: dmPolicy,
          );
      state = _fromProfile(profile).copyWith(saved: true);
      ref.invalidate(myProfileProvider);
    } catch (e) {
      // Put the interface back in the language the account is still stored
      // in. Leaving it switched after a failed save is worse than not
      // switching at all: the app would be speaking one language while
      // every generated report and chat reply came back in the other.
      if (language != null && language != previousLanguage) {
        await ref.read(localeControllerProvider.notifier).setLanguage(previousLanguage);
      }
      state = state.copyWith(saving: false, error: e);
    }
  }

  /// Picks a photo from the gallery and uploads it. A cancelled picker
  /// (`pickImage` returning `null`) is silently a no-op, same as tapping
  /// away from any other picker — not an error.
  Future<void> pickAndUploadAvatar() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
    if (file == null) return;

    state = state.copyWith(saving: true, error: null);
    try {
      final profile = await ref.read(profileApiProvider).uploadAvatar(file);
      state = _fromProfile(profile).copyWith(saved: true);
      ref.invalidate(avatarBytesProvider);
      ref.invalidate(myProfileProvider);
    } catch (e) {
      state = state.copyWith(saving: false, error: e);
    }
  }

  ProfileState _fromProfile(UserProfile profile) => ProfileState(
        diagnoses: profile.diagnoses.toSet(),
        displayName: profile.displayName,
        email: profile.email,
        language: profile.language,
        birthYear: profile.birthYear,
        age: profile.age,
        loading: false,
        saving: false,
      );
}
