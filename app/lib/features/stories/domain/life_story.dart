enum StoryStatus { pending, approved, rejected }

StoryStatus _statusFromJson(String raw) => switch (raw) {
      'approved' => StoryStatus.approved,
      'rejected' => StoryStatus.rejected,
      _ => StoryStatus.pending,
    };

/// One person's own account of their mental-health journey, submitted for
/// the public guide. Mirrors the backend's `LifeStory` — see
/// `mental_domain::life_story` for why there's no separate medication
/// field.
class LifeStory {
  final String id;
  final String body;
  final StoryStatus status;
  final bool crisisFlag;
  final DateTime createdAt;

  const LifeStory({
    required this.id,
    required this.body,
    required this.status,
    required this.crisisFlag,
    required this.createdAt,
  });

  /// `/stories` (the public feed) returns id/body/created_at only — no
  /// status or crisis flag, since every entry there is already approved.
  factory LifeStory.fromPublicJson(Map<String, dynamic> json) => LifeStory(
        id: json['id'] as String,
        body: json['body'] as String,
        status: StoryStatus.approved,
        crisisFlag: false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  /// `/stories/mine` returns the full record, including status.
  factory LifeStory.fromJson(Map<String, dynamic> json) => LifeStory(
        id: json['id'] as String,
        body: json['body'] as String,
        status: _statusFromJson(json['status'] as String),
        crisisFlag: json['crisis_flag'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// A submission as an admin sees it while moderating — identity included.
class AdminStoryView {
  final String id;
  final String userId;
  final String displayName;
  final String body;
  final StoryStatus status;
  final bool crisisFlag;
  final DateTime createdAt;

  const AdminStoryView({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.body,
    required this.status,
    required this.crisisFlag,
    required this.createdAt,
  });

  /// Every account's `display_name` defaults to the same placeholder and
  /// is rarely changed, so it doesn't actually distinguish submitters in
  /// the moderation queue — a short, stable handle derived from the id
  /// does. Purely a display choice; nothing is sent or stored under it.
  String get handle => 'kullanıcı_${(userId.hashCode.abs() % 1000).toString().padLeft(3, '0')}';

  factory AdminStoryView.fromJson(Map<String, dynamic> json) => AdminStoryView(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String,
        body: json['body'] as String,
        status: _statusFromJson(json['status'] as String),
        crisisFlag: json['crisis_flag'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// An already-published story a reader flagged for re-review.
class ReportedStory {
  final String reportId;
  final String? note;
  final DateTime reportedAt;
  final AdminStoryView story;

  const ReportedStory({
    required this.reportId,
    required this.note,
    required this.reportedAt,
    required this.story,
  });

  factory ReportedStory.fromJson(Map<String, dynamic> json) => ReportedStory(
        reportId: json['report_id'] as String,
        note: json['note'] as String?,
        reportedAt: DateTime.parse(json['reported_at'] as String),
        story: AdminStoryView.fromJson(json['story'] as Map<String, dynamic>),
      );
}
