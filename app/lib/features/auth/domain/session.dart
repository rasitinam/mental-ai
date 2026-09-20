/// Mirrors the backend's `SessionResponse` (returned by `/auth/register` and
/// `/auth/login`) and `AppleSessionResponse` (`/auth/apple`).
class Session {
  final String userId;
  final String token;
  final DateTime expiresAt;

  /// Only `/auth/apple` says so: that call may have just created the
  /// account, in which case the app routes into onboarding like a fresh
  /// email registration.
  final bool isNewAccount;

  const Session({
    required this.userId,
    required this.token,
    required this.expiresAt,
    this.isNewAccount = false,
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        userId: json['user_id'] as String,
        token: json['token'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
        isNewAccount: json['is_new_account'] as bool? ?? false,
      );
}
