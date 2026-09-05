import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mood_controller.dart';

/// Mood check-in on a 2D valence/arousal pad instead of a single "1-5
/// stars" scalar — lets someone log "calm and content" as a different
/// point from "content and excited" rather than collapsing both to the
/// same score.
class MoodScreen extends ConsumerWidget {
  const MoodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moodControllerProvider);
    final controller = ref.read(moodControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Şu an nasılsın?')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Enerji (uyarılmışlık)', style: Theme.of(context).textTheme.labelLarge),
            Slider(
              value: state.arousal,
              min: -1,
              max: 1,
              label: state.arousal.toStringAsFixed(2),
              onChanged: controller.setArousal,
            ),
            const SizedBox(height: 16),
            Text('Keyif (valans)', style: Theme.of(context).textTheme.labelLarge),
            Slider(
              value: state.valence,
              min: -1,
              max: 1,
              label: state.valence.toStringAsFixed(2),
              onChanged: controller.setValence,
            ),
            const SizedBox(height: 32),
            if (state.error != null)
              Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (state.submitted) const Text('Kaydedildi. Teşekkürler!'),
            const Spacer(),
            FilledButton(
              onPressed: state.submitting ? null : () => controller.submit(),
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
