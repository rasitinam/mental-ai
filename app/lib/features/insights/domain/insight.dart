/// Mirrors `mental_domain::Insight` — a short, research-backed card
/// distilled from freshly-ingested articles by the background research
/// service (see `apps/server/src/scheduler.rs`).
class Insight {
  final String id;
  final String title;
  final String body;
  final List<String> tags;
  final DateTime createdAt;

  const Insight({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.createdAt,
  });

  factory Insight.fromJson(Map<String, dynamic> json) => Insight(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
