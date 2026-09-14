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

/// Voice in and out, for the two places people write at length: the
/// journal and the chat.
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

/// A small speaker icon under an assistant message: tap to hear it, tap
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

    return Tooltip(
      message: speaking ? l10n.voiceStopSpeaking : l10n.voiceSpeak,
      child: InkResponse(
        onTap: () => ref
            .read(readAloudProvider)
            .toggle(id, text, Localizations.localeOf(context).languageCode),
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
            size: 18,
            color: speaking ? palette.accent : palette.textTertiary,
          ),
        ),
      ),
    );
  }
}

enum DictationStyle {
  /// A 46px round button that sits next to a send button (chat).
  round,

  /// A compact "Sesle yaz" pill that sits in a text card's footer (journal).
  pill,
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
  ConsumerState<DictationButton> createState() => _DictationButtonState();
}

class _DictationButtonState extends ConsumerState<DictationButton> {
  bool _listening = false;
  String _prefix = '';

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

    if (widget.style == DictationStyle.pill) {
      final color = _listening ? palette.warning : palette.accent;
      return Material(
        color: _listening ? palette.warningSoft : palette.accentSoft,
        borderRadius: BorderRadius.circular(100),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_listening ? Icons.stop_rounded : Icons.mic_none_rounded, size: 15, color: color),
                const SizedBox(width: 5),
                Text(
                  _listening ? l10n.voiceListening : l10n.voiceDictate,
                  style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: _listening ? l10n.voiceListening : l10n.voiceDictate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _listening ? palette.warning : palette.surfaceMuted,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _toggle,
            child: Icon(
              _listening ? Icons.stop_rounded : Icons.mic_none_rounded,
              size: 21,
              color: _listening ? Colors.white : palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
