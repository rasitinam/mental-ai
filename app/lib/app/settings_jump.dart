import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumped by an Ayarlar button outside the Me tab. The Me tab scrolls to
/// its settings whenever this is higher than the last value it handled —
/// including when the tab is built for the first time by that same tap.
final settingsJumpProvider = StateProvider<int>((ref) => 0);
