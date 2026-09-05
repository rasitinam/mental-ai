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

  static const String prefsUserIdKey = 'mental_ai.user_id';
}
