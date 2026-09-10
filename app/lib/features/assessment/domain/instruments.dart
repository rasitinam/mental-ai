import '../../../l10n/app_localizations.dart';

/// One question and the answer choices it's presented with — the choices
/// vary by instrument (and, within AUDIT-C, by question), so each question
/// carries its own rather than the flow assuming one shared 4-option set.
class AssessmentQuestion {
  final String text;
  final List<String> options;
  const AssessmentQuestion({required this.text, required this.options});
}

/// One screening instrument: a section label the question flow shows
/// while working through it, an optional one-time framing line (PC-PTSD-5
/// needs to explain what kind of event it's asking about before its first
/// question), and its questions in order.
class AssessmentInstrument {
  final String key;
  final String sectionLabel;
  final String? intro;
  final List<AssessmentQuestion> questions;
  const AssessmentInstrument({
    required this.key,
    required this.sectionLabel,
    this.intro,
    required this.questions,
  });
}

const kPhq9QuestionCount = 9;
const kGad7QuestionCount = 7;
const kWho5QuestionCount = 5;
const kPhq15QuestionCount = 15;
const kPtsd5QuestionCount = 5;
const kAuditcQuestionCount = 3;
const kCageaidQuestionCount = 4;
const kAssessmentQuestionCount = kPhq9QuestionCount +
    kGad7QuestionCount +
    kWho5QuestionCount +
    kPhq15QuestionCount +
    kPtsd5QuestionCount +
    kAuditcQuestionCount +
    kCageaidQuestionCount;

