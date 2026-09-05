import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';

/// First-run screen. Its only real job is stating the product's
/// boundaries up front, in plain language, before any data is collected —
/// see `mental-llm-connector::prompts::SAFETY_SYSTEM_PROMPT` on the
/// backend for the enforced version of the same framing.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.self_improvement_rounded, size: 32, color: palette.accent),
              ),
              const SizedBox(height: 28),
              Text(
                'Mental AI',
                style: AppTypography.largeTitle.copyWith(color: palette.textPrimary),
              ),
              const SizedBox(height: 10),
              Text(
                'Ruh halini takip et, günlük tut, güncel araştırmalara '
                'dayanan öz-farkındalık raporları al.',
                style: AppTypography.body.copyWith(color: palette.textSecondary),
              ),
              const SizedBox(height: 24),
              GlassSurface(
                radius: 22,
                blurSigma: 20,
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 20, color: palette.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Mental AI lisanslı bir psikolog, psikiyatrist ya da tıbbi bir '
                        'cihaz değildir; tanı koymaz. Kriz anında lütfen 112\'yi veya '
                        'bir uzmanı ara.',
                        style: AppTypography.subheadline.copyWith(color: palette.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AppPrimaryButton(
                label: 'Anladım, devam et',
                onPressed: () => context.go('/report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
