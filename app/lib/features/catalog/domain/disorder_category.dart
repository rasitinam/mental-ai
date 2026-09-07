/// Mirrors `mental_domain::catalog::DisorderCategory` — the DSM-shaped
/// category tree the insights screen browses by. Served from the backend
/// rather than hardcoded here so both sides agree on slugs.
class DisorderCategory {
  final String slug;
  final String name;
  final String emoji;

  /// Caveat shown above the condition list when the list alone would
  /// misrepresent the category (currently only the paraphilic one).
  final String? note;
  final List<Disorder> disorders;

  const DisorderCategory({
    required this.slug,
    required this.name,
    required this.emoji,
    required this.note,
    required this.disorders,
  });

  factory DisorderCategory.fromJson(Map<String, dynamic> json) => DisorderCategory(
        slug: json['slug'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        note: json['note'] as String?,
        disorders: (json['disorders'] as List<dynamic>? ?? [])
            .map((e) => Disorder.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Disorder {
  final String slug;
  final String name;

  const Disorder({required this.slug, required this.name});

  factory Disorder.fromJson(Map<String, dynamic> json) =>
      Disorder(slug: json['slug'] as String, name: json['name'] as String);
}
