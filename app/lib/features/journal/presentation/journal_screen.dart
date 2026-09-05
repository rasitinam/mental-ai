import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import 'journal_controller.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(journalControllerProvider);
    final journalController = ref.read(journalControllerProvider.notifier);
    final palette = AppPalette.of(context);

    ref.listen(journalControllerProvider, (prev, next) {
      if (next.submitted && prev?.submitted != true) {
        _controller.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Günlük kaydedildi.')),
        );
        journalController.reset();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Günlük')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GlassSurface(
                  radius: 26,
                  padding: const EdgeInsets.all(4),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: AppTypography.body.copyWith(color: palette.textPrimary),
                    cursorColor: palette.accent,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(18),
                      hintText: 'Bugün aklından ne geçti?',
                      hintStyle: AppTypography.body.copyWith(color: palette.textTertiary),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(state.error!, style: TextStyle(color: palette.warning)),
                ),
              AppPrimaryButton(
                label: 'Kaydet',
                loading: state.submitting,
                onPressed: () => journalController.submit(_controller.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
