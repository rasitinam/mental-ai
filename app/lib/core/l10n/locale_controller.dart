import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../storage/local_prefs.dart';

/// Every language the app ships. Kept here rather than derived from the
/// generated `AppLocalizations.supportedLocales` so the picker, the stored
/// preference and what gets sent to the backend all agree on one list.
const supportedLanguages = ['tr', 'en'];

/// The active interface language.
///
/// Read from local storage first so the app opens in the right language
/// before any network call, then kept in sync with the account (the backend
/// needs it too: reports, chat replies and the daily summary are generated
/// in this language, not just labelled in it).
final localeControllerProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(AppConstants.prefsLanguageKey);
    if (stored != null && supportedLanguages.contains(stored)) {
      return Locale(stored);
    }

    // No stored choice yet: follow the device, which is what someone
    // expects on a first launch — falling back to Turkish for every locale
    // the app doesn't have translations for.
    final deviceLanguage = PlatformDispatcher.instance.locale.languageCode;
    return Locale(supportedLanguages.contains(deviceLanguage) ? deviceLanguage : 'tr');
  }

  /// Switches language locally. Persisting to the account is the profile
  /// screen's job — it already owns that request, and doing it here would
  /// fire a network call from a setter.
  Future<void> setLanguage(String code) async {
    if (!supportedLanguages.contains(code)) return;

    await ref.read(sharedPreferencesProvider).setString(AppConstants.prefsLanguageKey, code);
    state = Locale(code);
  }
}
