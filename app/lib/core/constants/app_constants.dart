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

  // Apple requires the Hearth Plus paywall to link to a real, hosted
  // Privacy Policy and Terms of Use (App Store Review Guideline 3.1.2).
  // This draft must be shared publicly (the artifact's own Share menu)
  // before a real submission — Apple's reviewer opens it without being
  // signed into claude.ai. Override with --dart-define if it moves to a
  // permanent, self-hosted URL later; the paywall hides a link rather
  // than opening a blank page while either is empty.
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://claude.ai/code/artifact/2658cf1d-f5f7-4aee-b646-4c0ab1b9649e',
  );
  static const String termsOfUseUrl = String.fromEnvironment(
    'TERMS_OF_USE_URL',
    defaultValue: 'https://claude.ai/code/artifact/2658cf1d-f5f7-4aee-b646-4c0ab1b9649e',
  );


  static const String prefsUserIdKey = 'mental_ai.user_id';
  static const String prefsLanguageKey = 'mental_ai.language';
  static const String prefsThemeModeKey = 'mental_ai.theme_mode';
  static const String prefsSessionTokenKey = 'mental_ai.session_token';
  static const String prefsSessionExpiresAtKey = 'mental_ai.session_expires_at';
}
