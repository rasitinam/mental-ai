import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

/// Dials [number] and, when the device cannot place a call (an iPad or a phone
/// without a SIM: `launchUrl` answers `false`), says so instead of doing
/// nothing. A silent crisis button is the worst kind of broken.
Future<void> callEmergency(BuildContext context, String number) async {
  var opened = false;
  try {
    opened = await launchUrl(Uri(scheme: 'tel', path: number));
  } catch (_) {
    // Treated the same as a device that cannot call.
  }
  if (opened || !context.mounted) return;

  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.emergencyCallUnavailable(number))));
}
