/// Mirrors the backend's `/profile` response. `diagnoses` holds catalog
/// slugs the person selected themselves — the app never fills this in on
/// its own. `age` is derived server-side from [birthYear] so it can't go
/// stale in storage.
class UserProfile {
  final String id;
  final String displayName;
  final String? email;

  /// True for accounts created with Sign in with Apple, which have no
  /// password — deleting one re-verifies with Apple instead.
  final bool signsInWithApple;
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

  /// What this person asked the app *not* to do in conversation — slugs
  /// from `mental_domain::chat_boundary`, mirrored in
  /// `chatBoundaryOptions`. Set during onboarding, editable afterwards.
  final List<String> chatBoundaries;

  /// Anything the fixed list didn't cover, in their own words.
  final String? chatBoundaryNote;

  /// The evening check-in reminder: whether it's on, and the local hour
  /// it goes out at (17-23). See `NotificationSettingsScreen`.
  final bool checkinReminderEnabled;
  final int checkinReminderHour;

  /// When the account was created, for "Hearth'te N aydır".
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.signsInWithApple = false,
    required this.language,
    required this.birthYear,
    required this.age,
    required this.diagnoses,
    required this.isAdmin,
    required this.hasAvatar,
    required this.dmPolicy,
    this.chatBoundaries = const [],
    this.chatBoundaryNote,
    this.checkinReminderEnabled = true,
    this.checkinReminderHour = 21,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        displayName: json['display_name'] as String,
        email: json['email'] as String?,
        signsInWithApple: json['signs_in_with_apple'] as bool? ?? false,
        language: json['language'] as String? ?? 'tr',
        birthYear: json['birth_year'] as int?,
        age: json['age'] as int?,
        diagnoses: (json['diagnoses'] as List<dynamic>? ?? []).cast<String>(),
        isAdmin: json['is_admin'] as bool? ?? false,
        hasAvatar: json['has_avatar'] as bool? ?? false,
        dmPolicy: json['dm_policy'] as String? ?? 'everyone',
        chatBoundaries: (json['chat_boundaries'] as List<dynamic>? ?? []).cast<String>(),
        chatBoundaryNote: json['chat_boundary_note'] as String?,
        checkinReminderEnabled: json['checkin_reminder_enabled'] as bool? ?? true,
        checkinReminderHour: json['checkin_reminder_hour'] as int? ?? 21,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),

      );
}
