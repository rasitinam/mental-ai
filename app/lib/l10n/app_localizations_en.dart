// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Hearth';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonLoading => 'Loading';

  @override
  String get errorNoConnection =>
      'Check your internet connection and try again.';

  @override
  String get errorServer =>
      'Can\'t reach the server right now. Try again shortly.';

  @override
  String get errorTimeout => 'The connection timed out. Want to try again?';

  @override
  String get authErrorWrongCredentials => 'Wrong email or password.';

  @override
  String get authErrorEmailTaken =>
      'An account with this email already exists.';

  @override
  String get authErrorCheckDetails => 'Check your details.';

  @override
  String get navReport => 'Home';

  @override
  String get navMood => 'Mood';

  @override
  String get navJournal => 'Journal';

  @override
  String get navStories => 'Stories';

  @override
  String get navChat => 'Chat';

  @override
  String get navMessages => 'Messages';

  @override
  String get navGuide => 'Guide';

  @override
  String get navLife => 'Life';

  @override
  String get navSettings => 'Settings';

  @override
  String get navProfile => 'Profile';

  @override
  String get greetingNight => 'Good night';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingDay => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get homeStateNoData => 'Nothing recorded yet';

  @override
  String get homeStateNoDataNote =>
      'Add a mood check-in or start a conversation, and your state will show up here.';

  @override
  String get homeMoodLabel => 'Mood';

  @override
  String get homeEnergyLabel => 'Energy';

  @override
  String get homeBarBad => 'LOW';

  @override
  String get homeBarGood => 'GOOD';

  @override
  String homeBasedOn(String sources) {
    return 'Based on: $sources';
  }

  @override
  String get homeDiagnosesTitle => 'My diagnoses';

  @override
  String get homeToday => 'Today\'s note';

  @override
  String get streakLabel => 'Streak';

  @override
  String get streakDays => 'days';

  @override
  String get streakJournalLabel => 'day streak';

  @override
  String get streakPeriodLabel => 'Period streak';

  @override
  String streakPeriodValue(int active, int total) {
    return '$active / $total days';
  }

  @override
  String get homeRecommendations => 'Suggestions';

  @override
  String get homeNoReport => 'You don\'t have a report for today yet.';

  @override
  String get homeGenerateReport => 'Generate report';

  @override
  String get homeRefreshing => 'Reassessing how you\'re doing';

  @override
  String get homeCrisisWarning =>
      'We noticed some difficult language in your recent entries. If this is an emergency, call your local emergency number; if you want to talk, reaching a professional is worth considering.';

  @override
  String get guideTitle => 'Guide';

  @override
  String get guideSearchHint => 'Search conditions';

  @override
  String guideSearchEmpty(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get guideCategoryAll => 'All';

  @override
  String guideDisorderCount(int count) {
    return '$count conditions';
  }

  @override
  String get guideOpenCard => 'Open the card';

  @override
  String get guideResearchInCategory => 'Research in this category';

  @override
  String get guideResearchFeed => 'From this week\'s reading';

  @override
  String get guideEmptyInCategory => 'No research cards in this category yet';

  @override
  String get guideEmptyFeed => 'No insights yet';

  @override
  String get guideEmptyInCategoryBody =>
      'Tap any condition above to read its reference card. Research cards collect here as the background service finds new papers in this category.';

  @override
  String get guideEmptyFeedBody =>
      'This screen fills up as the background research service collects new papers. If you\'d rather not wait, you can synthesize an insight now from what has already been gathered.';

  @override
  String get guideSynthesizeNow => 'Generate now';

  @override
  String get cardTitle => 'Reference Card';

  @override
  String get cardWhatIsIt => 'What is it?';

  @override
  String get cardHowDevelops => 'How does it develop?';

  @override
  String get cardWhatHelps => 'What helps day to day?';

  @override
  String get cardProfessionalHelp => 'What does professional support involve?';

  @override
  String get cardDisclaimer =>
      'This page is for information only and does not diagnose. If you recognize these symptoms in yourself, talk to a mental health professional.';

  @override
  String get cardPreparing => 'Preparing the card';

  @override
  String get cardPreparingBody =>
      'This one is being opened for the first time and is being compiled from research sources. It will be instant next time.';

  @override
  String get cardLoadFailed => 'The card couldn\'t be loaded';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsConnection => 'Connection';

  @override
  String get settingsServer => 'Server address';

  @override
  String get settingsDeviceId => 'Device ID';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsPrivacy => 'Privacy and Security';

  @override
  String get settingsDataLocation => 'Where your data lives';

  @override
  String get settingsDataLocationBody =>
      'Only in the local database on your own machine.';

  @override
  String get settingsLegal => 'Legal notice';

  @override
  String get settingsLegalBody =>
      'Hearth is not a substitute for a licensed professional. In an emergency, call your local emergency number.';

  @override
  String get settingsCommunity => 'Community';

  @override
  String get settingsStories => 'Stories';

  @override
  String get settingsModeration => 'Moderation';

  @override
  String get settingsAdminBadge => 'Admin';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsProfile => 'Edit Profile';

  @override
  String get settingsPrivacyRow => 'Privacy';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get profileTitle => 'Edit Profile';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileLanguageTurkish => 'Turkish';

  @override
  String get profileLanguageEnglish => 'English';

  @override
  String get profileBirthYear => 'Year of birth';

  @override
  String get profileBirthYearHint => 'e.g. 1998';

  @override
  String profileAgeValue(int age) {
    return '$age years old';
  }

  @override
  String get profileAgeWhy =>
      'Knowing your age keeps suggestions fitted to the stage of life you\'re in.';

  @override
  String get profileDiagnoses => 'My diagnoses';

  @override
  String get profileSaved => 'Your profile has been saved.';

  @override
  String get profileInvalidYear => 'Enter a valid year of birth.';

  @override
  String get diagnosesTitle => 'My diagnoses';

  @override
  String get diagnosesNote =>
      'What you pick here is only what you\'ve told the app; it never diagnoses anyone. Your selection is used to shape your reports and chat around you.';

  @override
  String diagnosesSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String diagnosesCatalogSize(int categories, int total) {
    return '$categories categories · $total conditions';
  }

  @override
  String get diagnosesSaved => 'Your diagnoses have been saved.';

  @override
  String get diagnosesLoadFailed => 'Categories couldn\'t be loaded.';

  @override
  String get authRegisterTitle => 'Create your account';

  @override
  String get authRegisterNote =>
      'It takes a few seconds. You don\'t have to share anything.';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authWelcomeNote =>
      'Let\'s pick up where you left off. You don\'t have to share anything.';

  @override
  String get authLoginTitle => 'Sign in to your account';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordRule => 'At least 8 characters.';

  @override
  String get authShowPassword => 'Show';

  @override
  String get authHidePassword => 'Hide';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authNoAccount => 'No account yet?';

  @override
  String get authPassword => 'Password (at least 8 characters)';

  @override
  String get authDisclaimer =>
      'Hearth is not a licensed psychologist, psychiatrist or medical device, and it does not diagnose. In a crisis, please call your local emergency number or reach a professional.';

  @override
  String get authRegisterCta => 'Create account';

  @override
  String get authLoginCta => 'Sign in';

  @override
  String get authSwitchToLogin => 'Already have an account? Sign in';

  @override
  String get authSwitchToRegister => 'No account yet? Sign up';

  @override
  String get authDisplayNameLabel => 'Your name';

  @override
  String get authDisplayNameHint => 'What should we call you?';

  @override
  String get moodDoneToday => 'Today\'s check-in is in';

  @override
  String get moodHowAreYou => 'Which of these is closest right now?';

  @override
  String get moodPickHint =>
      'You can pick more than one. There\'s no right answer.';

  @override
  String get moodWhereItLands => 'Where it lands';

  @override
  String get moodAxisHint =>
      'Your picks translate onto these two axes — you can nudge the dot by hand too.';

  @override
  String get moodOncePerDay => 'Saved once a day · next one in 24h';

  @override
  String get moodWordCalm => 'Calm';

  @override
  String get moodWordHopeful => 'Hopeful';

  @override
  String get moodWordTired => 'Tired';

  @override
  String get moodWordTense => 'Tense';

  @override
  String get moodWordUnsure => 'Unsure';

  @override
  String get moodWordRelieved => 'Relieved';

  @override
  String get moodWordHeavy => 'Heavy';

  @override
  String get moodWordJoyful => 'Joyful';

  @override
  String get moodWordAngry => 'Angry';

  @override
  String get moodWordEmpty => 'Empty';

  @override
  String moodNextIn(String time) {
    return 'Next check-in opens in $time';
  }

  @override
  String get moodDragHint => 'Drag the dot to where you feel you are';

  @override
  String get moodSaved => 'Saved. Thank you!';

  @override
  String get moodTryTomorrow => 'Try again tomorrow';

  @override
  String get moodEnergetic => 'Energized';

  @override
  String get moodCalm => 'Calm';

  @override
  String get moodUnpleasant => 'Difficult';

  @override
  String get moodPleasant => 'Pleasant';

  @override
  String get journalSaved => 'Journal entry saved.';

  @override
  String journalCharCount(int count) {
    return '$count characters';
  }

  @override
  String get journalHint => 'Half a sentence is fine...';

  @override
  String get journalPrompt => 'What was on your mind today?';

  @override
  String get journalPromptNote => 'Nobody reads this. Half a sentence is fine.';

  @override
  String get journalDraftSaved => 'Draft saved';

  @override
  String get journalPast => 'Past entries';

  @override
  String get journalEmpty => 'You haven\'t written an entry yet.';

  @override
  String get journalDoneToday => 'Today\'s entry is written';

  @override
  String journalNextIn(String time) {
    return 'Next entry opens in $time';
  }

  @override
  String get timeUnitHour => 'h';

  @override
  String get timeUnitMinute => 'm';

  @override
  String get timeUnitSecond => 's';

  @override
  String get chatEmptyPrompt => 'Want to share something?';

  @override
  String get chatInputHint => 'Write something...';

  @override
  String get chatCrisis =>
      'This sounds like a hard moment. If this is an emergency, call your local emergency number; if you want to talk, reaching a professional is worth considering.';

  @override
  String get chatToday => 'today';

  @override
  String get chatCrisisTitle => 'You don\'t have to carry this alone';

  @override
  String get chatCallEmergency => 'Call 112';

  @override
  String get chatContinue => 'Continue';

  @override
  String get lifeTitle => 'Life Analysis';

  @override
  String get lifeCooldownTooltip => 'Can be refreshed once a week';

  @override
  String lifeNextOn(String date) {
    return 'next $date';
  }

  @override
  String get lifeRegenerate => 'Re-analyze';

  @override
  String get lifeOverview => 'Overview';

  @override
  String get lifePatterns => 'Recurring patterns';

  @override
  String get lifeDoList => 'What works for you';

  @override
  String get lifeDontList => 'What works against you';

  @override
  String get lifeEmpty => 'You don\'t have a life analysis yet.';

  @override
  String get lifeEmptyBody =>
      'An analysis is built from your whole history of mood check-ins, journal entries, conversations and reports.';

  @override
  String get lifeGenerate => 'Generate analysis';

  @override
  String get storiesEntryTitle => 'Community Stories';

  @override
  String get storiesEntryBody =>
      'Read what others going through the same thing wrote, or share your own.';

  @override
  String get storiesTitle => 'Stories';

  @override
  String get storiesSearchHint => 'Search condition or category';

  @override
  String get storiesAnonymous => 'anonymous';

  @override
  String get storiesTranslated => 'Translated';

  @override
  String get storiesShowOriginal => 'Show original';

  @override
  String get storiesShowTranslation => 'Show translation';

  @override
  String get storiesTabFeed => 'Stories';

  @override
  String get storiesTabMine => 'Mine';

  @override
  String get storiesWriteCta => 'Share your story';

  @override
  String get storiesFeedEmpty => 'No stories yet';

  @override
  String get storiesFeedEmptyBody => 'Approved stories will be listed here.';

  @override
  String get storiesMineEmpty => 'You haven\'t written a story yet';

  @override
  String get storiesMineEmptyBody =>
      'You can share what you went through, what helped and what didn\'t. Your story is reviewed before it\'s published.';

  @override
  String get storiesStatusPending => 'In review';

  @override
  String get storiesStatusApproved => 'Published';

  @override
  String get storiesStatusRejected => 'Not published';

  @override
  String get storiesWithdrawTitle => 'Remove your story';

  @override
  String get storiesWithdrawBody =>
      'This story will be permanently deleted. Are you sure?';

  @override
  String get storiesWithdraw => 'Remove';

  @override
  String get storiesReportTitle => 'Report this story';

  @override
  String get storiesReportNoteHint => 'Optional note';

  @override
  String get storiesReport => 'Report';

  @override
  String get storiesReportSent => 'Your report has been received, thank you.';

  @override
  String get storiesSubmitTitle => 'Write Your Story';

  @override
  String get storiesSubmitHint =>
      'What did you go through, what helped, what didn\'t? Tell it in your own words...';

  @override
  String get storiesPickDiagnosis => 'Which condition is this about?';

  @override
  String storiesCharCount(int count) {
    return '$count characters · at least 8 lines suggested';
  }

  @override
  String get storiesDisclaimer =>
      'This is not medical advice. Always make medication and treatment decisions together with a doctor. What you share here is your own personal experience — someone else\'s situation may be different.';

  @override
  String get storiesConsentLabel =>
      'I understand that once approved, this story will be shared with other users (without my identity shown).';

  @override
  String get storiesModerationNotice =>
      'Your story is reviewed before it\'s published. You can withdraw it at any time.';

  @override
  String get storiesSubmit => 'Submit';

  @override
  String get storiesSubmitSuccess => 'Your story has been sent for review.';

  @override
  String get storiesEditTitle => 'Edit Your Story';

  @override
  String get storiesSaveChanges => 'Save';

  @override
  String get storiesEditSuccess =>
      'Your story was updated and sent for re-review.';

  @override
  String get storiesEditNotice =>
      'Saving sends this story back for review; it won\'t show in the feed until it\'s approved again.';

  @override
  String get storiesEdit => 'Edit';

  @override
  String get storiesModerationTitle => 'Story Moderation';

  @override
  String storiesModerationQueueTab(int count) {
    return '$count pending';
  }

  @override
  String storiesModerationReportsTab(int count) {
    return '$count reported';
  }

  @override
  String get storiesModerationEmpty => 'No pending stories';

  @override
  String get storiesModerationNoReports => 'No reported stories';

  @override
  String get storiesModerationApprove => 'Approve';

  @override
  String get storiesModerationReject => 'Reject';

  @override
  String get storiesModerationKeep => 'Keep published';

  @override
  String get storiesModerationCrisisFlag => 'Crisis language';

  @override
  String get storiesModerationReporterNote => 'Reporter\'s note:';

  @override
  String get settingsAssessment => 'Self-assessment';

  @override
  String get settingsMyStories => 'My stories';

  @override
  String get settingsChatBoundaries => 'Conversation preferences';

  @override
  String get settingsChatBoundariesBody =>
      'Set what you don\'t want in conversations';

  @override
  String get onboardingSkipTour => 'Skip the tour';

  @override
  String get onboardingSkipStep => 'Skip this step';

  @override
  String get introGreeting =>
      'Hi — I\'m Hearth. Before anything else, I\'d like to ask you one thing.';

  @override
  String get introQuestion =>
      'How would you like me to be with you in these conversations — and what would you rather I never did? Write it in your own words. Everything I say from here on follows what you tell me now.';

  @override
  String get introExamples =>
      'For example: \"Don\'t give me advice, just listen.\" · \"Keep it short.\" · \"Don\'t tell me to see a therapist.\" · \"Be honest with me, don\'t sugar-coat it.\"';

  @override
  String get introInputHint => 'Write in your own words…';

  @override
  String get introContinue => 'Continue';

  @override
  String get introChangeLater =>
      'Saved. You can change it any time under Settings > Conversation preferences.';

  @override
  String get tourNext => 'Next';

  @override
  String get tourStart => 'Let\'s start';

  @override
  String get tourWelcomeTitle => 'Welcome to Hearth';

  @override
  String get tourWelcomeBody =>
      'Hearth is a space that keeps you company over time. The more you share, the more its answers are actually about you. It isn\'t a replacement for a therapist — but it\'s here on the days in between.\n\nNow that that\'s out of the way, let me show you what\'s here — a few steps, and you can skip whenever you like.';

  @override
  String get tourChatTitle => 'Talk whenever you need to';

  @override
  String get tourChatBody =>
      'Chat is open at three in the morning too. It remembers what you\'ve said and knows your check-ins and journal entries — so you don\'t have to start from the beginning every time.\n\nWhat you told me a moment ago about how you want to be spoken to is already in effect here, and you can change it whenever you like.';

  @override
  String get tourMoodJournalTitle => 'Mood and journal';

  @override
  String get tourMoodJournalBody =>
      'Once a day, mark how you feel in a few words, and write about your day if you want to. Both take under a minute.\n\nThese aren\'t just records: they\'re where the picture of what lifts you and what wears you down comes from.';

  @override
  String get tourReportTitle => 'Today\'s note';

  @override
  String get tourReportBody =>
      'Every day the home screen carries a short summary of your day and a couple of small suggestions — drawn from your mood, your journal and your conversations.\n\nThe weekly recap and life analysis show the wider picture: what keeps repeating, what\'s changing.';

  @override
  String get tourCommunityTitle => 'You\'re not alone in this';

  @override
  String get tourCommunityBody =>
      'In Stories you can read other people\'s own accounts, and share yours (anonymously if you prefer). Every story is reviewed before it\'s published.\n\nThe Guide has plain, research-backed explanations of conditions.';

  @override
  String get tourPrivacyTitle => 'Your data and your safety';

  @override
  String get tourPrivacyBody =>
      'What you write belongs to your account; nobody sees it unless you share it as a story. You can delete your account and all of your data in one step, any time.\n\nWhen there\'s a real risk, the app won\'t look away — it will point you to emergency help. Hearth doesn\'t give medical advice or diagnose.';

  @override
  String get boundariesTitle => 'What don\'t you want in these conversations?';

  @override
  String get boundariesIntro =>
      'Everyone has something they\'d rather not hear. Tick whatever applies — and change it whenever it stops fitting.';

  @override
  String get boundariesEffectNote =>
      'What you pick goes straight into the conversation: Hearth will stay inside these limits from now on. The only exception is a real risk to your safety, which always comes first.';

  @override
  String get boundariesNoteLabel => 'Anything else you\'d like to add?';

  @override
  String get boundariesNoteHint => 'e.g. don\'t talk to me like you pity me';

  @override
  String get boundariesChangeLater =>
      'You can change these any time under Settings > Conversation preferences.';

  @override
  String get boundaryNoAdvice => 'Don\'t give me advice';

  @override
  String get boundaryNoAdviceBody =>
      'No tips, techniques or \"try this\" unless I ask. Just listen.';

  @override
  String get boundaryNoReferrals => 'Don\'t tell me to see a professional';

  @override
  String get boundaryNoReferralsBody =>
      'I already know that option exists; I don\'t want it raised every conversation.';

  @override
  String get boundaryNoToxicPositivity => 'No relentless positivity';

  @override
  String get boundaryNoToxicPositivityBody =>
      'Skip the \"everything will be fine\" framing and talk to me plainly.';

  @override
  String get boundaryNoQuestions => 'Don\'t ask me a lot of questions';

  @override
  String get boundaryNoQuestionsBody =>
      'It shouldn\'t feel like an interview — fewer questions, plainer answers.';

  @override
  String get boundaryNoClinicalTerms => 'No clinical language';

  @override
  String get boundaryNoClinicalTermsBody =>
      'Everyday words instead of diagnosis names and therapy jargon.';

  @override
  String get boundaryNoReligious => 'No religious or spiritual framing';

  @override
  String get boundaryNoReligiousBody =>
      'Don\'t reach for faith-based comfort or imagery.';

  @override
  String get boundaryNoToughLove => 'No tough-love tone';

  @override
  String get boundaryNoToughLoveBody =>
      'I don\'t want a confronting \"pull yourself together\" approach.';

  @override
  String get boundaryNoHistoryCallbacks => 'Don\'t bring up my past entries';

  @override
  String get boundaryNoHistoryCallbacksBody =>
      'Leave my older journals and check-ins alone unless I raise them.';

  @override
  String get introGotIt => 'Got it';

  @override
  String get introMoodTitle => 'What is a mood check-in?';

  @override
  String get introMoodBody =>
      'Once a day, you mark how you feel right now in a few words. You can also nudge the two bars underneath by hand.\n\nThese entries are the main input behind today\'s note and your weekly recap — after a few days in a row, patterns start to show.';

  @override
  String get introJournalTitle => 'How the journal works';

  @override
  String get introJournalBody =>
      'One entry a day: what\'s on your mind, what happened, what you haven\'t told anyone. What you write stays yours; it\'s never shared.\n\nAn unfinished entry is kept as a draft, so you can come back to it. Past entries live in the archive below.';

  @override
  String get introChatTitle => 'About chat';

  @override
  String get introChatBody =>
      'Write whatever you want here — to get something off your chest, to make sense of something, or just to talk about your day.\n\nHearth answers knowing your check-ins, your journal and your conversation preferences. It doesn\'t give medical advice, and in an emergency it will point you to help.';

  @override
  String get milestoneContinue => 'Continue';

  @override
  String get milestoneFirstMoodTitle => 'Your first check-in is saved';

  @override
  String get milestoneFirstMoodBody =>
      'Good start. Mark a few more days and the note and charts on your home screen will start showing your own patterns.';

  @override
  String get milestoneFirstJournalTitle => 'Your first journal entry is in';

  @override
  String get milestoneFirstJournalBody =>
      'What you wrote is yours alone. You can write a new entry tomorrow; the old ones are waiting in your archive.';

  @override
  String get milestoneFirstChatTitle => 'Your first conversation has started';

  @override
  String get milestoneFirstChatBody =>
      'What you talk about is remembered, so you won\'t have to start over next time. You can change how you want to be spoken to any time in Settings.';

  @override
  String get assessmentOnboardTitle => 'Let\'s get to know you a bit';

  @override
  String assessmentOnboardIntro(int total) {
    return 'There are a few short tests to complete — $total questions in all, about the last two weeks: your mood, your anxiety, your general well-being and more. This shapes how we approach things with you — skip it now and do it later from Settings if you\'d rather.';
  }

  @override
  String get assessmentStart => 'Start';

  @override
  String get assessmentSkip => 'Not now';

  @override
  String assessmentProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get assessmentSectionMood => 'Over the last 2 weeks — your mood';

  @override
  String get assessmentSectionAnxiety => 'Over the last 2 weeks — your anxiety';

  @override
  String get assessmentSectionWellbeing =>
      'Over the last 2 weeks — your well-being';

  @override
  String get assessmentSectionSomatic =>
      'Over the last 4 weeks — your physical symptoms';

  @override
  String get assessmentSectionPtsd => 'A traumatic event';

  @override
  String get assessmentSectionAlcohol =>
      'Over the last year — your alcohol use';

  @override
  String get assessmentSectionSubstance =>
      'Over the last year — your substance use';

  @override
  String get assessmentPtsd5Intro =>
      'Sometimes people experience very stressful events — a serious accident, a natural disaster, physical or sexual assault, combat, being badly beaten, or witnessing someone\'s death. If something like this has happened to you, in the past month have you:';

  @override
  String get assessmentAnswer0 => 'Not at all';

  @override
  String get assessmentAnswer1 => 'Several days';

  @override
  String get assessmentAnswer2 => 'More than half the days';

  @override
  String get assessmentAnswer3 => 'Nearly every day';

  @override
  String get assessmentAnswerNo => 'No';

  @override
  String get assessmentAnswerYes => 'Yes';

  @override
  String get who5Answer0 => 'At no time';

  @override
  String get who5Answer1 => 'Some of the time';

  @override
  String get who5Answer2 => 'Less than half of the time';

  @override
  String get who5Answer3 => 'More than half of the time';

  @override
  String get who5Answer4 => 'Most of the time';

  @override
  String get who5Answer5 => 'All of the time';

  @override
  String get phq15Answer0 => 'Not bothered at all';

  @override
  String get phq15Answer1 => 'Bothered a little';

  @override
  String get phq15Answer2 => 'Bothered a lot';

  @override
  String get assessmentResultTitle => 'Thank you';

  @override
  String get assessmentResultNote =>
      'This isn\'t a diagnosis — it\'s a screening signal that helps us tailor how we approach things with you.';

  @override
  String get assessmentResultDepression => 'Mood screening';

  @override
  String get assessmentResultAnxiety => 'Anxiety screening';

  @override
  String get assessmentResultWellbeing => 'Well-being screening';

  @override
  String get assessmentResultSomatic => 'Physical symptom screening';

  @override
  String get assessmentResultPtsd => 'Post-traumatic stress screening';

  @override
  String get assessmentResultAlcohol => 'Alcohol use screening';

  @override
  String get assessmentResultSubstance => 'Substance use screening';

  @override
  String get assessmentBandMinimal => 'Minimal';

  @override
  String get assessmentBandMild => 'Mild';

  @override
  String get assessmentBandModerate => 'Moderate';

  @override
  String get assessmentBandModeratelySevere => 'Moderately severe';

  @override
  String get assessmentBandSevere => 'Severe';

  @override
  String get assessmentBandVeryLow => 'Very low';

  @override
  String get assessmentBandLow => 'Low';

  @override
  String get assessmentBandMedium => 'Medium';

  @override
  String get assessmentBandHigh => 'High';

  @override
  String get assessmentBandGood => 'Good';

  @override
  String get assessmentBandCaution => 'Worth watching';

  @override
  String get assessmentBandBelowThreshold => 'Below threshold';

  @override
  String get assessmentBandPositiveScreen => 'Worth a closer look';

  @override
  String get assessmentContinueCta => 'Continue';

  @override
  String get assessmentSubmitError => 'Couldn\'t submit — try again?';

  @override
  String get assessmentRetakeTitle => 'Self-assessment';

  @override
  String assessmentRetakeIntro(int total) {
    return 'There are tests to complete: seven short screens, $total questions in all — your mood, your anxiety, your general well-being and more. Results are used in the background of your chats and suggestions.';
  }

  @override
  String get assessmentRetakeCta => 'Start the assessment';

  @override
  String get assessmentRetakeAgain => 'Retake';

  @override
  String get assessmentLastTakenToday => 'Taken today';

  @override
  String assessmentLastTaken(int days) {
    return 'Taken $days days ago';
  }

  @override
  String get assessmentNeverTaken => 'Not taken yet';

  @override
  String get phq9Q1 => 'Little interest or pleasure in doing things';

  @override
  String get phq9Q2 => 'Feeling down, depressed, or hopeless';

  @override
  String get phq9Q3 =>
      'Trouble falling or staying asleep, or sleeping too much';

  @override
  String get phq9Q4 => 'Feeling tired or having little energy';

  @override
  String get phq9Q5 => 'Poor appetite or overeating';

  @override
  String get phq9Q6 =>
      'Feeling bad about yourself — or that you are a failure or have let yourself or your family down';

  @override
  String get phq9Q7 =>
      'Trouble concentrating on things, such as reading or watching television';

  @override
  String get phq9Q8 =>
      'Moving or speaking so slowly that other people could have noticed — or the opposite, being so fidgety or restless that you\'ve been moving around a lot more than usual';

  @override
  String get phq9Q9 =>
      'Thoughts that you would be better off dead, or of hurting yourself in some way';

  @override
  String get gad7Q1 => 'Feeling nervous, anxious, or on edge';

  @override
  String get gad7Q2 => 'Not being able to stop or control worrying';

  @override
  String get gad7Q3 => 'Worrying too much about different things';

  @override
  String get gad7Q4 => 'Trouble relaxing';

  @override
  String get gad7Q5 => 'Being so restless that it\'s hard to sit still';

  @override
  String get gad7Q6 => 'Becoming easily annoyed or irritable';

  @override
  String get gad7Q7 => 'Feeling afraid as if something awful might happen';

  @override
  String get who5Q1 => 'I have felt cheerful and in good spirits.';

  @override
  String get who5Q2 => 'I have felt calm and relaxed.';

  @override
  String get who5Q3 => 'I have felt active and vigorous.';

  @override
  String get who5Q4 => 'I woke up feeling fresh and rested.';

  @override
  String get who5Q5 =>
      'My daily life has been filled with things that interest me.';

  @override
  String get phq15Q1 => 'Stomach pain';

  @override
  String get phq15Q2 => 'Back pain';

  @override
  String get phq15Q3 => 'Pain in your arms, legs, or joints';

  @override
  String get phq15Q4 =>
      'Menstrual cramps or other problems with your periods (women only)';

  @override
  String get phq15Q5 => 'Headaches';

  @override
  String get phq15Q6 => 'Chest pain';

  @override
  String get phq15Q7 => 'Dizziness';

  @override
  String get phq15Q8 => 'Fainting spells';

  @override
  String get phq15Q9 => 'Feeling your heart pound or race';

  @override
  String get phq15Q10 => 'Shortness of breath';

  @override
  String get phq15Q11 => 'Pain or other problems during sexual intercourse';

  @override
  String get phq15Q12 => 'Constipation, loose bowels, or diarrhea';

  @override
  String get phq15Q13 => 'Nausea, gas, or indigestion';

  @override
  String get phq15Q14 => 'Feeling tired or having low energy';

  @override
  String get phq15Q15 => 'Trouble sleeping';

  @override
  String get ptsd5Q1 =>
      'Had nightmares about the event(s) or thought about them when you didn\'t want to?';

  @override
  String get ptsd5Q2 =>
      'Tried hard not to think about the event(s), or went out of your way to avoid situations that reminded you of them?';

  @override
  String get ptsd5Q3 =>
      'Been constantly on guard, watchful, or easily startled?';

  @override
  String get ptsd5Q4 =>
      'Felt numb or detached from people, activities, or your surroundings?';

  @override
  String get ptsd5Q5 =>
      'Felt guilty, or unable to stop blaming yourself or others, for the event(s) or problems they caused?';

  @override
  String get auditcQ1 => 'How often did you have a drink containing alcohol?';

  @override
  String get auditcQ1Opt0 => 'Never';

  @override
  String get auditcQ1Opt1 => 'Monthly or less';

  @override
  String get auditcQ1Opt2 => '2-4 times a month';

  @override
  String get auditcQ1Opt3 => '2-3 times a week';

  @override
  String get auditcQ1Opt4 => '4 or more times a week';

  @override
  String get auditcQ2 =>
      'How many drinks did you have on a typical day when drinking?';

  @override
  String get auditcQ2Opt0 => '1 or 2';

  @override
  String get auditcQ2Opt1 => '3 or 4';

  @override
  String get auditcQ2Opt2 => '5 or 6';

  @override
  String get auditcQ2Opt3 => '7 to 9';

  @override
  String get auditcQ2Opt4 => '10 or more';

  @override
  String get auditcQ3 =>
      'How often did you have 6 or more drinks on one occasion?';

  @override
  String get auditcQ3Opt0 => 'Never';

  @override
  String get auditcQ3Opt1 => 'Less than monthly';

  @override
  String get auditcQ3Opt2 => 'Monthly';

  @override
  String get auditcQ3Opt3 => 'Weekly';

  @override
  String get auditcQ3Opt4 => 'Daily or almost daily';

  @override
  String get cageaidQ1 =>
      'Have you felt you ought to cut down on your drinking or drug use?';

  @override
  String get cageaidQ2 =>
      'Have people annoyed you by criticizing your drinking or drug use?';

  @override
  String get cageaidQ3 =>
      'Have you felt bad or guilty about your drinking or drug use?';

  @override
  String get cageaidQ4 =>
      'Have you used alcohol or drugs first thing in the morning to steady your nerves or feel better?';

  @override
  String get storiesAnonymousToggle => 'Share anonymously';

  @override
  String get storiesAnonymousOnBody => 'Your name and photo won\'t be shown.';

  @override
  String get storiesAnonymousOffBody => 'Shared with your name and photo.';

  @override
  String get profileStatStories => 'Stories';

  @override
  String get profileStatFollowers => 'Followers';

  @override
  String get profileStatFollowing => 'Following';

  @override
  String get profileFollow => 'Follow';

  @override
  String get profileUnfollow => 'Unfollow';

  @override
  String get profileNobodyYet => 'Nobody yet';

  @override
  String get myProfileEdit => 'Edit Profile';

  @override
  String get myProfileStories => 'My Stories';

  @override
  String get settingsDmPrivacy => 'Message privacy';

  @override
  String get settingsDmEveryone => 'Accept messages from everyone';

  @override
  String get settingsDmFollowing => 'Only from people I follow';

  @override
  String get settingsDmNoReceipts => 'Messages have no read receipts.';

  @override
  String get dmTitle => 'Messages';

  @override
  String get dmTabInbox => 'Chats';

  @override
  String get dmTabRequests => 'Requests';

  @override
  String get dmNoThreads => 'No conversations yet';

  @override
  String get dmNoRequests => 'No pending requests';

  @override
  String get dmMessage => 'Send a message';

  @override
  String get dmFollowersOnly => 'Only accepts messages from people they follow';

  @override
  String dmRequestTitle(String name) {
    return 'Write to $name';
  }

  @override
  String get dmRequestBody =>
      'Your first message goes as a request. You can\'t send a second one until it\'s accepted.';

  @override
  String get dmRequestHint => 'Say something...';

  @override
  String get dmRequestSent => 'Request sent.';

  @override
  String get dmSend => 'Send';

  @override
  String get dmSendFailed => 'Couldn\'t send the message.';

  @override
  String get dmComposerHint => 'Write something...';

  @override
  String get dmAccept => 'Accept';

  @override
  String get dmDecline => 'Decline';

  @override
  String get dmAcceptPrompt =>
      'This person wants to talk. Replying accepts the request automatically.';

  @override
  String get dmWaiting => 'Waiting';

  @override
  String get dmNewRequest => 'New request';

  @override
  String get dmWaitingBody =>
      'Request sent. You can write once it\'s accepted.';

  @override
  String get dmLeave => 'Leave conversation';

  @override
  String get recapEntryTitle => 'Your Weekly Recap';

  @override
  String get recapEntrySubtitle => 'See and share your week';

  @override
  String get recapTitle => 'Weekly Recap';

  @override
  String get recapCheckins => 'Mood check-ins';

  @override
  String get recapJournalEntries => 'Journal entries';

  @override
  String get recapActiveDays => 'Active days';

  @override
  String get recapMoodVeryPositive => 'You had a great week.';

  @override
  String get recapMoodPositive => 'This week was mostly good.';

  @override
  String get recapMoodNeutral => 'This week was steady.';

  @override
  String get recapMoodMixed => 'This week had its ups and downs.';

  @override
  String get recapMoodHard => 'This week was tough. Be gentle with yourself.';

  @override
  String get recapMoodEmpty => 'No check-ins yet this week.';

  @override
  String get recapShare => 'Share';

  @override
  String recapShareText(int checkins, int streak) {
    return 'I logged $checkins mood check-ins on Hearth this week, and I\'m on a $streak-day streak.';
  }

  @override
  String get lifeMoodHistoryTitle => 'Your Mood History';

  @override
  String get lifeMoodHistoryEmpty => 'No check-ins yet';

  @override
  String get lifeMoodHistoryLegendLow => 'Hard';

  @override
  String get lifeMoodHistoryLegendHigh => 'Good';

  @override
  String get settingsDeleteAccount => 'Delete Account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'This can\'t be undone. Your mood entries, journals, stories, messages, and everything else tied to your account will be permanently deleted.';

  @override
  String get deleteAccountPasswordHint => 'Enter your password to confirm';

  @override
  String get deleteAccountConfirm => 'Permanently Delete';

  @override
  String get deleteAccountWrongPassword => 'Incorrect password.';

  @override
  String get deleteAccountDone => 'Your account has been deleted.';

  @override
  String get storiesReactionDestek => 'You\'re not alone';

  @override
  String get storiesReactionGuclusun => 'You\'re strong';

  @override
  String get storiesReactionAnliyorum => 'I understand';

  @override
  String get storiesHighlightsTitle => 'Highlights';

  @override
  String get settingsPremiumRow => 'Hearth Plus';

  @override
  String get premiumTitle => 'Hearth Plus';

  @override
  String get premiumPitch => 'For anyone who wants to go deeper with Hearth.';

  @override
  String get premiumFeatureChat => 'Unlimited AI chat';

  @override
  String get premiumFeatureAnalysis => 'More frequent life analysis';

  @override
  String get premiumFeatureInsights => 'Deeper, more personalized insights';

  @override
  String premiumPricePerMonth(String price) {
    return '$price / month';
  }

  @override
  String get premiumSubscribe => 'Subscribe';

  @override
  String get premiumRestore => 'Restore Purchases';

  @override
  String premiumActiveUntil(String date) {
    return 'Your subscription is active until $date.';
  }

  @override
  String get premiumAlreadyActive => 'Hearth Plus is already active';

  @override
  String get premiumTerms =>
      'Subscription renews automatically. You\'ll be charged unless you cancel at least 24 hours before the current period ends. Cancel anytime in App Store > Settings.';

  @override
  String get premiumUnavailable => 'Purchases aren\'t available right now.';

  @override
  String get premiumRestored => 'Your purchases have been restored.';

  @override
  String get premiumPrivacyPolicy => 'Privacy Policy';

  @override
  String get premiumTermsOfUse => 'Terms of Use';

  @override
  String get chatQuotaExceeded =>
      'You\'ve used today\'s free chat limit. Get Hearth Plus for unlimited chat.';

  @override
  String get voiceDictate => 'Dictate';

  @override
  String get voiceListening => 'Listening…';

  @override
  String get voiceUnavailable =>
      'Dictation isn\'t available on this device right now.';

  @override
  String get voicePermissionDenied =>
      'Dictation needs microphone access. You can allow it for Hearth in your phone\'s settings.';

  @override
  String get voiceSpeak => 'Read aloud';

  @override
  String get voiceStopSpeaking => 'Stop reading';

  @override
  String get discoveriesTitle => 'What lifts you';

  @override
  String get discoveriesSeeAll => 'See all';

  @override
  String get discoveriesKindLifts => 'Helps';

  @override
  String get discoveriesKindDrains => 'Wears you down';

  @override
  String get discoveriesKindRhythm => 'Rhythm';

  @override
  String get discoveriesError => 'Couldn\'t load your discoveries right now.';

  @override
  String get discoveriesEmptyTitle => 'Nothing clear yet';

  @override
  String get discoveriesEmptyBody =>
      'There\'s no repeating pattern in your records just yet. Adding a few words or a short note to your check-ins will fill this in.';

  @override
  String get discoveriesFootnote =>
      'This is a tendency seen in your own records only — not a firm conclusion or a diagnosis.';

  @override
  String get discoveriesLockedTitle => 'Your discoveries are on the way';

  @override
  String get discoveriesLockedBody =>
      'A few more days of mood check-ins and I can show you what tends to lift you.';

  @override
  String discoveriesLockedProgress(int logged, int needed) {
    return '$logged/$needed days';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsCheckinTitle => 'Evening check-in';

  @override
  String get notificationsCheckinBody =>
      'If you haven\'t logged your mood that day, one gentle reminder arrives at the time you pick. If you have, it never bothers you.';

  @override
  String get notificationsTimeLabel => 'Time';

  @override
  String get notificationsPreviewLabel => 'What it looks like';

  @override
  String get notificationsPreviewTitle => 'How was today?';

  @override
  String get notificationsPreviewBody =>
      'Half a minute is enough — how today felt shapes tomorrow\'s note.';

  @override
  String get notificationsWebNote =>
      'Notifications only arrive in the phone app for now; your choice is still saved.';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String settingsNotificationsOn(String time) {
    return 'Evening check-in · $time';
  }

  @override
  String get settingsNotificationsOff => 'Evening check-in is off';

  @override
  String get metooButton => 'This happened to me too';

  @override
  String metooCount(int count) {
    return '$count people';
  }

  @override
  String metooWithYou(int count) {
    return 'You and $count others';
  }

  @override
  String get metooYouSaidIt => 'Sent to the author';

  @override
  String get metooSheetTitle => 'Is this your story too?';

  @override
  String get metooSheetBody =>
      'The author is never shown who you are. You can leave them a short note if you like.';

  @override
  String get metooNoteNotAlone => 'You\'re not alone';

  @override
  String get metooNoteSameHere => 'I went through something similar';

  @override
  String get metooNoteThanks => 'Thank you for sharing this';

  @override
  String get metooNoteStrength => 'Sending you strength';

  @override
  String get metooJustMark => 'Mark it without a note';

  @override
  String get metooSent => 'Sent to the author. Your identity wasn\'t shown.';

  @override
  String metooOwnCount(int count) {
    return '$count people found themselves in this story';
  }

  @override
  String get metooOwnPrivacy =>
      'You\'re never shown who they are — only the notes they left.';

  @override
  String get sessionEntryTitle => 'My pre-session summary';

  @override
  String get sessionEntryBody =>
      'Put your recent weeks on one page to bring to your therapist.';

  @override
  String get sessionTitle => 'Pre-session summary';

  @override
  String get sessionIntro =>
      'A one-page summary to bring to your therapist or psychiatrist: how this stretch went, what kept coming up, what was hard, what helped. Built only from your own records.';

  @override
  String get sessionPeriodLabel => 'Which period should it cover?';

  @override
  String get sessionPeriodWeek => 'Last week';

  @override
  String get sessionPeriodTwoWeeks => 'Last 2 weeks';

  @override
  String get sessionPeriodMonth => 'Last month';

  @override
  String get sessionNoteLabel =>
      'Anything you want to talk about in this session?';

  @override
  String get sessionNoteHint => 'Optional. e.g. my sleep, tension at work';

  @override
  String get sessionGenerate => 'Prepare summary';

  @override
  String get sessionRegenerate => 'Prepare again';

  @override
  String get sessionGenerating => 'Reading your records…';

  @override
  String get sessionGeneratingBody =>
      'Bringing together your check-ins, journal and conversations. This can take about half a minute.';

  @override
  String get sessionDocTitle => 'Pre-session summary';

  @override
  String sessionStats(int moodDays, int journals) {
    return '$moodDays days of check-ins · $journals journal entries';
  }

  @override
  String get sessionOverview => 'Overview';

  @override
  String get sessionMoodCourse => 'How my mood moved';

  @override
  String get sessionThemes => 'What kept coming up';

  @override
  String get sessionHardMoments => 'Hard moments';

  @override
  String get sessionWhatHelped => 'What helped';

  @override
  String get sessionQuestions => 'What I want to talk about';

  @override
  String get sessionScreening => 'Latest self-assessment';

  @override
  String sessionScreeningAgo(int days) {
    return '$days days ago';
  }

  @override
  String get sessionScreeningDepression => 'Depression (PHQ-9)';

  @override
  String get sessionScreeningAnxiety => 'Anxiety (GAD-7)';

  @override
  String get sessionScreeningWellbeing => 'Wellbeing (WHO-5)';

  @override
  String get sessionShare => 'Share as PDF';

  @override
  String get sessionNotEnough =>
      'There are no check-ins or journal entries in this period. Pick a longer period, or log a few days and try again.';

  @override
  String get sessionDisclaimer =>
      'Prepared from your own records; not a diagnosis or a medical assessment.';

  @override
  String get sessionPdfFooter =>
      'Hearth · prepared from the person\'s own records, not a diagnosis';

  @override
  String get navToday => 'Today';

  @override
  String get navPath => 'My path';

  @override
  String get navMe => 'Me';

  @override
  String get supportPill => 'Support';

  @override
  String get supportSheetBody =>
      'If this is an emergency, call 112 now. When you feel ready, reaching out to a professional can be a good step too.';

  @override
  String get supportWriteInChat => 'Write in chat';

  @override
  String get todayNoCheckinYet => 'No check-in yet today';

  @override
  String todayMoreWords(int count) {
    return '+$count words';
  }

  @override
  String get todayWriteJournal => 'Write in journal';

  @override
  String get todaySpeak => 'Say it out loud';

  @override
  String get todayYourState => 'Where you are';

  @override
  String todayStreak(int count) {
    return '$count-day streak';
  }

  @override
  String get todayRefreshState => 'Refresh';

  @override
  String get levelVeryLow => 'very low';

  @override
  String get levelLow => 'low';

  @override
  String get levelMid => 'middle';

  @override
  String get levelHigh => 'good';

  @override
  String get levelVeryHigh => 'very good';

  @override
  String todayMetooCard(int count) {
    return '$count people found themselves in your stories';
  }

  @override
  String get todayMetooCardAction => 'See the notes they left';

  @override
  String get chatPreferences => 'Preferences';

  @override
  String storiesPendingBanner(int count) {
    return '$count stories waiting for approval';
  }

  @override
  String storiesReportsBanner(int count) {
    return '$count reported stories';
  }

  @override
  String get storiesAdminOnly => 'Only admins see this';

  @override
  String get storiesReview => 'Review';

  @override
  String get pathSessionBody => 'One page to take to your therapist';

  @override
  String get pathTests => 'My screenings';

  @override
  String get pathDiagnosesEmpty => 'You haven\'t added a diagnosis yet.';

  @override
  String get pathDiagnosesAdd => 'Add a diagnosis';

  @override
  String get pathGuideBody => 'Condition cards and research';

  @override
  String get meReminders => 'Reminders';

  @override
  String meReminderOn(String time) {
    return 'At $time';
  }

  @override
  String get meReminderOff => 'Off';

  @override
  String get meChatAndMessages => 'Chat and messages';

  @override
  String get meDmPolicyEveryone => 'From everyone';

  @override
  String get meDmPolicyFollowing => 'Only people I follow';

  @override
  String get mePlusBody => 'Unlimited chat';

  @override
  String get mePlusCta => 'See plans';

  @override
  String get meModeration => 'Story moderation';

  @override
  String meModerationCounts(int pending, int reports) {
    return '$pending pending · $reports reported';
  }

  @override
  String get quickCheckinEyebrow => 'Mood · today';

  @override
  String get quickCheckinNoteHint => 'Add a sentence, if you like';

  @override
  String get quickCheckinFootnote => 'Saved once a day.';

  @override
  String quickCheckinFootnoteReminder(String time) {
    return 'Saved once a day. If you skip it, one reminder comes at $time.';
  }
}
