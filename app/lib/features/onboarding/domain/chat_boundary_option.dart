import '../../../l10n/app_localizations.dart';

/// One selectable "please don't do this" rule, mirroring a slug in the
/// backend's `mental_domain::chat_boundary`. The slug is the contract —
/// the label and the line under it are UI copy, and the directive the
/// model actually receives lives server-side, so wording can change here
/// without changing how the model behaves.
class ChatBoundaryOption {
  final String slug;
  final String label;
  final String description;

  const ChatBoundaryOption({
    required this.slug,
    required this.label,
    required this.description,
  });
}

List<ChatBoundaryOption> chatBoundaryOptions(AppLocalizations l10n) => [
      ChatBoundaryOption(
        slug: 'no_advice',
        label: l10n.boundaryNoAdvice,
        description: l10n.boundaryNoAdviceBody,
      ),
      ChatBoundaryOption(
        slug: 'no_referrals',
        label: l10n.boundaryNoReferrals,
        description: l10n.boundaryNoReferralsBody,
      ),
      ChatBoundaryOption(
        slug: 'no_toxic_positivity',
        label: l10n.boundaryNoToxicPositivity,
        description: l10n.boundaryNoToxicPositivityBody,
      ),
      ChatBoundaryOption(
        slug: 'no_questions',
        label: l10n.boundaryNoQuestions,
        description: l10n.boundaryNoQuestionsBody,
      ),
      ChatBoundaryOption(
        slug: 'no_clinical_terms',
        label: l10n.boundaryNoClinicalTerms,
        description: l10n.boundaryNoClinicalTermsBody,
      ),
      ChatBoundaryOption(
        slug: 'no_religious',
        label: l10n.boundaryNoReligious,
        description: l10n.boundaryNoReligiousBody,
      ),
      ChatBoundaryOption(
        slug: 'no_tough_love',
        label: l10n.boundaryNoToughLove,
        description: l10n.boundaryNoToughLoveBody,
      ),
      ChatBoundaryOption(
        slug: 'no_history_callbacks',
        label: l10n.boundaryNoHistoryCallbacks,
        description: l10n.boundaryNoHistoryCallbacksBody,
      ),
    ];

/// Longest note the backend accepts (`MAX_BOUNDARY_NOTE_LEN`) — enforced
/// here too so the field stops at the limit instead of failing on save.
const kBoundaryNoteMaxLength = 280;
