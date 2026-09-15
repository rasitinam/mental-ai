/// Central place for values that differ between local dev and a real
/// deployment. `apiBaseUrl` points at the Rust backend
/// (`backend/apps/server`) running locally by default; override with
/// `--dart-define=API_BASE_URL=...` when pointing at a deployed backend.
class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8787',
  );

  // Public pages on GitHub Pages (repo rasitinam/hearth-privacy). Apple
  // requires the Hearth Plus paywall to link to both (App Store Review
  // Guideline 3.1.2), and the first-launch consent screen links to the
  // policy. Both pages accept ?lang=tr|en.
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://rasitinam.github.io/hearth-privacy/',
  );
  static const String termsOfUseUrl = String.fromEnvironment(
    'TERMS_OF_USE_URL',
    defaultValue: 'https://rasitinam.github.io/hearth-privacy/terms.html',
  );

  static const String prefsUserIdKey = 'mental_ai.user_id';
  /// The Privacy Policy version this device accepted on the consent screen.
  static const String prefsPrivacyAcceptedKey = 'mental_ai.privacy_accepted_version';
  static const String prefsLanguageKey = 'mental_ai.language';
  static const String prefsThemeModeKey = 'mental_ai.theme_mode';
  static const String prefsSessionTokenKey = 'mental_ai.session_token';
  static const String prefsSessionExpiresAtKey = 'mental_ai.session_expires_at';
}
