// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mental AI';

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
  String get navReport => 'Home';

  @override
  String get navMood => 'Mood';

  @override
  String get navJournal => 'Journal';

  @override
  String get navChat => 'Chat';

  @override
  String get navGuide => 'Guide';

  @override
  String get navLife => 'Life';

  @override
  String get navSettings => 'Settings';

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
  String get homeDiagnosesTitle => 'MY DIAGNOSES';

  @override
  String get homeToday => 'Today';

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
      'Mental AI is not a substitute for a licensed professional. In an emergency, call your local emergency number.';

  @override
  String get settingsCommunity => 'Community';

  @override
  String get settingsStories => 'Stories';

  @override
  String get settingsStoriesBody =>
      'Share your experience, read others\' stories.';

  @override
  String get settingsModeration => 'Moderation';

  @override
  String get settingsModerationBody => 'Review pending and reported stories.';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsProfile => 'My profile';

  @override
  String get settingsProfileBody => 'Email, age, language and your diagnoses.';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get profileTitle => 'My profile';

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
  String get diagnosesSaved => 'Your diagnoses have been saved.';

  @override
  String get diagnosesLoadFailed => 'Categories couldn\'t be loaded.';

  @override
  String get authRegisterTitle => 'Create your account';

  @override
  String get authLoginTitle => 'Sign in to your account';

  @override
  String get authPassword => 'Password (at least 8 characters)';

  @override
  String get authDisclaimer =>
      'Mental AI is not a licensed psychologist, psychiatrist or medical device, and it does not diagnose. In a crisis, please call your local emergency number or reach a professional.';

  @override
  String get authRegisterCta => 'Create account';

  @override
  String get authLoginCta => 'Sign in';

  @override
  String get authSwitchToLogin => 'Already have an account? Sign in';

  @override
  String get authSwitchToRegister => 'No account yet? Sign up';

  @override
  String get moodDoneToday => 'Today\'s check-in is in';

  @override
  String get moodHowAreYou => 'How are you right now?';

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
  String get journalHint => 'What was on your mind today?';

  @override
  String get journalPast => 'PAST ENTRIES';

  @override
  String get journalEmpty => 'You haven\'t written an entry yet.';

  @override
  String get journalDoneToday => 'Today\'s entry is written';

  @override
  String journalNextIn(String time) {
    return 'Next entry opens in $time';
  }

  @override
  String get chatEmptyPrompt => 'Want to share something?';

  @override
  String get chatInputHint => 'Write something...';

  @override
  String get chatCrisis =>
      'This sounds like a hard moment. If this is an emergency, call your local emergency number; if you want to talk, reaching a professional is worth considering.';

  @override
  String get lifeTitle => 'Life Analysis';

  @override
  String get lifeCooldownTooltip => 'Can be refreshed once a week';

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
  String get storiesTitle => 'Stories';

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
}
