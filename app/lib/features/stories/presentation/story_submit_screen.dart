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
import '../domain/life_story.dart';
import 'stories_controller.dart';

/// The write flow for a life story — also the edit flow: pass [editing]
/// and the form prefills from it, the button reads "save" instead of
/// "send", and the consent/moderation-notice block (already agreed to,
/// the first time this story was submitted) is replaced by a short note
/// that saving sends it back for re-review. Free text plus one required
/// diagnosis tag — no structured "medication" field, deliberately. See
/// `mental_domain::life_story` on the backend for why: this is meant to
/// read as one person's own account, not a searchable directory of who
/// recommends which drug.
class StorySubmitScreen extends ConsumerStatefulWidget {
  final LifeStory? editing;
  const StorySubmitScreen({super.key, this.editing});

  @override
  ConsumerState<StorySubmitScreen> createState() => _StorySubmitScreenState();
}

class _StorySubmitScreenState extends ConsumerState<StorySubmitScreen> {
  final _controller = TextEditingController();
  bool _consent = false;
  /// Defaults to anonymous: signing a mental-health account with your
  /// name should be something you turn on, not something you forget to
  /// turn off.
  bool _anonymous = true;
  Disorder? _diagnosis;
  bool _resolvingDiagnosis = false;

  bool get _editing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _controller.text = editing.body;
      _anonymous = editing.anonymous;
      _resolvingDiagnosis = true;
      // The form works with a full `Disorder` (for its name and picker
      // state), but a story only carries its slug — resolved once
      // against the already-cached catalog rather than added as a new
      // field on `LifeStory` just for this screen.
      ref.read(categoriesProvider.future).then((categories) {
        if (!mounted) return;
        for (final category in categories) {
          for (final disorder in category.disorders) {
            if (disorder.slug == editing.diagnosisSlug) {
              setState(() {
                _diagnosis = disorder;
                _resolvingDiagnosis = false;
              });
              return;
            }
          }
        }
        setState(() => _resolvingDiagnosis = false);
      });
    }
  }

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
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DiagnosisPickerSheet(categories: categories),
    );
    if (picked != null) setState(() => _diagnosis = picked);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final diagnosis = _diagnosis;
    if (diagnosis == null) return;
    final controller = ref.read(storiesControllerProvider.notifier);
    final ok = _editing
        ? await controller.update(
            widget.editing!.id,
            body: _controller.text.trim(),
            diagnosisSlug: diagnosis.slug,
            anonymous: _anonymous,
          )
        : await controller.submit(
            body: _controller.text.trim(),
            diagnosisSlug: diagnosis.slug,
            consent: _consent,
            anonymous: _anonymous,
          );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editing ? l10n.storiesEditSuccess : l10n.storiesSubmitSuccess)),
      );
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
    final canSubmit = (_editing || _consent) &&
        _diagnosis != null &&
        _controller.text.trim().isNotEmpty &&
        !state.submitting &&
        !_resolvingDiagnosis;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          // Inside the shell: clear the floating tab bar (see `bottomClearance`).
          padding: EdgeInsets.fromLTRB(22, 12, 22, bottomClearance(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SquareIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 14),
                  Text(_editing ? l10n.storiesEditTitle : l10n.storiesSubmitTitle,
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
                  l10n.storiesDisclaimer,
                  style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              GlassSurface(
                radius: 16,
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: _pickDiagnosis,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Icon(Icons.local_offer_outlined, size: 18, color: palette.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _diagnosis?.name ?? l10n.storiesPickDiagnosis,
                            style: AppTypography.label.copyWith(
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
              Container(
                constraints: const BoxConstraints(minHeight: 230),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.glassFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: palette.accent, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _controller,
                      maxLines: null,
                      minLines: 7,
                      onChanged: (_) => setState(() {}),
                      textAlignVertical: TextAlignVertical.top,
                      style: AppTypography.body.copyWith(color: palette.textPrimary),
                      cursorColor: palette.accent,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: l10n.storiesSubmitHint,
                        hintStyle: AppTypography.body.copyWith(color: palette.textTertiary),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.storiesCharCount(_controller.text.length),
                      style: AppTypography.caption.copyWith(color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassSurface(
                radius: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.storiesAnonymousToggle,
                              style: AppTypography.label.copyWith(color: palette.textPrimary)),
                          const SizedBox(height: 3),
                          Text(
                            _anonymous
                                ? l10n.storiesAnonymousOnBody
                                : l10n.storiesAnonymousOffBody,
                            style:
                                AppTypography.footnote.copyWith(color: palette.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: _anonymous,
                      activeThumbColor: palette.accent,
                      onChanged: (v) => setState(() => _anonymous = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_editing) ...[
                // Consent was already given the first time this story was
                // submitted — edited text is still the same account of
                // the same person's life, so this doesn't ask again. It
                // does need a new moderation pass, though, since the text
                // an admin reviewed no longer exists once it's changed.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.refresh_rounded, size: 18, color: palette.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.storiesEditNotice,
                          style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                InkWell(
                  onTap: () => setState(() => _consent = !_consent),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _consent ? palette.accent : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                            border: _consent
                                ? null
                                : Border.all(color: palette.textTertiary, width: 1.5),
                          ),
                          child: _consent
                              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.storiesConsentLabel,
                            style: AppTypography.footnote
                                .copyWith(color: palette.textPrimary, fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.storiesModerationNotice,
                  style: AppTypography.footnote.copyWith(color: palette.textSecondary, fontSize: 12),
                ),
              ],
              const SizedBox(height: 22),
              if (state.error != null) ...[
                Text(friendlyErrorMessage(l10n, state.error!),
                    style: TextStyle(color: palette.warning), textAlign: TextAlign.center),
                const SizedBox(height: 12),
              ],
              AppPrimaryButton(
                label: _editing ? l10n.storiesSaveChanges : l10n.storiesSubmit,
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
            color: palette.canvasTop,
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
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.storiesPickDiagnosis,
                    style: AppTypography.title3.copyWith(color: palette.textPrimary, fontSize: 20),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(22, 0, 22, bottomClearance(context)),
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
      radius: 16,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
          onExpansionChanged: (v) => setState(() => _expanded = v),
          title: Text(
            '${widget.category.emoji}  ${widget.category.name}',
            style: AppTypography.label.copyWith(color: palette.textPrimary),
          ),
          iconColor: palette.accent,
          collapsedIconColor: palette.textTertiary,
          children: _expanded
              ? [
                  for (final disorder in widget.category.disorders)
                    InkWell(
                      onTap: () => Navigator.of(context).pop(disorder),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          disorder.name,
                          style:
                              AppTypography.subheadline.copyWith(color: palette.textSecondary),
                        ),
                      ),
                    ),
                ]
              : const [],
        ),
      ),
    );
  }
}
