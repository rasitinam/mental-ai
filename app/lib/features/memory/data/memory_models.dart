/// One short thing Hearth has learned about someone, from their own entries.
/// `kind` is one of the backend's fixed set ("theme", "trigger", "helps",
/// "context", "goal") — see `mental_domain::memory` — and is only ever used
/// to pick the right icon/label here, never shown to the person as-is.
class MemoryItem {
  final String kind;
  final String text;

  const MemoryItem({required this.kind, required this.text});

  factory MemoryItem.fromJson(Map<String, dynamic> json) =>
      MemoryItem(kind: json['kind'] as String, text: json['text'] as String);
}

class PersonMemory {
  final bool enabled;
  final List<MemoryItem> items;
  final DateTime? generatedAt;

  const PersonMemory({required this.enabled, required this.items, this.generatedAt});

  factory PersonMemory.fromJson(Map<String, dynamic> json) => PersonMemory(
        enabled: json['enabled'] as bool,
        items: (json['items'] as List).map((i) => MemoryItem.fromJson(i as Map<String, dynamic>)).toList(),
        generatedAt: json['generated_at'] == null ? null : DateTime.parse(json['generated_at'] as String),
      );
}
