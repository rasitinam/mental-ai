/// Someone else's account as this app shows it. Deliberately carries
/// nothing clinical — mirrors the backend's `PublicProfile`.
class PublicProfile {
  final String userId;
  final String displayName;
  final bool hasAvatar;
  final int storyCount;
  final int followerCount;
  final int followingCount;
  final bool viewerFollows;

  /// Whether the viewer is allowed to *open* a conversation. The backend
  /// resolves the other person's DM policy so the app doesn't have to
  /// re-implement the rule.
  final bool acceptsDm;

  const PublicProfile({
    required this.userId,
    required this.displayName,
    required this.hasAvatar,
    required this.storyCount,
    required this.followerCount,
    required this.followingCount,
    required this.viewerFollows,
    required this.acceptsDm,
  });

  factory PublicProfile.fromJson(Map<String, dynamic> json) => PublicProfile(
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String,
        hasAvatar: json['has_avatar'] as bool? ?? false,
        storyCount: json['story_count'] as int? ?? 0,
        followerCount: json['follower_count'] as int? ?? 0,
        followingCount: json['following_count'] as int? ?? 0,
        viewerFollows: json['viewer_follows'] as bool? ?? false,
        acceptsDm: json['accepts_dm'] as bool? ?? false,
      );

  PublicProfile withFollow(bool following) => PublicProfile(
        userId: userId,
        displayName: displayName,
        hasAvatar: hasAvatar,
        storyCount: storyCount,
        followerCount: followerCount + (following ? 1 : -1),
        followingCount: followingCount,
        viewerFollows: following,
        acceptsDm: acceptsDm,
      );
}

/// A row in a follower/following list.
class UserCard {
  final String userId;
  final String displayName;
  final bool hasAvatar;

  const UserCard({
    required this.userId,
    required this.displayName,
    required this.hasAvatar,
  });

  factory UserCard.fromJson(Map<String, dynamic> json) => UserCard(
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String,
        hasAvatar: json['has_avatar'] as bool? ?? false,
      );
}

enum DmStatus { pending, accepted }

/// One conversation in the inbox or the request list. There is no unread
/// count and no seen state — see `migrations/0011_social.sql`.
class DmThread {
  final String id;
  final String otherUserId;
  final String otherDisplayName;
  final bool otherHasAvatar;
  final DmStatus status;

  /// True when the viewer opened this thread, which is what separates
  /// "they want to talk to you" from "waiting for them".
  final bool startedByMe;
  final DateTime lastMessageAt;
  final String? lastMessage;

  const DmThread({
    required this.id,
    required this.otherUserId,
    required this.otherDisplayName,
    required this.otherHasAvatar,
    required this.status,
    required this.startedByMe,
    required this.lastMessageAt,
    required this.lastMessage,
  });

  factory DmThread.fromJson(Map<String, dynamic> json) => DmThread(
        id: json['id'] as String,
        otherUserId: json['other_user_id'] as String,
        otherDisplayName: json['other_display_name'] as String,
        otherHasAvatar: json['other_has_avatar'] as bool? ?? false,
        status: json['status'] == 'accepted' ? DmStatus.accepted : DmStatus.pending,
        startedByMe: json['started_by_me'] as bool? ?? false,
        lastMessageAt: DateTime.parse(json['last_message_at'] as String),
        lastMessage: json['last_message'] as String?,
      );
}

class DmMessage {
  final String id;
  final String senderId;
  final bool mine;
  final String body;
  final DateTime createdAt;

  const DmMessage({
    required this.id,
    required this.senderId,
    required this.mine,
    required this.body,
    required this.createdAt,
  });

  factory DmMessage.fromJson(Map<String, dynamic> json) => DmMessage(
        id: json['id'] as String,
        senderId: json['sender_id'] as String,
        mine: json['mine'] as bool? ?? false,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// One row on the "Blocked people" screen. A block made from an anonymous
/// story carries no name or user id — the app never learns who the author is,
/// so the list must not either.
class BlockedPerson {
  /// The block's own id, which is what unblocking takes.
  final String id;
  final String? displayName;
  final String? userId;
  final bool hasAvatar;
  final bool anonymous;

  const BlockedPerson({
    required this.id,
    required this.displayName,
    required this.userId,
    required this.hasAvatar,
    required this.anonymous,
  });

  factory BlockedPerson.fromJson(Map<String, dynamic> json) => BlockedPerson(
        id: json['id'] as String,
        displayName: json['display_name'] as String?,
        userId: json['user_id'] as String?,
        hasAvatar: json['has_avatar'] as bool? ?? false,
        anonymous: json['anonymous'] as bool? ?? false,
      );
}
