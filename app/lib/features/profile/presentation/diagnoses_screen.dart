import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/data/catalog_api.dart';
import '../../catalog/domain/disorder_category.dart';
import 'profile_controller.dart';

/// Self-reported diagnoses. Nothing here assesses anyone — it exists so
/// someone can tell the app what they already know, which then shows up as
/// context in reports and chat instead of the app guessing.
class DiagnosesScreen extends ConsumerWidget {
  const DiagnosesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);
    final categories = ref.watch(categoriesProvider);
    final palette = AppPalette.of(context);

    ref.listen(profileControllerProvider, (prev, next) {
      if (next.saved && prev?.saved != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.diagnosesSaved)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.diagnosesTitle)),
      body: categories.when(
        loading: () => Center(child: CircularProgressIndicator(color: palette.accent)),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text(l10n.diagnosesLoadFailed,
                style: AppTypography.subheadline.copyWith(color: palette.warning)),
          ),
        ),
        data: (data) => _CategoryList(
          categories: data,
          selected: state.diagnoses,
          loading: state.loading,
          palette: palette,
          l10n: l10n,
          onToggle: controller.toggle,
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(state.error!, style: TextStyle(color: palette.warning)),
              ),
            AppPrimaryButton(
              label: l10n.commonSave,
              loading: state.saving,
              onPressed: controller.save,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<DisorderCategory> categories;
  final Set<String> selected;
  final bool loading;
  final AppPalette palette;
  final AppLocalizations l10n;
  final ValueChanged<String> onToggle;

  const _CategoryList({
    required this.categories,
    required this.selected,
    required this.loading,
    required this.palette,
    required this.l10n,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(child: CircularProgressIndicator(color: palette.accent));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        GlassSurface(
          radius: 22,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: palette.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.diagnosesNote,
                  style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (final category in categories)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassSurface(
              radius: 22,
              padding: EdgeInsets.zero,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 18),
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  title: Text(
                    '${category.emoji}  ${category.name}',
                    style: AppTypography.subheadline.copyWith(color: palette.textPrimary),
                  ),
                  subtitle: _selectedCount(category) == 0
                      ? null
                      : Text(
                          l10n.diagnosesSelectedCount(_selectedCount(category)),
                          style: AppTypography.caption.copyWith(color: palette.accent),
                        ),
                  iconColor: palette.accent,
                  collapsedIconColor: palette.textTertiary,
                  children: [
                    for (final disorder in category.disorders)
                      CheckboxListTile(
                        value: selected.contains(disorder.slug),
                        onChanged: (_) => onToggle(disorder.slug),
                        title: Text(
                          disorder.name,
                          style: AppTypography.subheadline.copyWith(color: palette.textSecondary),
                        ),
                        activeColor: palette.accent,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  int _selectedCount(DisorderCategory category) =>
      category.disorders.where((d) => selected.contains(d.slug)).length;
}
