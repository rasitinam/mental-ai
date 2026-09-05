import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';

/// First-run screen. Its only real job is stating the product's
/// boundaries up front, in plain language, before any data is collected —
/// see `mental-llm-connector::prompts::SAFETY_SYSTEM_PROMPT` on the
/// backend for the enforced version of the same framing.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.self_improvement, size: 56, color: AppColors.primary),
              const SizedBox(height: 24),
              Text('Mental AI\'a hoş geldin', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              const Text(
                'Mental AI; ruh halini takip etmene, günlük tutmana ve güncel '
                'psikoloji araştırmalarına dayanan öz-farkındalık raporları almana '
                'yardımcı olan bir arkadaştır.\n\n'
                'Önemli: Mental AI lisanslı bir psikolog, psikiyatrist ya da tıbbi '
                'bir cihaz değildir; tanı koymaz. Kriz anında lütfen 112\'yi veya '
                'bir uzmanı ara.',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/report'),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Anladım, devam et'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
