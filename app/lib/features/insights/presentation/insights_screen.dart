import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../catalog/data/catalog_api.dart';
import '../../catalog/domain/disorder_category.dart';
import '../domain/insight.dart';
import 'insights_controller.dart';

/// Two things live on this screen, and the category selector switches
/// between them: "Genel" is the research feed the background service
/// produces, and a specific category is a reference section — the
/// conditions under it, each opening its own explainer, plus whatever
/// research cards were filed under that category.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(insightsControllerProvider);
    final controller = ref.read(insightsControllerProvider.notifier);
    final selected = ref.watch(selectedCategoryProvider);
    final categories = ref.watch(categoriesProvider);
    final palette = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('İçgörüler')),
      body: Column(
        children: [
          _CategoryStrip(
            categories: categories.valueOrNull ?? const [],
            selected: selected,
            palette: palette,
            onSelect: (slug) => ref.read(selectedCategoryProvider.notifier).state = slug,
          ),
          Expanded(
            child: RefreshIndicator(
              color: palette.accent,
              onRefresh: controller.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
                children: [
                  if (selected != null)
                    ..._categorySection(
                      context: context,
                      category: categories.valueOrNull?.where((c) => c.slug == selected).firstOrNull,
                      palette: palette,
                    ),
                  if (state.loading)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(child: CircularProgressIndicator(color: palette.accent)),
                    )
                  else if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(state.error!,
                          style: TextStyle(color: palette.warning), textAlign: TextAlign.center),
                    )
                  else if (state.insights.isEmpty)
                    _EmptyFeed(
                      palette: palette,
                      inCategory: selected != null,
                      synthesizing: state.synthesizing,
                      onSynthesizeNow: controller.synthesizeNow,
                    )
                  else ...[
                    if (selected != null) ...[
                      const SizedBox(height: 22),
                      _SectionLabel(text: 'Bu kategoriden araştırmalar', palette: palette),
                      const SizedBox(height: 10),
                    ],
                    for (final insight in state.insights)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _InsightCard(insight: insight),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _categorySection({
    required BuildContext context,
    required DisorderCategory? category,
    required AppPalette palette,
  }) {
    if (category == null) return const [];

    return [
      if (category.note != null) ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.warningSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: palette.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(category.note!,
                    style: AppTypography.footnote.copyWith(color: palette.warning)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
      _SectionLabel(text: '${category.emoji}  ${category.name}', palette: palette),
      const SizedBox(height: 10),
      GlassSurface(
        radius: 22,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < category.disorders.length; i++) ...[
              _DisorderRow(
                disorder: category.disorders[i],
                palette: palette,
                onTap: () => context.go('/insights/disorder/${category.disorders[i].slug}'),
              ),
              if (i != category.disorders.length - 1)
                Divider(height: 1, indent: 20, color: palette.separator),
            ],
          ],
        ),
      ),
    ];
  }
}

class _CategoryStrip extends StatelessWidget {
  final List<DisorderCategory> categories;
  final String? selected;
  final AppPalette palette;
  final ValueChanged<String?> onSelect;

  const _CategoryStrip({
    required this.categories,
    required this.selected,
    required this.palette,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _CategoryChip(
            label: 'Genel',
            selected: selected == null,
            palette: palette,
            onTap: () => onSelect(null),
          ),
          for (final category in categories)
            _CategoryChip(
              label: '${category.emoji} ${category.name}',
              selected: selected == category.slug,
              palette: palette,
              onTap: () => onSelect(category.slug),
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? palette.accent : palette.glassFill,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? palette.accent : palette.glassBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Text(
              label,
              style: AppTypography.footnote.copyWith(
                color: selected ? Colors.white : palette.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DisorderRow extends StatelessWidget {
  final Disorder disorder;
  final AppPalette palette;
  final VoidCallback onTap;

  const _DisorderRow({required this.disorder, required this.palette, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(disorder.name,
                  style: AppTypography.subheadline.copyWith(color: palette.textPrimary)),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: palette.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final AppPalette palette;
  const _SectionLabel({required this.text, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.caption.copyWith(color: palette.textTertiary, letterSpacing: 0.6),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final Insight insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return GlassSurface(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 16, color: palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(insight.title, style: AppTypography.headline.copyWith(color: palette.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(insight.body, style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
          if (insight.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in insight.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(10)),
                    child: Text(tag, style: AppTypography.caption.copyWith(color: palette.accent)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            DateFormat.yMMMd().format(insight.createdAt),
            style: AppTypography.caption.copyWith(color: palette.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  final AppPalette palette;
  final bool inCategory;
  final bool synthesizing;
  final VoidCallback onSynthesizeNow;

  const _EmptyFeed({
    required this.palette,
    required this.inCategory,
    required this.synthesizing,
    required this.onSynthesizeNow,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: GlassSurface(
        radius: 26,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_outlined, size: 30, color: palette.accent),
            const SizedBox(height: 14),
            Text(
              inCategory ? 'Bu kategoride henüz araştırma kartı yok' : 'Henüz bir içgörü yok',
              textAlign: TextAlign.center,
              style: AppTypography.headline.copyWith(color: palette.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              inCategory
                  ? 'Yukarıdaki başlıklardan birine dokunarak o durumla ilgili bilgi kartını '
                      'okuyabilirsin. Araştırma kartları, arka plandaki servis bu kategoride '
                      'yeni makale buldukça burada birikir.'
                  : 'Arka planda çalışan araştırma servisi yeni makaleler topladıkça bu ekran '
                      'güncellenecek. Beklemek istemezsen zaten toplanmış makalelerden şimdi bir '
                      'içgörü çıkarabilirsin.',
              textAlign: TextAlign.center,
              style: AppTypography.subheadline.copyWith(color: palette.textSecondary),
            ),
            if (!inCategory) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: AppPrimaryButton(
                  label: 'Şimdi oluştur',
                  loading: synthesizing,
                  onPressed: onSynthesizeNow,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
