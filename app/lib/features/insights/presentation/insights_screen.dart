import 'package:flutter/material.dart';

/// Placeholder for the research-backed insight feed. Will read from the
/// backend's `/insights` endpoint (surfacing `mental_domain::Insight`
/// records distilled from `research-ingest`'s corpus) once that route is
/// wired up server-side.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İçgörüler')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Araştırma tabanlı içgörüler burada listelenecek.\n'
            'Arka planda çalışan araştırma servisi yeni makaleler topladıkça '
            'bu ekran güncellenecek.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
