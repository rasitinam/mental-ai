import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_prefs.dart';
import 'social_api.dart';

/// What the Messages tab's red dot reflects: a pending request nobody has
/// answered yet, or a message in an accepted thread since it was last
/// opened. No count, no per-thread detail — just "there's something".
class DmBadgeState {
  final bool hasPendingRequest;
  final bool hasUnreadMessage;
  const DmBadgeState({this.hasPendingRequest = false, this.hasUnreadMessage = false});

  bool get visible => hasPendingRequest || hasUnreadMessage;
}

const _lastSeenPrefsKey = 'dm_last_seen_v1';

/// There is no read-receipt column on the server by design (see
/// `mental_domain::social` — the whole point of the DM system is that
/// nobody, including the other side of the conversation, learns whether a
/// message was opened). This is purely local bookkeeping for the badge:
/// "have I, on this device, scrolled a newer message than I already saw".
/// It never leaves the device and nothing server-side reads it.
class DmBadgeNotifier extends StateNotifier<DmBadgeState> {
  final Ref _ref;
  Timer? _timer;

  DmBadgeNotifier(this._ref) : super(const DmBadgeState()) {
    unawaited(_poll());
    _timer = Timer.periodic(const Duration(seconds: 25), (_) => unawaited(_poll()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Map<String, int> _readLastSeen() {
    final raw = _ref.read(sharedPreferencesProvider).getString(_lastSeenPrefsKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as int));
  }

  Future<void> _writeLastSeen(Map<String, int> value) async {
    await _ref.read(sharedPreferencesProvider).setString(_lastSeenPrefsKey, jsonEncode(value));
  }

  Future<void> _poll() async {
    try {
      final api = _ref.read(socialApiProvider);
      final threads = await api.threads();
      final requests = await api.requests();

      final lastSeen = _readLastSeen();
      var unread = false;
      var changed = false;
      for (final thread in threads) {
        final at = thread.lastMessageAt.millisecondsSinceEpoch;
        final seen = lastSeen[thread.id];
        if (seen == null) {
          // First poll that has ever seen this thread — baseline it as
          // caught-up instead of lighting the badge for every
          // conversation that predates this feature.
          lastSeen[thread.id] = at;
          changed = true;
        } else if (at > seen) {
          unread = true;
        }
      }
      if (changed) await _writeLastSeen(lastSeen);

      if (!mounted) return;
      state = DmBadgeState(hasPendingRequest: requests.isNotEmpty, hasUnreadMessage: unread);
    } catch (_) {
      // A failed poll just leaves the badge as it was.
    }
  }

  /// Call when a thread is opened, or right after sending into one — marks
  /// it caught up so its own message doesn't keep the dot lit.
  Future<void> markSeen(String threadId) async {
    final lastSeen = _readLastSeen();
    lastSeen[threadId] = DateTime.now().millisecondsSinceEpoch;
    await _writeLastSeen(lastSeen);
    await _poll();
  }

  /// Forces an immediate re-check — used after accepting/declining a
  /// request, so the badge doesn't wait for the next timer tick.
  Future<void> refresh() => _poll();
}

final dmBadgeProvider = StateNotifierProvider<DmBadgeNotifier, DmBadgeState>((ref) {
  return DmBadgeNotifier(ref);
});
