/// Mirrors `mental_domain::JournalEntry`.
class JournalEntry {
  final String id;
  final String body;
  final DateTime createdAt;

  const JournalEntry({required this.id, required this.body, required this.createdAt});

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
