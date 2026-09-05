/// Mirrors the backend's `SessionResponse` (returned by both
/// `/auth/register` and `/auth/login`).
class Session {
  final String userId;
  final String token;
  final DateTime expiresAt;

  const Session({required this.userId, required this.token, required this.expiresAt});

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        userId: json['user_id'] as String,
        token: json['token'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
      );
}
