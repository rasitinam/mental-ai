import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/network/error_messages.dart';
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
      body: SafeArea(
        bottom: false,
        child: categories.when(
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
      ),
      bottomNavigationBar: Padding(
        // This screen's own bottom bar renders behind `HomeShell`'s floating tab
        // bar (`extendBody: true`); `bottomClearance` lifts the Save button clear.
        padding: EdgeInsets.fromLTRB(22, 0, 22, bottomClearance(context, gap: 12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(friendlyErrorMessage(l10n, error), style: TextStyle(color: palette.warning)),
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
    final total = categories.fold<int>(0, (sum, c) => sum + c.disorders.length);

    // itemCount is categories + a header and a footer, so both scroll with
    // the list instead of forcing a second scrollable around it.
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      itemCount: categories.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SquareIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 14),
                  Text(l10n.diagnosesTitle,
                      style: AppTypography.title3.copyWith(color: palette.textPrimary)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  l10n.diagnosesNote,
                  style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }

        if (index == categories.length + 1) {
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.diagnosesCatalogSize(categories.length, total),
              style: AppTypography.footnote.copyWith(color: palette.textSecondary),
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
      radius: 16,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          onExpansionChanged: (value) => setState(() => _expanded = value),
          leading: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.category.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                height: 1,
                fontWeight: FontWeight.w700,
                color: palette.accent,
              ),
            ),
          ),
          title: Text(
            widget.category.name,
            style: AppTypography.label
                .copyWith(color: palette.textPrimary, fontWeight: FontWeight.w600),
          ),
          trailing: _SelectedCount(category: widget.category, palette: palette),
          children: _expanded
              ? [
                  for (final disorder in widget.category.disorders)
                    _DisorderRow(
                      slug: disorder.slug,
                      name: disorder.name,
                      palette: palette,
                      last: disorder == widget.category.disorders.last,
                    ),
                ]
              : const [],
        ),
      ),
    );
  }
}

/// Watches only this category's count, so ticking a box in one category
/// leaves every other badge untouched.
class _SelectedCount extends ConsumerWidget {
  final DisorderCategory category;
  final AppPalette palette;

  const _SelectedCount({required this.category, required this.palette});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      profileControllerProvider.select(
        (state) => category.disorders.where((d) => state.diagnoses.contains(d.slug)).length,
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (count > 0)
          Container(
            constraints: const BoxConstraints(minWidth: 22),
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.accent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11.5,
                height: 1,
                fontWeight: FontWeight.w600,
                color: AppPalette.of(context).onAccent,
              ),
            ),
          ),
        const SizedBox(width: 8),
        Icon(Icons.expand_more_rounded, size: 20, color: palette.textTertiary),
      ],
    );
  }
}

/// One row, watching one boolean. This is what makes ticking a box cost a
/// single-row rebuild rather than a rebuild of the whole catalog.
class _DisorderRow extends ConsumerWidget {
  final String slug;
  final String name;
  final AppPalette palette;
  final bool last;

  const _DisorderRow({
    required this.slug,
    required this.name,
    required this.palette,
    required this.last,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      profileControllerProvider.select((state) => state.diagnoses.contains(slug)),
    );

    return InkWell(
      onTap: () => ref.read(profileControllerProvider.notifier).toggle(slug),
      child: Container(
        constraints: const BoxConstraints(minHeight: 46),
        decoration: last
            ? null
            : BoxDecoration(border: Border(bottom: BorderSide(color: palette.separator))),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? palette.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: selected ? null : Border.all(color: palette.textTertiary, width: 1.5),
              ),
              child: selected
                  ? Icon(Icons.check_rounded, size: 15, color: AppPalette.of(context).onAccent)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name,
                  style: AppTypography.subheadline.copyWith(color: palette.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}
