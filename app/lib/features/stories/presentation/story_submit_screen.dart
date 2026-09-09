import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/data/catalog_api.dart';
import '../../catalog/domain/disorder_category.dart';
import 'stories_controller.dart';

/// The write flow for a life story. Free text only — no separate
/// "medication" field — and shown together with a disclaimer and a
/// consent checkbox that must be ticked before submitting. See
/// `mental_domain::life_story` on the backend for why: this is meant to
/// read as one person's own account, not a searchable directory of who
/// recommends which drug.
class StorySubmitScreen extends ConsumerStatefulWidget {
  const StorySubmitScreen({super.key});

  @override
  ConsumerState<StorySubmitScreen> createState() => _StorySubmitScreenState();
}

class _StorySubmitScreenState extends ConsumerState<StorySubmitScreen> {
  final _controller = TextEditingController();
  bool _consent = false;
  Disorder? _diagnosis;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDiagnosis() async {
    final categories = await ref.read(categoriesProvider.future);
    if (!mounted) return;
    final picked = await showModalBottomSheet<Disorder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DiagnosisPickerSheet(categories: categories),
    );
    if (picked != null) setState(() => _diagnosis = picked);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final diagnosis = _diagnosis;
    if (diagnosis == null) return;
    final ok = await ref.read(storiesControllerProvider.notifier).submit(
          body: _controller.text.trim(),
          diagnosisSlug: diagnosis.slug,
          consent: _consent,
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.storiesSubmitSuccess)));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.commonError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final state = ref.watch(storiesControllerProvider);
    final canSubmit =
        _consent && _diagnosis != null && _controller.text.trim().isNotEmpty && !state.submitting;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.storiesSubmitTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  l10n.storiesDisclaimer,
                  style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              GlassSurface(
                radius: 20,
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: _pickDiagnosis,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.local_offer_outlined, size: 18, color: palette.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _diagnosis?.name ?? l10n.storiesPickDiagnosis,
                            style: AppTypography.subheadline.copyWith(
                              color: _diagnosis != null ? palette.textPrimary : palette.textTertiary,
                              fontWeight: _diagnosis != null ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 20, color: palette.textTertiary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GlassSurface(
                radius: 26,
                padding: const EdgeInsets.all(4),
                child: TextField(
                  controller: _controller,
                  maxLines: 10,
                  minLines: 8,
                  onChanged: (_) => setState(() {}),
                  textAlignVertical: TextAlignVertical.top,
                  style: AppTypography.body.copyWith(color: palette.textPrimary),
                  cursorColor: palette.accent,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(18),
                    hintText: l10n.storiesSubmitHint,
                    hintStyle: AppTypography.body.copyWith(color: palette.textTertiary),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  l10n.storiesCharCount(_controller.text.length),
                  style: AppTypography.caption.copyWith(color: palette.textTertiary),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => setState(() => _consent = !_consent),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _consent,
                        onChanged: (v) => setState(() => _consent = v ?? false),
                        activeColor: palette.accent,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            l10n.storiesConsentLabel,
                            style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.storiesModerationNotice,
                style: AppTypography.footnote.copyWith(color: palette.textTertiary),
              ),
              const SizedBox(height: 20),
              if (state.error != null) ...[
                Text(state.error!, style: TextStyle(color: palette.warning), textAlign: TextAlign.center),
                const SizedBox(height: 12),
              ],
              AppPrimaryButton(
                label: l10n.storiesSubmit,
                loading: state.submitting,
                onPressed: canSubmit ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single-select diagnosis picker. Same lazy-expand shape as
/// `DiagnosesScreen`'s category list and for the same reason — the
/// catalog is ~130 conditions, and building every row up front is what
/// caused the jank that screen was rewritten to avoid.
class _DiagnosisPickerSheet extends StatelessWidget {
  final List<DisorderCategory> categories;
  const _DiagnosisPickerSheet({required this.categories});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: palette.canvasBottom,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.separator,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Text(
                  l10n.storiesPickDiagnosis,
                  style: AppTypography.headline.copyWith(color: palette.textPrimary),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: categories.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PickerCategoryTile(category: categories[i], palette: palette),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PickerCategoryTile extends StatefulWidget {
  final DisorderCategory category;
  final AppPalette palette;
  const _PickerCategoryTile({required this.category, required this.palette});

  @override
  State<_PickerCategoryTile> createState() => _PickerCategoryTileState();
}

class _PickerCategoryTileState extends State<_PickerCategoryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return GlassSurface(
      radius: 18,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(bottom: 6),
          onExpansionChanged: (v) => setState(() => _expanded = v),
          title: Text(
            '${widget.category.emoji}  ${widget.category.name}',
            style: AppTypography.subheadline.copyWith(color: palette.textPrimary),
          ),
          iconColor: palette.accent,
          collapsedIconColor: palette.textTertiary,
          children: _expanded
              ? [
                  for (final disorder in widget.category.disorders)
                    ListTile(
                      dense: true,
                      title: Text(
                        disorder.name,
                        style: AppTypography.subheadline.copyWith(color: palette.textSecondary),
                      ),
                      onTap: () => Navigator.of(context).pop(disorder),
                    ),
                ]
              : const [],
        ),
      ),
    );
  }
}
