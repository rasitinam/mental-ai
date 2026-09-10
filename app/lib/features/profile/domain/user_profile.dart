/// Mirrors the backend's `/profile` response. `diagnoses` holds catalog
/// slugs the person selected themselves — the app never fills this in on
/// its own. `age` is derived server-side from [birthYear] so it can't go
/// stale in storage.
class UserProfile {
  final String id;
  final String displayName;
  final String? email;
  final String language;
  final int? birthYear;
  final int? age;
  final List<String> diagnoses;
  final bool isAdmin;
  final bool hasAvatar;

  /// "everyone" | "following" — who may open a DM request. Kept as the
  /// raw string the API uses: the only thing the app does with it is
  /// show which of two rows is ticked and send the other one back.
  final String dmPolicy;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.language,
    required this.birthYear,
    required this.age,
    required this.diagnoses,
    required this.isAdmin,
    required this.hasAvatar,
    required this.dmPolicy,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        displayName: json['display_name'] as String,
        email: json['email'] as String?,
        language: json['language'] as String? ?? 'tr',
        birthYear: json['birth_year'] as int?,
        age: json['age'] as int?,
        diagnoses: (json['diagnoses'] as List<dynamic>? ?? []).cast<String>(),
        isAdmin: json['is_admin'] as bool? ?? false,
        hasAvatar: json['has_avatar'] as bool? ?? false,
        dmPolicy: json['dm_policy'] as String? ?? 'everyone',
      );
}
