/// Mirrors `mental_domain::Insight` — a short, research-backed card
/// distilled from freshly-ingested articles by the background research
/// service (see `apps/server/src/scheduler.rs`).
class Insight {
  final String id;
  final String title;
  final String body;
  /// The language the card was written in, sent by the backend rather than
  /// assumed here — compared against the reader's app language to decide
  /// whether to offer a translation.
  final String language;
  final List<String> tags;
  final String? category;
  final DateTime createdAt;

  const Insight({
    required this.id,
    required this.title,
    required this.body,
    this.language = 'tr',
    required this.tags,
    required this.category,
    required this.createdAt,
  });

  factory Insight.fromJson(Map<String, dynamic> json) => Insight(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        language: json['language'] as String? ?? 'tr',
        tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
        category: json['category'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// One card's translated text, as returned by `/insights/:id/translate`.
class InsightTranslation {
  final String title;
  final String body;

  const InsightTranslation({required this.title, required this.body});

  factory InsightTranslation.fromJson(Map<String, dynamic> json) => InsightTranslation(
        title: json['title'] as String,
        body: json['body'] as String,
      );
}
