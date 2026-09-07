/// Mirrors `mental_domain::User`. `diagnoses` holds catalog slugs the person
/// selected themselves — the app never fills this in on its own.
class UserProfile {
  final String id;
  final String displayName;
  final List<String> diagnoses;

  const UserProfile({required this.id, required this.displayName, required this.diagnoses});

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        displayName: json['display_name'] as String,
        diagnoses: (json['diagnoses'] as List<dynamic>? ?? []).cast<String>(),
      );
}
