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
  /// ISO-639-1-ish code the backend detected at submission — compared
  /// against the viewer's own app language to decide whether the feed
  /// offers a translated copy. See `StoriesController.translationFor`.
  final String language;
  final String diagnosisSlug;
  final StoryStatus status;
  final bool crisisFlag;
  final DateTime createdAt;
  final bool anonymous;
  final int upvotes;
  final bool viewerUpvoted;

  /// Null for an anonymous story — the backend doesn't send an id to
  /// click through to, not just no name to render.
  final String? authorUserId;
  final String? authorDisplayName;
  final bool authorHasAvatar;

  const LifeStory({
    required this.id,
    required this.body,
    this.language = 'tr',
    required this.diagnosisSlug,
    required this.status,
    required this.crisisFlag,
    required this.createdAt,
    this.anonymous = true,
    this.upvotes = 0,
    this.viewerUpvoted = false,
    this.authorUserId,
    this.authorDisplayName,
    this.authorHasAvatar = false,
  });

  /// `/stories` (the feed) adds the vote tally and, when the author
  /// signed it, their identity. No status or crisis flag: every entry
  /// there is already approved.
  factory LifeStory.fromPublicJson(Map<String, dynamic> json) => LifeStory(
        id: json['id'] as String,
        body: json['body'] as String,
        language: json['language'] as String? ?? 'tr',
        diagnosisSlug: json['diagnosis_slug'] as String? ?? '',
        status: StoryStatus.approved,
        crisisFlag: false,
        createdAt: DateTime.parse(json['created_at'] as String),
        anonymous: json['anonymous'] as bool? ?? true,
        upvotes: json['upvotes'] as int? ?? 0,
        viewerUpvoted: json['viewer_upvoted'] as bool? ?? false,
        authorUserId: json['author_user_id'] as String?,
        authorDisplayName: json['author_display_name'] as String?,
        authorHasAvatar: json['author_has_avatar'] as bool? ?? false,
      );

  /// `/stories/mine` returns the full record, including status.
  factory LifeStory.fromJson(Map<String, dynamic> json) => LifeStory(
        id: json['id'] as String,
        body: json['body'] as String,
        diagnosisSlug: json['diagnosis_slug'] as String? ?? '',
        status: _statusFromJson(json['status'] as String),
        crisisFlag: json['crisis_flag'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        anonymous: json['anonymous'] as bool? ?? true,
      );

  /// Local echo of a vote, so the row updates on tap instead of waiting
  /// for the feed to be refetched.
  LifeStory withVote({required bool upvoted}) => LifeStory(
        id: id,
        body: body,
        language: language,
        diagnosisSlug: diagnosisSlug,
        status: status,
        crisisFlag: crisisFlag,
        createdAt: createdAt,
        anonymous: anonymous,
        upvotes: upvotes + (upvoted ? 1 : -1),
        viewerUpvoted: upvoted,
        authorUserId: authorUserId,
        authorDisplayName: authorDisplayName,
        authorHasAvatar: authorHasAvatar,
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
