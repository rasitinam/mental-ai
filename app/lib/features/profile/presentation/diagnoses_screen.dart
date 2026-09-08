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
///
/// Performance shapes this screen more than any other in the app: the
/// catalog is twenty categories holding about a hundred and thirty
/// conditions. Three things keep it smooth, and removing any one of them
/// brought the jank back:
///   - the category list is built lazily, so only visible cards exist;
///   - a category's rows are built when it is opened, not before;
///   - each row watches only its own checkbox, so ticking one rebuilds one
///     row instead of the entire catalog.
class DiagnosesScreen extends ConsumerWidget {
  const DiagnosesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(profileControllerProvider.notifier);
    final categories = ref.watch(categoriesProvider);
    final palette = AppPalette.of(context);

    // Narrow watches: the screen frame doesn't rebuild when a checkbox
    // changes, only when one of these three actually moves.
    final loading = ref.watch(profileControllerProvider.select((s) => s.loading));
    final saving = ref.watch(profileControllerProvider.select((s) => s.saving));
    final error = ref.watch(profileControllerProvider.select((s) => s.error));

    ref.listen(profileControllerProvider.select((s) => s.saved), (previous, next) {
      if (next && previous != true) {
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
        data: (data) => loading
            ? Center(child: CircularProgressIndicator(color: palette.accent))
            : _CategoryList(categories: data, palette: palette, l10n: l10n),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(error, style: TextStyle(color: palette.warning)),
              ),
            AppPrimaryButton(
              label: l10n.commonSave,
              loading: saving,
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
  final AppPalette palette;
  final AppLocalizations l10n;

  const _CategoryList({
    required this.categories,
    required this.palette,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    // itemCount is categories + 1 so the explanatory note scrolls with the
    // list instead of forcing a second scrollable around it.
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: categories.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: GlassSurface(
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
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _CategoryTile(
            category: categories[index - 1],
            palette: palette,
            l10n: l10n,
          ),
        );
      },
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final DisorderCategory category;
  final AppPalette palette;
  final AppLocalizations l10n;

  const _CategoryTile({
    required this.category,
    required this.palette,
    required this.l10n,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  /// Rows are only built while the tile is open. `ExpansionTile` builds its
  /// children whether or not they are visible, so without this the screen
  /// would construct every condition in the catalog on first paint.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return GlassSurface(
      radius: 22,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          onExpansionChanged: (value) => setState(() => _expanded = value),
          title: Text(
            '${widget.category.emoji}  ${widget.category.name}',
            style: AppTypography.subheadline.copyWith(color: palette.textPrimary),
          ),
          subtitle: _SelectedCount(category: widget.category, palette: palette, l10n: widget.l10n),
          iconColor: palette.accent,
          collapsedIconColor: palette.textTertiary,
          children: _expanded
              ? [
                  for (final disorder in widget.category.disorders)
                    _DisorderCheckbox(
                      slug: disorder.slug,
                      name: disorder.name,
                      palette: palette,
                    ),
                ]
              : const [],
        ),
      ),
    );
  }
}

/// Watches only this category's count, so ticking a box in one category
/// leaves every other subtitle untouched.
class _SelectedCount extends ConsumerWidget {
  final DisorderCategory category;
  final AppPalette palette;
  final AppLocalizations l10n;

  const _SelectedCount({required this.category, required this.palette, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      profileControllerProvider.select(
        (state) => category.disorders.where((d) => state.diagnoses.contains(d.slug)).length,
      ),
    );

    if (count == 0) return const SizedBox.shrink();

    return Text(
      l10n.diagnosesSelectedCount(count),
      style: AppTypography.caption.copyWith(color: palette.accent),
    );
  }
}

/// One row, watching one boolean. This is what makes ticking a box cost a
/// single-row rebuild rather than a rebuild of the whole catalog.
class _DisorderCheckbox extends ConsumerWidget {
  final String slug;
  final String name;
  final AppPalette palette;

  const _DisorderCheckbox({required this.slug, required this.name, required this.palette});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      profileControllerProvider.select((state) => state.diagnoses.contains(slug)),
    );

    return CheckboxListTile(
      value: selected,
      onChanged: (_) => ref.read(profileControllerProvider.notifier).toggle(slug),
      title: Text(
        name,
        style: AppTypography.subheadline.copyWith(color: palette.textSecondary),
      ),
      activeColor: palette.accent,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }
}
