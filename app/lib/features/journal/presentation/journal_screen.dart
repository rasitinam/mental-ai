import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Bugün aklından ne geçti?',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (state.error != null)
              Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            FilledButton(
              onPressed: state.submitting ? null : () => journalController.submit(_controller.text),
              child: state.submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
