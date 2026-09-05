import 'package:flutter/material.dart';

/// Placeholder for the longer-horizon (weekly/monthly) narrative produced
/// by `mental-analysis-engine::generate_life_analysis`. Needs a
/// `/life-analysis/:user_id` backend route before this can call live data.
class LifeAnalysisScreen extends StatelessWidget {
  const LifeAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yaşam Analizi')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Haftalık/aylık yaşam analizi burada görünecek.\n'
            'Yeterli ruh hali ve günlük verisi biriktikçe aktifleşir.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
