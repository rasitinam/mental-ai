import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/data/profile_api.dart';
import '../storage/local_prefs.dart';

/// Tells the backend the device's current offset from UTC whenever a
/// session starts, so the evening check-in reminder arrives at 21:00 on
/// this person's clock rather than the server's.
///
/// Sent on every launch rather than once: a trip abroad or a
/// daylight-saving change should correct itself the next time the app is
/// opened, without anyone visiting a settings screen. Best-effort — a
/// failure just leaves the previous offset in place.
void syncUtcOffset(ProviderContainer container) {
  Future<void> send() async {
    try {
      await container
          .read(profileApiProvider)
          .setPreferences(utcOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes);
    } catch (_) {}
  }

  container.listen<String?>(sessionTokenProvider, (previous, next) {
    if (next != null && previous != next) send();
  });

  if (container.read(sessionTokenProvider) != null) send();
}
