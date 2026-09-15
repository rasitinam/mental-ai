import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';

/// Voice in and out, for the places people write at length: the journal,
/// the check-in note and the chat.
///
/// Speech recognition runs on the device's own recognizer (Android's
/// speech service, Apple's Speech framework, the browser's Web Speech API)
/// — no audio is uploaded by this app, and what comes back is plain text
/// that lands in the same field typing would have filled. Nothing is sent
/// until the person presses send themselves, so a misheard word is always
/// theirs to fix first.

/// One recognizer for the whole app: the plugin wraps a single native
/// service, and two widgets each holding their own would fight over it.
final speechToTextProvider = Provider<SpeechToText>((ref) => SpeechToText());

/// One text-to-speech engine for the whole app, so starting to read one
/// message stops whichever message was already being read.
final readAloudProvider = ChangeNotifierProvider<ReadAloud>((ref) => ReadAloud());

class ReadAloud extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  String? _speakingId;
  bool _configured = false;

  /// Which message (by caller-chosen id) is being read right now, if any.
  String? get speakingId => _speakingId;

  Future<void> toggle(String id, String text, String languageCode) async {
    if (_speakingId == id) {
      await stop();
      return;
    }

    await _tts.stop();
    if (!_configured) {
      _tts.setCompletionHandler(_clear);
      _tts.setCancelHandler(_clear);
      _tts.setErrorHandler((_) => _clear());
      _configured = true;
    }

    await _tts.setLanguage(languageCode == 'en' ? 'en-US' : 'tr-TR');
    // A touch slower than the engine default: this reads replies about
    // how someone is doing, not a news bulletin.
    await _tts.setSpeechRate(0.46);

    _speakingId = id;
    notifyListeners();
    await _tts.speak(_plain(text));
  }

  Future<void> stop() async {
    await _tts.stop();
    _clear();
  }

  void _clear() {
    if (_speakingId == null) return;
    _speakingId = null;
    notifyListeners();
  }

  /// Markdown the model sometimes emits (`**bold**`, bullets) would
  /// otherwise be read out as "asterisk asterisk".
  static String _plain(String text) =>
      text.replaceAll(RegExp(r'[*_#`>]+'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}

/// "Sesli oku" at the foot of an assistant message: tap to hear it, tap
/// again (or start another) to stop.
class SpeakButton extends ConsumerWidget {
  final String id;
  final String text;

  const SpeakButton({super.key, required this.id, required this.text});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final speaking = ref.watch(readAloudProvider.select((r) => r.speakingId == id));
    final color = speaking ? palette.textPrimary : palette.textSecondary;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => ref.read(readAloudProvider).toggle(id, text, Localizations.localeOf(context).languageCode),
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined, size: 17, color: color),
                const SizedBox(width: 6),
                Text(
                  speaking ? l10n.voiceStopSpeaking : l10n.voiceSpeak,
                  style: AppTypography.footnote.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum DictationStyle {
  /// A 54px rounded square in the sky color, next to a send button (chat).
  round,

  /// A "Sesle yaz" pill in a text card's footer (journal).
  pill,

  /// A 40px icon square inside a single-line field (check-in note).
  compact,
}

/// Dictates into [controller]. What was already typed is kept and the
/// spoken words are appended after it, updating live as recognition
/// refines, so talking and typing can be mixed in one entry.
class DictationButton extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final DictationStyle style;

  /// Called with the full text after every recognition update — for
  /// callers that persist a draft on change, which programmatic edits to
  /// a controller don't trigger on their own.
  final ValueChanged<String>? onChanged;

  const DictationButton({
    super.key,
    required this.controller,
    this.style = DictationStyle.round,
    this.onChanged,
  });

  @override
  ConsumerState<DictationButton> createState() => DictationButtonState();
}

class DictationButtonState extends ConsumerState<DictationButton> {
  bool _listening = false;
  String _prefix = '';

  /// Starts listening if it isn't already — for "Sesle anlat", which
  /// arrives at the journal wanting the microphone already on.
  Future<void> start() async {
    if (!_listening) await _toggle();
  }

  Future<void> _toggle() async {
    final l10n = AppLocalizations.of(context)!;
    final speech = ref.read(speechToTextProvider);

    if (_listening) {
      await speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    speech.statusListener = _onStatus;
    speech.errorListener = _onError;

    final available = speech.isAvailable ||
        await speech.initialize(onStatus: _onStatus, onError: _onError);
    if (!mounted) return;
    if (!available) {
      final permitted = await speech.hasPermission;
      if (mounted) _tell(permitted ? l10n.voiceUnavailable : l10n.voicePermissionDenied);
      return;
    }

    final existing = widget.controller.text;
    _prefix = existing.isEmpty || existing.endsWith(' ') || existing.endsWith('\n')
        ? existing
        : '$existing ';

    HapticFeedback.selectionClick();
    setState(() => _listening = true);

    final language = Localizations.localeOf(context).languageCode;
    await speech.listen(
      onResult: _onResult,
      listenOptions: SpeechListenOptions(
        localeId: language == 'en' ? 'en_US' : 'tr_TR',
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
      ),
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    final text = '$_prefix${result.recognizedWords}';
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.onChanged?.call(text);
    if (result.finalResult && _listening) setState(() => _listening = false);
  }

  void _onStatus(String status) {
    if (!mounted) return;
    if ((status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) && _listening) {
      setState(() => _listening = false);
    }
  }

  void _onError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() => _listening = false);
    final l10n = AppLocalizations.of(context)!;
    if (error.errorMsg.contains('permission')) {
      _tell(l10n.voicePermissionDenied);
    } else if (error.permanent && error.errorMsg != 'error_no_match') {
      _tell(l10n.voiceUnavailable);
    }
  }

  void _tell(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    if (_listening) ref.read(speechToTextProvider).cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final label = _listening ? l10n.voiceListening : l10n.voiceDictate;
    final icon = _listening ? Icons.stop_rounded : Icons.mic_none_rounded;

    switch (widget.style) {
      case DictationStyle.pill:
        final foreground = _listening ? palette.warningSoft : palette.onTint;
        return Semantics(
          button: true,
          child: Material(
            color: _listening ? palette.warning : palette.sky,
            borderRadius: BorderRadius.circular(100),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _toggle,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: foreground),
                      const SizedBox(width: 6),
                      Text(label, style: AppTypography.footnote.copyWith(color: foreground, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

      case DictationStyle.compact:
        return Tooltip(
          message: label,
          child: Material(
            color: _listening ? palette.warning : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _toggle,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(icon, size: 20, color: _listening ? palette.warningSoft : palette.textPrimary),
              ),
            ),
          ),
        );

      case DictationStyle.round:
        return Tooltip(
          message: label,
          child: Material(
            color: _listening ? palette.warning : palette.sky,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _toggle,
              child: SizedBox(
                width: 54,
                height: 54,
                child: Icon(icon, size: 23, color: _listening ? palette.warningSoft : palette.onTint),
              ),
            ),
          ),
        );
    }
  }
}
