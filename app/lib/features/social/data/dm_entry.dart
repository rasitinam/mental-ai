import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True for the one moment between tapping Settings' "Mesajlar" row and
/// landing on the Messages tab. `HomeShell`'s back-button handling reads
/// this once, at the Messages tab's root, to decide where Android back
/// should go: Settings (this case) or Stories (reached directly from the
/// tab bar). Cleared the instant it's read, and also whenever the
/// Messages tab icon itself is tapped, so only "just came from the
/// Profile row" counts — not "was on Settings a few taps ago".
final dmEnteredFromSettingsProvider = StateProvider<bool>((ref) => false);