/// The seven instruments in the order the flow presents them (and the
/// order [AssessmentController.submit] slices `answers` by) — same order
/// the backend's `WellbeingAssessment` fields and `AssessmentResult`
/// expect. Free-standing function rather than a const list because every
/// question and option comes from [AppLocalizations].
List<AssessmentInstrument> buildInstruments(AppLocalizations l10n) {
  final phqGadOptions = [
    l10n.assessmentAnswer0,
    l10n.assessmentAnswer1,
    l10n.assessmentAnswer2,
    l10n.assessmentAnswer3,
  ];
  final yesNo = [l10n.assessmentAnswerNo, l10n.assessmentAnswerYes];
  final who5Options = [
    l10n.who5Answer0,
    l10n.who5Answer1,
    l10n.who5Answer2,
    l10n.who5Answer3,
    l10n.who5Answer4,
    l10n.who5Answer5,
  ];
  final phq15Options = [l10n.phq15Answer0, l10n.phq15Answer1, l10n.phq15Answer2];

  return [
    AssessmentInstrument(
      key: 'phq9',
      sectionLabel: l10n.assessmentSectionMood,
      questions: [
        AssessmentQuestion(text: l10n.phq9Q1, options: phqGadOptions),
        AssessmentQuestion(text: l10n.phq9Q2, options: phqGadOptions),
        AssessmentQuestion(text: l10n.phq9Q3, options: phqGadOptions),
        AssessmentQuestion(text: l10n.phq9Q4, options: phqGadOptions),
        AssessmentQuestion(text: l10n.phq9Q5, options: phqGadOptions),
        AssessmentQuestion(text: l10n.phq9Q6, options: phqGadOptions),
        AssessmentQuestion(text: l10n.phq9Q7, options: phqGadOptions),
        AssessmentQuestion(text: l10n.phq9Q8, options: phqGadOptions),
        AssessmentQuestion(text: l10n.phq9Q9, options: phqGadOptions),
      ],
    ),
    AssessmentInstrument(
      key: 'gad7',
      sectionLabel: l10n.assessmentSectionAnxiety,
      questions: [
        AssessmentQuestion(text: l10n.gad7Q1, options: phqGadOptions),
        AssessmentQuestion(text: l10n.gad7Q2, options: phqGadOptions),
        AssessmentQuestion(text: l10n.gad7Q3, options: phqGadOptions),
        AssessmentQuestion(text: l10n.gad7Q4, options: phqGadOptions),
        AssessmentQuestion(text: l10n.gad7Q5, options: phqGadOptions),
        AssessmentQuestion(text: l10n.gad7Q6, options: phqGadOptions),
        AssessmentQuestion(text: l10n.gad7Q7, options: phqGadOptions),
      ],
    ),
    AssessmentInstrument(
      key: 'who5',
      sectionLabel: l10n.assessmentSectionWellbeing,
      questions: [
        AssessmentQuestion(text: l10n.who5Q1, options: who5Options),
        AssessmentQuestion(text: l10n.who5Q2, options: who5Options),
        AssessmentQuestion(text: l10n.who5Q3, options: who5Options),
        AssessmentQuestion(text: l10n.who5Q4, options: who5Options),
        AssessmentQuestion(text: l10n.who5Q5, options: who5Options),
      ],
    ),
    AssessmentInstrument(
      key: 'phq15',
      sectionLabel: l10n.assessmentSectionSomatic,
      questions: [
        AssessmentQuestion(text: l10n.phq15Q1, options: phq15Options),
        AssessmentQuestion(text: l10n.phq15Q2, options: phq15Options),
        AssessmentQuestion(text: l10n.phq15Q3, options: phq15Options),
        AssessmentQuestion(text: l10n.phq15Q4, options: phq15Options),
        AssessmentQuestion(text: l10n.phq15Q5, options: phq15Options),
        AssessmentQuestion(text: l10n.phq15Q6, options: phq15Options),
        AssessmentQuestion(text: l10n.phq15Q7, options: phq15Options),
        AssessmentQuestion(text: l10n.phq15Q8, options: phq15Options),
        AssessmentQuestion(text: l10n.phq15Q9, options: phq15Options),
        AssessmentQuestion(text: l10n.phq15Q10, options: phq15Options),
        AssessmentQuestion(text: l10n.phq15Q11, options: phq15Options),
        AssessmentQuestion(text: l10n.phq15Q12, options: phq15Options),
        AssessmentQuestion(text: l10n.phq15Q13, options: phq15Options),
        AssessmentQuestion(text: l10n.phq15Q14, options: phq15Options),
        AssessmentQuestion(text: l10n.phq15Q15, options: phq15Options),
      ],
    ),
    AssessmentInstrument(
      key: 'ptsd5',
      sectionLabel: l10n.assessmentSectionPtsd,
      intro: l10n.assessmentPtsd5Intro,
      questions: [
        AssessmentQuestion(text: l10n.ptsd5Q1, options: yesNo),
        AssessmentQuestion(text: l10n.ptsd5Q2, options: yesNo),
        AssessmentQuestion(text: l10n.ptsd5Q3, options: yesNo),
        AssessmentQuestion(text: l10n.ptsd5Q4, options: yesNo),
        AssessmentQuestion(text: l10n.ptsd5Q5, options: yesNo),
      ],
    ),
    AssessmentInstrument(
      key: 'auditc',
      sectionLabel: l10n.assessmentSectionAlcohol,
      questions: [
        AssessmentQuestion(
          text: l10n.auditcQ1,
          options: [
            l10n.auditcQ1Opt0,
            l10n.auditcQ1Opt1,
            l10n.auditcQ1Opt2,
            l10n.auditcQ1Opt3,
            l10n.auditcQ1Opt4,
          ],
        ),
        AssessmentQuestion(
          text: l10n.auditcQ2,
          options: [
            l10n.auditcQ2Opt0,
            l10n.auditcQ2Opt1,
            l10n.auditcQ2Opt2,
            l10n.auditcQ2Opt3,
            l10n.auditcQ2Opt4,
          ],
        ),
        AssessmentQuestion(
          text: l10n.auditcQ3,
          options: [
            l10n.auditcQ3Opt0,
            l10n.auditcQ3Opt1,
            l10n.auditcQ3Opt2,
            l10n.auditcQ3Opt3,
            l10n.auditcQ3Opt4,
          ],
        ),
      ],
    ),
    AssessmentInstrument(
      key: 'cageaid',
      sectionLabel: l10n.assessmentSectionSubstance,
      questions: [
        AssessmentQuestion(text: l10n.cageaidQ1, options: yesNo),
        AssessmentQuestion(text: l10n.cageaidQ2, options: yesNo),
        AssessmentQuestion(text: l10n.cageaidQ3, options: yesNo),
        AssessmentQuestion(text: l10n.cageaidQ4, options: yesNo),
      ],
    ),
  ];
}
