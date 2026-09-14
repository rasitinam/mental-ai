import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hearth'**
  String get appTitle;

  /// No description provided for @commonRetry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get commonClose;

  /// No description provided for @commonError.
  ///
  /// In tr, this message translates to:
  /// **'Bir şeyler ters gitti'**
  String get commonError;

  /// No description provided for @commonLoading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor'**
  String get commonLoading;

  /// No description provided for @errorNoConnection.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantını kontrol et ve tekrar dene.'**
  String get errorNoConnection;

  /// No description provided for @errorServer.
  ///
  /// In tr, this message translates to:
  /// **'Sunucuya şu an ulaşılamıyor. Birazdan tekrar dene.'**
  String get errorServer;

  /// No description provided for @errorTimeout.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı zaman aşımına uğradı. Tekrar dener misin?'**
  String get errorTimeout;

  /// No description provided for @authErrorWrongCredentials.
  ///
  /// In tr, this message translates to:
  /// **'E-posta veya şifre hatalı.'**
  String get authErrorWrongCredentials;

  /// No description provided for @authErrorEmailTaken.
  ///
  /// In tr, this message translates to:
  /// **'Bu e-posta ile zaten bir hesap var.'**
  String get authErrorEmailTaken;

  /// No description provided for @authErrorCheckDetails.
  ///
  /// In tr, this message translates to:
  /// **'Bilgileri kontrol et.'**
  String get authErrorCheckDetails;

  /// No description provided for @navReport.
  ///
  /// In tr, this message translates to:
  /// **'Ana Ekran'**
  String get navReport;

  /// No description provided for @navMood.
  ///
  /// In tr, this message translates to:
  /// **'Ruh Hali'**
  String get navMood;

  /// No description provided for @navJournal.
  ///
  /// In tr, this message translates to:
  /// **'Günlük'**
  String get navJournal;

  /// No description provided for @navStories.
  ///
  /// In tr, this message translates to:
  /// **'Hikayeler'**
  String get navStories;

  /// No description provided for @navChat.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet'**
  String get navChat;

  /// No description provided for @navMessages.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlar'**
  String get navMessages;

  /// No description provided for @navGuide.
  ///
  /// In tr, this message translates to:
  /// **'Rehber'**
  String get navGuide;

  /// No description provided for @navLife.
  ///
  /// In tr, this message translates to:
  /// **'Yaşam'**
  String get navLife;

  /// No description provided for @navSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get navSettings;

  /// No description provided for @navProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profilim'**
  String get navProfile;

  /// No description provided for @greetingNight.
  ///
  /// In tr, this message translates to:
  /// **'İyi geceler'**
  String get greetingNight;

  /// No description provided for @greetingMorning.
  ///
  /// In tr, this message translates to:
  /// **'Günaydın'**
  String get greetingMorning;

  /// No description provided for @greetingDay.
  ///
  /// In tr, this message translates to:
  /// **'İyi günler'**
  String get greetingDay;

  /// No description provided for @greetingEvening.
  ///
  /// In tr, this message translates to:
  /// **'İyi akşamlar'**
  String get greetingEvening;

  /// No description provided for @homeStateNoData.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir kayıt yok'**
  String get homeStateNoData;

  /// No description provided for @homeStateNoDataNote.
  ///
  /// In tr, this message translates to:
  /// **'Bir ruh hali kaydı ekle ya da sohbet et; durumun buraya yansısın.'**
  String get homeStateNoDataNote;

  /// No description provided for @homeMoodLabel.
  ///
  /// In tr, this message translates to:
  /// **'Keyif'**
  String get homeMoodLabel;

  /// No description provided for @homeEnergyLabel.
  ///
  /// In tr, this message translates to:
  /// **'Enerji'**
  String get homeEnergyLabel;

  /// No description provided for @homeBarBad.
  ///
  /// In tr, this message translates to:
  /// **'KÖTÜ'**
  String get homeBarBad;

  /// No description provided for @homeBarGood.
  ///
  /// In tr, this message translates to:
  /// **'İYİ'**
  String get homeBarGood;

  /// No description provided for @homeBasedOn.
  ///
  /// In tr, this message translates to:
  /// **'Şuna göre: {sources}'**
  String homeBasedOn(String sources);

  /// No description provided for @homeDiagnosesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tanılarım'**
  String get homeDiagnosesTitle;

  /// No description provided for @homeToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün notu'**
  String get homeToday;

  /// No description provided for @streakLabel.
  ///
  /// In tr, this message translates to:
  /// **'Seri'**
  String get streakLabel;

  /// No description provided for @streakDays.
  ///
  /// In tr, this message translates to:
  /// **'gün'**
  String get streakDays;

  /// No description provided for @streakJournalLabel.
  ///
  /// In tr, this message translates to:
  /// **'gün seri'**
  String get streakJournalLabel;

  /// No description provided for @streakPeriodLabel.
  ///
  /// In tr, this message translates to:
  /// **'Dönem serisi'**
  String get streakPeriodLabel;

  /// No description provided for @streakPeriodValue.
  ///
  /// In tr, this message translates to:
  /// **'{active} / {total} gün'**
  String streakPeriodValue(int active, int total);

  /// No description provided for @homeRecommendations.
  ///
  /// In tr, this message translates to:
  /// **'Öneriler'**
  String get homeRecommendations;

  /// No description provided for @homeNoReport.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bugüne ait bir raporun yok.'**
  String get homeNoReport;

  /// No description provided for @homeGenerateReport.
  ///
  /// In tr, this message translates to:
  /// **'Rapor oluştur'**
  String get homeGenerateReport;

  /// No description provided for @homeRefreshing.
  ///
  /// In tr, this message translates to:
  /// **'Durumun yeniden değerlendiriliyor'**
  String get homeRefreshing;

  /// No description provided for @homeCrisisWarning.
  ///
  /// In tr, this message translates to:
  /// **'Son kayıtlarında zorlu ifadeler fark ettik. Acil durumdaysan 112\'yi ara; konuşmak istersen bir uzmana ulaşmayı düşünebilirsin.'**
  String get homeCrisisWarning;

  /// No description provided for @guideTitle.
  ///
  /// In tr, this message translates to:
  /// **'Rehber'**
  String get guideTitle;

  /// No description provided for @guideSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Tanı ara'**
  String get guideSearchHint;

  /// No description provided for @guideSearchEmpty.
  ///
  /// In tr, this message translates to:
  /// **'\"{query}\" için sonuç yok'**
  String guideSearchEmpty(String query);

  /// No description provided for @guideCategoryAll.
  ///
  /// In tr, this message translates to:
  /// **'Genel'**
  String get guideCategoryAll;

  /// No description provided for @guideDisorderCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} tanı'**
  String guideDisorderCount(int count);

  /// No description provided for @guideOpenCard.
  ///
  /// In tr, this message translates to:
  /// **'Bilgi kartını gör'**
  String get guideOpenCard;

  /// No description provided for @guideResearchInCategory.
  ///
  /// In tr, this message translates to:
  /// **'Bu kategoriden araştırmalar'**
  String get guideResearchInCategory;

  /// No description provided for @guideResearchFeed.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta okunanlardan'**
  String get guideResearchFeed;

  /// No description provided for @guideEmptyInCategory.
  ///
  /// In tr, this message translates to:
  /// **'Bu kategoride henüz araştırma kartı yok'**
  String get guideEmptyInCategory;

  /// No description provided for @guideEmptyFeed.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir içgörü yok'**
  String get guideEmptyFeed;

  /// No description provided for @guideEmptyInCategoryBody.
  ///
  /// In tr, this message translates to:
  /// **'Yukarıdaki başlıklardan birine dokunarak o durumla ilgili bilgi kartını okuyabilirsin. Araştırma kartları, arka plandaki servis bu kategoride yeni makale buldukça burada birikir.'**
  String get guideEmptyInCategoryBody;

  /// No description provided for @guideEmptyFeedBody.
  ///
  /// In tr, this message translates to:
  /// **'Arka planda çalışan araştırma servisi yeni makaleler topladıkça bu ekran güncellenecek. Beklemek istemezsen zaten toplanmış makalelerden şimdi bir içgörü çıkarabilirsin.'**
  String get guideEmptyFeedBody;

  /// No description provided for @guideSynthesizeNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi oluştur'**
  String get guideSynthesizeNow;

  /// No description provided for @cardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bilgi Kartı'**
  String get cardTitle;

  /// No description provided for @cardWhatIsIt.
  ///
  /// In tr, this message translates to:
  /// **'Nedir?'**
  String get cardWhatIsIt;

  /// No description provided for @cardHowDevelops.
  ///
  /// In tr, this message translates to:
  /// **'Nasıl gelişir?'**
  String get cardHowDevelops;

  /// No description provided for @cardWhatHelps.
  ///
  /// In tr, this message translates to:
  /// **'Günlük hayatta ne yardımcı olur?'**
  String get cardWhatHelps;

  /// No description provided for @cardProfessionalHelp.
  ///
  /// In tr, this message translates to:
  /// **'Profesyonel destek neleri içerir?'**
  String get cardProfessionalHelp;

  /// No description provided for @cardDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Bu sayfa yalnızca bilgilendirme amaçlıdır ve tanı koymaz. Kendinde bu belirtileri görüyorsan bir ruh sağlığı uzmanına danış.'**
  String get cardDisclaimer;

  /// No description provided for @cardPreparing.
  ///
  /// In tr, this message translates to:
  /// **'Bilgi kartı hazırlanıyor'**
  String get cardPreparing;

  /// No description provided for @cardPreparingBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu başlık ilk kez açılıyor; araştırma kaynaklarından derleniyor. Bir sonraki açılışta anında gelecek.'**
  String get cardPreparingBody;

  /// No description provided for @cardLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Bilgi kartı yüklenemedi'**
  String get cardLoadFailed;

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @settingsConnection.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı'**
  String get settingsConnection;

  /// No description provided for @settingsServer.
  ///
  /// In tr, this message translates to:
  /// **'Sunucu adresi'**
  String get settingsServer;

  /// No description provided for @settingsDeviceId.
  ///
  /// In tr, this message translates to:
  /// **'Cihaz kimliği'**
  String get settingsDeviceId;

  /// No description provided for @settingsAppearance.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get settingsThemeDark;

  /// No description provided for @settingsPrivacy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik ve Güvenlik'**
  String get settingsPrivacy;

  /// No description provided for @settingsDataLocation.
  ///
  /// In tr, this message translates to:
  /// **'Verilerin nerede duruyor'**
  String get settingsDataLocation;

  /// No description provided for @settingsDataLocationBody.
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca kendi bilgisayarındaki yerel veritabanında saklanır.'**
  String get settingsDataLocationBody;

  /// No description provided for @settingsLegal.
  ///
  /// In tr, this message translates to:
  /// **'Yasal uyarı'**
  String get settingsLegal;

  /// No description provided for @settingsLegalBody.
  ///
  /// In tr, this message translates to:
  /// **'Hearth lisanslı bir sağlık uzmanının yerini tutmaz. Acil bir durumdaysan 112\'yi ara.'**
  String get settingsLegalBody;

  /// No description provided for @settingsCommunity.
  ///
  /// In tr, this message translates to:
  /// **'Topluluk'**
  String get settingsCommunity;

  /// No description provided for @settingsStories.
  ///
  /// In tr, this message translates to:
  /// **'Hikayeler'**
  String get settingsStories;

  /// No description provided for @settingsModeration.
  ///
  /// In tr, this message translates to:
  /// **'Moderasyon'**
  String get settingsModeration;

  /// No description provided for @settingsAdminBadge.
  ///
  /// In tr, this message translates to:
  /// **'Admin'**
  String get settingsAdminBadge;

  /// No description provided for @settingsAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get settingsAccount;

  /// No description provided for @settingsProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profili Düzenle'**
  String get settingsProfile;

  /// No description provided for @settingsPrivacyRow.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik'**
  String get settingsPrivacyRow;

  /// No description provided for @settingsLogout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yap'**
  String get settingsLogout;

  /// No description provided for @profileTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profili Düzenle'**
  String get profileTitle;

  /// No description provided for @profileEmail.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get profileEmail;

  /// No description provided for @profileLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get profileLanguage;

  /// No description provided for @profileLanguageTurkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get profileLanguageTurkish;

  /// No description provided for @profileLanguageEnglish.
  ///
  /// In tr, this message translates to:
  /// **'İngilizce'**
  String get profileLanguageEnglish;

  /// No description provided for @profileBirthYear.
  ///
  /// In tr, this message translates to:
  /// **'Doğum yılı'**
  String get profileBirthYear;

  /// No description provided for @profileBirthYearHint.
  ///
  /// In tr, this message translates to:
  /// **'örn. 1998'**
  String get profileBirthYearHint;

  /// No description provided for @profileAgeValue.
  ///
  /// In tr, this message translates to:
  /// **'{age} yaşında'**
  String profileAgeValue(int age);

  /// No description provided for @profileAgeWhy.
  ///
  /// In tr, this message translates to:
  /// **'Yaşını bilmek, önerilerin yaşadığın döneme uygun olmasını sağlar.'**
  String get profileAgeWhy;

  /// No description provided for @profileDiagnoses.
  ///
  /// In tr, this message translates to:
  /// **'Tanılarım'**
  String get profileDiagnoses;

  /// No description provided for @profileSaved.
  ///
  /// In tr, this message translates to:
  /// **'Profilin kaydedildi.'**
  String get profileSaved;

  /// No description provided for @profileInvalidYear.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir doğum yılı gir.'**
  String get profileInvalidYear;

  /// No description provided for @diagnosesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tanılarım'**
  String get diagnosesTitle;

  /// No description provided for @diagnosesNote.
  ///
  /// In tr, this message translates to:
  /// **'Burada seçtiklerin yalnızca senin bildirdiğin bilgilerdir; uygulama tanı koymaz. Seçtiklerin raporlarını ve sohbeti sana göre şekillendirmek için kullanılır.'**
  String get diagnosesNote;

  /// No description provided for @diagnosesSelectedCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} seçili'**
  String diagnosesSelectedCount(int count);

  /// No description provided for @diagnosesCatalogSize.
  ///
  /// In tr, this message translates to:
  /// **'{categories} kategori · {total} tanı'**
  String diagnosesCatalogSize(int categories, int total);

  /// No description provided for @diagnosesSaved.
  ///
  /// In tr, this message translates to:
  /// **'Tanıların kaydedildi.'**
  String get diagnosesSaved;

  /// No description provided for @diagnosesLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriler yüklenemedi.'**
  String get diagnosesLoadFailed;

  /// No description provided for @authRegisterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabını oluştur'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterNote.
  ///
  /// In tr, this message translates to:
  /// **'Birkaç saniye sürer. Hiçbir şey paylaşmak zorunda değilsin.'**
  String get authRegisterNote;

  /// No description provided for @authWelcomeBack.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar hoş geldin'**
  String get authWelcomeBack;

  /// No description provided for @authWelcomeNote.
  ///
  /// In tr, this message translates to:
  /// **'Kaldığın yerden devam edelim. Hiçbir şey paylaşmak zorunda değilsin.'**
  String get authWelcomeNote;

  /// No description provided for @authLoginTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabına giriş yap'**
  String get authLoginTitle;

  /// No description provided for @authPasswordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordRule.
  ///
  /// In tr, this message translates to:
  /// **'En az 8 karakter.'**
  String get authPasswordRule;

  /// No description provided for @authShowPassword.
  ///
  /// In tr, this message translates to:
  /// **'Göster'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In tr, this message translates to:
  /// **'Gizle'**
  String get authHidePassword;

  /// No description provided for @authHaveAccount.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabın var mı?'**
  String get authHaveAccount;

  /// No description provided for @authNoAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu?'**
  String get authNoAccount;

  /// No description provided for @authPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre (en az 8 karakter)'**
  String get authPassword;

  /// No description provided for @authDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Hearth lisanslı bir psikolog, psikiyatrist ya da tıbbi bir cihaz değildir; tanı koymaz. Kriz anında lütfen 112\'yi veya bir uzmanı ara.'**
  String get authDisclaimer;

  /// No description provided for @authRegisterCta.
  ///
  /// In tr, this message translates to:
  /// **'Hesap oluştur'**
  String get authRegisterCta;

  /// No description provided for @authLoginCta.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap'**
  String get authLoginCta;

  /// No description provided for @authSwitchToLogin.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabın var mı? Giriş yap'**
  String get authSwitchToLogin;

  /// No description provided for @authSwitchToRegister.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu? Kayıt ol'**
  String get authSwitchToRegister;

  /// No description provided for @authDisplayNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Adın'**
  String get authDisplayNameLabel;

  /// No description provided for @authDisplayNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Sana nasıl seslenelim?'**
  String get authDisplayNameHint;

  /// No description provided for @moodDoneToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü kaydın alındı'**
  String get moodDoneToday;

  /// No description provided for @moodHowAreYou.
  ///
  /// In tr, this message translates to:
  /// **'Şu an sana en yakın olan hangisi?'**
  String get moodHowAreYou;

  /// No description provided for @moodPickHint.
  ///
  /// In tr, this message translates to:
  /// **'Birkaçını seçebilirsin. Doğru cevap yok.'**
  String get moodPickHint;

  /// No description provided for @moodWhereItLands.
  ///
  /// In tr, this message translates to:
  /// **'Nereye düşüyor'**
  String get moodWhereItLands;

  /// No description provided for @moodAxisHint.
  ///
  /// In tr, this message translates to:
  /// **'Seçtiklerin bu iki eksene çevriliyor — noktayı elle de oynatabilirsin.'**
  String get moodAxisHint;

  /// No description provided for @moodOncePerDay.
  ///
  /// In tr, this message translates to:
  /// **'Günde bir kez kaydediliyor · sonraki 24 sa sonra'**
  String get moodOncePerDay;

  /// No description provided for @moodWordCalm.
  ///
  /// In tr, this message translates to:
  /// **'Sakin'**
  String get moodWordCalm;

  /// No description provided for @moodWordHopeful.
  ///
  /// In tr, this message translates to:
  /// **'Umutlu'**
  String get moodWordHopeful;

  /// No description provided for @moodWordTired.
  ///
  /// In tr, this message translates to:
  /// **'Yorgun'**
  String get moodWordTired;

  /// No description provided for @moodWordTense.
  ///
  /// In tr, this message translates to:
  /// **'Gergin'**
  String get moodWordTense;

  /// No description provided for @moodWordUnsure.
  ///
  /// In tr, this message translates to:
  /// **'Kararsız'**
  String get moodWordUnsure;

  /// No description provided for @moodWordRelieved.
  ///
  /// In tr, this message translates to:
  /// **'Hafiflemiş'**
  String get moodWordRelieved;

  /// No description provided for @moodWordHeavy.
  ///
  /// In tr, this message translates to:
  /// **'Ağır'**
  String get moodWordHeavy;

  /// No description provided for @moodWordJoyful.
  ///
  /// In tr, this message translates to:
  /// **'Neşeli'**
  String get moodWordJoyful;

  /// No description provided for @moodWordAngry.
  ///
  /// In tr, this message translates to:
  /// **'Kızgın'**
  String get moodWordAngry;

  /// No description provided for @moodWordEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Boşlukta'**
  String get moodWordEmpty;

  /// No description provided for @moodNextIn.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki kayıt {time} sonra açılıyor'**
  String moodNextIn(String time);

  /// No description provided for @moodDragHint.
  ///
  /// In tr, this message translates to:
  /// **'Noktayı hissettiğin yere sürükle'**
  String get moodDragHint;

  /// No description provided for @moodSaved.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedildi. Teşekkürler!'**
  String get moodSaved;

  /// No description provided for @moodTryTomorrow.
  ///
  /// In tr, this message translates to:
  /// **'Yarın tekrar dene'**
  String get moodTryTomorrow;

  /// No description provided for @moodEnergetic.
  ///
  /// In tr, this message translates to:
  /// **'Enerjik'**
  String get moodEnergetic;

  /// No description provided for @moodCalm.
  ///
  /// In tr, this message translates to:
  /// **'Sakin'**
  String get moodCalm;

  /// No description provided for @moodUnpleasant.
  ///
  /// In tr, this message translates to:
  /// **'Zorlayıcı'**
  String get moodUnpleasant;

  /// No description provided for @moodPleasant.
  ///
  /// In tr, this message translates to:
  /// **'Keyifli'**
  String get moodPleasant;

  /// No description provided for @journalSaved.
  ///
  /// In tr, this message translates to:
  /// **'Günlük kaydedildi.'**
  String get journalSaved;

  /// No description provided for @journalCharCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} karakter'**
  String journalCharCount(int count);

  /// No description provided for @journalHint.
  ///
  /// In tr, this message translates to:
  /// **'Yarım cümle de olur...'**
  String get journalHint;

  /// No description provided for @journalPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Bugün aklından ne geçti?'**
  String get journalPrompt;

  /// No description provided for @journalPromptNote.
  ///
  /// In tr, this message translates to:
  /// **'Kimse okumuyor. Yarım cümle de olur.'**
  String get journalPromptNote;

  /// No description provided for @journalDraftSaved.
  ///
  /// In tr, this message translates to:
  /// **'Taslak kaydedildi'**
  String get journalDraftSaved;

  /// No description provided for @journalPast.
  ///
  /// In tr, this message translates to:
  /// **'Önceki günler'**
  String get journalPast;

  /// No description provided for @journalEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir günlük yazmadın.'**
  String get journalEmpty;

  /// No description provided for @journalDoneToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü günlüğün yazıldı'**
  String get journalDoneToday;

  /// No description provided for @journalNextIn.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki giriş {time} sonra açılıyor'**
  String journalNextIn(String time);

  /// No description provided for @timeUnitHour.
  ///
  /// In tr, this message translates to:
  /// **'sa'**
  String get timeUnitHour;

  /// No description provided for @timeUnitMinute.
  ///
  /// In tr, this message translates to:
  /// **'dk'**
  String get timeUnitMinute;

  /// No description provided for @timeUnitSecond.
  ///
  /// In tr, this message translates to:
  /// **'sn'**
  String get timeUnitSecond;

  /// No description provided for @chatEmptyPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Bir şey paylaşmak ister misin?'**
  String get chatEmptyPrompt;

  /// No description provided for @chatInputHint.
  ///
  /// In tr, this message translates to:
  /// **'Bir şey yaz...'**
  String get chatInputHint;

  /// No description provided for @chatCrisis.
  ///
  /// In tr, this message translates to:
  /// **'Zor bir an gibi görünüyor. Acil durumdaysan 112\'yi ara; konuşmak istersen bir uzmana ulaşmayı düşünebilirsin.'**
  String get chatCrisis;

  /// No description provided for @chatToday.
  ///
  /// In tr, this message translates to:
  /// **'bugün'**
  String get chatToday;

  /// No description provided for @chatCrisisTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bunu yalnız taşımak zorunda değilsin'**
  String get chatCrisisTitle;

  /// No description provided for @chatCallEmergency.
  ///
  /// In tr, this message translates to:
  /// **'112\'yi ara'**
  String get chatCallEmergency;

  /// No description provided for @chatContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get chatContinue;

  /// No description provided for @lifeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yaşam Analizi'**
  String get lifeTitle;

  /// No description provided for @lifeCooldownTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Haftada bir yenilenebilir'**
  String get lifeCooldownTooltip;

  /// No description provided for @lifeNextOn.
  ///
  /// In tr, this message translates to:
  /// **'sonraki {date}'**
  String lifeNextOn(String date);

  /// No description provided for @lifeRegenerate.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden analiz et'**
  String get lifeRegenerate;

  /// No description provided for @lifeOverview.
  ///
  /// In tr, this message translates to:
  /// **'Genel görünüm'**
  String get lifeOverview;

  /// No description provided for @lifePatterns.
  ///
  /// In tr, this message translates to:
  /// **'Öne çıkan örüntüler'**
  String get lifePatterns;

  /// No description provided for @lifeDoList.
  ///
  /// In tr, this message translates to:
  /// **'Yapman iyi gelenler'**
  String get lifeDoList;

  /// No description provided for @lifeDontList.
  ///
  /// In tr, this message translates to:
  /// **'Sana zorluk çıkaranlar'**
  String get lifeDontList;

  /// No description provided for @lifeEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir yaşam analizin yok.'**
  String get lifeEmpty;

  /// No description provided for @lifeEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Tüm ruh hali, günlük, sohbet ve rapor geçmişine bakarak bir analiz oluşturulur.'**
  String get lifeEmptyBody;

  /// No description provided for @lifeGenerate.
  ///
  /// In tr, this message translates to:
  /// **'Analiz oluştur'**
  String get lifeGenerate;

  /// No description provided for @storiesEntryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Topluluk Hikayeleri'**
  String get storiesEntryTitle;

  /// No description provided for @storiesEntryBody.
  ///
  /// In tr, this message translates to:
  /// **'Aynı şeyi yaşayanların deneyimlerini oku ya da kendi hikayeni paylaş.'**
  String get storiesEntryBody;

  /// No description provided for @storiesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hikayeler'**
  String get storiesTitle;

  /// No description provided for @storiesSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Tanı veya kategori ara'**
  String get storiesSearchHint;

  /// No description provided for @storiesAnonymous.
  ///
  /// In tr, this message translates to:
  /// **'isimsiz'**
  String get storiesAnonymous;

  /// No description provided for @storiesTranslated.
  ///
  /// In tr, this message translates to:
  /// **'Çevrildi'**
  String get storiesTranslated;

  /// No description provided for @storiesShowOriginal.
  ///
  /// In tr, this message translates to:
  /// **'Orijinalini gör'**
  String get storiesShowOriginal;

  /// No description provided for @storiesShowTranslation.
  ///
  /// In tr, this message translates to:
  /// **'Çeviriyi gör'**
  String get storiesShowTranslation;

  /// No description provided for @storiesTabFeed.
  ///
  /// In tr, this message translates to:
  /// **'Hikayeler'**
  String get storiesTabFeed;

  /// No description provided for @storiesTabMine.
  ///
  /// In tr, this message translates to:
  /// **'Hikayem'**
  String get storiesTabMine;

  /// No description provided for @storiesWriteCta.
  ///
  /// In tr, this message translates to:
  /// **'Hikayeni paylaş'**
  String get storiesWriteCta;

  /// No description provided for @storiesFeedEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz paylaşılan hikaye yok'**
  String get storiesFeedEmpty;

  /// No description provided for @storiesFeedEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Onaylanan hikayeler burada listelenecek.'**
  String get storiesFeedEmptyBody;

  /// No description provided for @storiesMineEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir hikaye yazmadın'**
  String get storiesMineEmpty;

  /// No description provided for @storiesMineEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Yaşadıklarını, neyin işine yaradığını ya da yaramadığını başkalarıyla paylaşabilirsin. Gönderdiğin hikaye yayınlanmadan önce incelenir.'**
  String get storiesMineEmptyBody;

  /// No description provided for @storiesStatusPending.
  ///
  /// In tr, this message translates to:
  /// **'İnceleniyor'**
  String get storiesStatusPending;

  /// No description provided for @storiesStatusApproved.
  ///
  /// In tr, this message translates to:
  /// **'Yayında'**
  String get storiesStatusApproved;

  /// No description provided for @storiesStatusRejected.
  ///
  /// In tr, this message translates to:
  /// **'Yayınlanmadı'**
  String get storiesStatusRejected;

  /// No description provided for @storiesWithdrawTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hikayeni kaldır'**
  String get storiesWithdrawTitle;

  /// No description provided for @storiesWithdrawBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu hikaye kalıcı olarak silinecek. Emin misin?'**
  String get storiesWithdrawBody;

  /// No description provided for @storiesWithdraw.
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get storiesWithdraw;

  /// No description provided for @storiesReportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu hikayeyi bildir'**
  String get storiesReportTitle;

  /// No description provided for @storiesReportNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'İsteğe bağlı not'**
  String get storiesReportNoteHint;

  /// No description provided for @storiesReport.
  ///
  /// In tr, this message translates to:
  /// **'Bildir'**
  String get storiesReport;

  /// No description provided for @storiesReportSent.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimin alındı, teşekkürler.'**
  String get storiesReportSent;

  /// No description provided for @storiesSubmitTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hikayeni Yaz'**
  String get storiesSubmitTitle;

  /// No description provided for @storiesSubmitHint.
  ///
  /// In tr, this message translates to:
  /// **'Neler yaşadın, neyin işine yaradı, neyin yaramadı? Kendi cümlelerinle anlat...'**
  String get storiesSubmitHint;

  /// No description provided for @storiesPickDiagnosis.
  ///
  /// In tr, this message translates to:
  /// **'Hangi tanı hakkında?'**
  String get storiesPickDiagnosis;

  /// No description provided for @storiesCharCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} karakter · en az 8 satır önerilir'**
  String storiesCharCount(int count);

  /// No description provided for @storiesDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Bu bir tıbbi tavsiye değildir. İlaç ve tedavi kararlarını mutlaka bir hekimle birlikte al. Burada paylaştığın kendi kişisel deneyimindir — başka birinin durumu farklı olabilir.'**
  String get storiesDisclaimer;

  /// No description provided for @storiesConsentLabel.
  ///
  /// In tr, this message translates to:
  /// **'Bu hikayenin, onaylandıktan sonra diğer kullanıcılarla (kimliğim gösterilmeden) paylaşılacağını biliyorum.'**
  String get storiesConsentLabel;

  /// No description provided for @storiesModerationNotice.
  ///
  /// In tr, this message translates to:
  /// **'Hikayen yayınlanmadan önce incelenir. İstediğin zaman geri çekebilirsin.'**
  String get storiesModerationNotice;

  /// No description provided for @storiesSubmit.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get storiesSubmit;

  /// No description provided for @storiesSubmitSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Hikayen incelemeye gönderildi.'**
  String get storiesSubmitSuccess;

  /// No description provided for @storiesEditTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hikayeni Düzenle'**
  String get storiesEditTitle;

  /// No description provided for @storiesSaveChanges.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get storiesSaveChanges;

  /// No description provided for @storiesEditSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Hikayen güncellendi ve yeniden incelemeye gönderildi.'**
  String get storiesEditSuccess;

  /// No description provided for @storiesEditNotice.
  ///
  /// In tr, this message translates to:
  /// **'Kaydettiğinde bu hikaye yeniden incelemeye gönderilir; onaylanana kadar akışta görünmez.'**
  String get storiesEditNotice;

  /// No description provided for @storiesEdit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get storiesEdit;

  /// No description provided for @storiesModerationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hikaye Moderasyonu'**
  String get storiesModerationTitle;

  /// No description provided for @storiesModerationQueueTab.
  ///
  /// In tr, this message translates to:
  /// **'{count} bekleyen'**
  String storiesModerationQueueTab(int count);

  /// No description provided for @storiesModerationReportsTab.
  ///
  /// In tr, this message translates to:
  /// **'{count} bildirilen'**
  String storiesModerationReportsTab(int count);

  /// No description provided for @storiesModerationEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen hikaye yok'**
  String get storiesModerationEmpty;

  /// No description provided for @storiesModerationNoReports.
  ///
  /// In tr, this message translates to:
  /// **'Bildirilen hikaye yok'**
  String get storiesModerationNoReports;

  /// No description provided for @storiesModerationApprove.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get storiesModerationApprove;

  /// No description provided for @storiesModerationReject.
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get storiesModerationReject;

  /// No description provided for @storiesModerationKeep.
  ///
  /// In tr, this message translates to:
  /// **'Yayında tut'**
  String get storiesModerationKeep;

  /// No description provided for @storiesModerationCrisisFlag.
  ///
  /// In tr, this message translates to:
  /// **'Kriz dili'**
  String get storiesModerationCrisisFlag;

  /// No description provided for @storiesModerationReporterNote.
  ///
  /// In tr, this message translates to:
  /// **'Bildiren notu:'**
  String get storiesModerationReporterNote;

  /// No description provided for @settingsAssessment.
  ///
  /// In tr, this message translates to:
  /// **'Öz-değerlendirme'**
  String get settingsAssessment;

  /// No description provided for @settingsMyStories.
  ///
  /// In tr, this message translates to:
  /// **'Hikayelerim'**
  String get settingsMyStories;

  /// No description provided for @settingsChatBoundaries.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet tercihlerim'**
  String get settingsChatBoundaries;

  /// No description provided for @settingsChatBoundariesBody.
  ///
  /// In tr, this message translates to:
  /// **'Sohbetlerde neyi istemediğini belirle'**
  String get settingsChatBoundariesBody;

  /// No description provided for @onboardingSkipTour.
  ///
  /// In tr, this message translates to:
  /// **'Tanıtımı atla'**
  String get onboardingSkipTour;

  /// No description provided for @onboardingSkipStep.
  ///
  /// In tr, this message translates to:
  /// **'Bu adımı atla'**
  String get onboardingSkipStep;

  /// No description provided for @introGreeting.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba, ben Hearth. Her şeyden önce sana tek bir şey sormak istiyorum.'**
  String get introGreeting;

  /// No description provided for @introQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Bu sohbetlerde sana nasıl davranmamı istersin — ve neyi kesinlikle yapmamamı istersin? Kendi cümlelerinle yaz. Bundan sonra söyleyeceğim her şey, şimdi bana anlattığına göre şekillenecek.'**
  String get introQuestion;

  /// No description provided for @introExamples.
  ///
  /// In tr, this message translates to:
  /// **'Örneğin: \"Bana akıl verme, sadece dinle.\" · \"Kısa yaz.\" · \"Terapiste git deme.\" · \"Bana karşı dürüst ol, yumuşatma.\"'**
  String get introExamples;

  /// No description provided for @introInputHint.
  ///
  /// In tr, this message translates to:
  /// **'Kendi cümlelerinle yaz…'**
  String get introInputHint;

  /// No description provided for @introContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get introContinue;

  /// No description provided for @introChangeLater.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedildi. İstediğin zaman Ayarlar > Sohbet tercihlerim\'den değiştirebilirsin.'**
  String get introChangeLater;

  /// No description provided for @tourNext.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get tourNext;

  /// No description provided for @tourStart.
  ///
  /// In tr, this message translates to:
  /// **'Hadi başlayalım'**
  String get tourStart;

  /// No description provided for @tourWelcomeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hearth\'e hoş geldin'**
  String get tourWelcomeTitle;

  /// No description provided for @tourWelcomeBody.
  ///
  /// In tr, this message translates to:
  /// **'Hearth, ruh haline zamanla eşlik eden bir alan. Ne kadar çok şey paylaşırsan, sana o kadar özel cevaplar verir. Terapistin yerini tutmaz — ama arada geçen günlerde yanında olur.\n\nBunlar geride kaldığına göre, şimdi burada neler var göstereyim — birkaç adım, istediğin an atlayabilirsin.'**
  String get tourWelcomeBody;

  /// No description provided for @tourChatTitle.
  ///
  /// In tr, this message translates to:
  /// **'İstediğin saatte konuş'**
  String get tourChatTitle;

  /// No description provided for @tourChatBody.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet, gecenin üçünde de açık. Konuştuklarını hatırlar, ruh hali kayıtlarını ve günlüklerini bilir — yani her seferinde baştan anlatmak zorunda değilsin.\n\nBiraz önce sana nasıl davranılmasını istediğini söylemiştin; burada şimdiden geçerli, istediğin an da değiştirebilirsin.'**
  String get tourChatBody;

  /// No description provided for @tourMoodJournalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ruh hali ve günlük'**
  String get tourMoodJournalTitle;

  /// No description provided for @tourMoodJournalBody.
  ///
  /// In tr, this message translates to:
  /// **'Günde bir kez nasıl hissettiğini birkaç kelimeyle işaretle, istersen gününü günlüğe yaz. İkisi de bir dakikadan kısa sürer.\n\nBunlar sadece kayıt değil: haftalar içinde nelerin seni iyi ya da kötü hissettirdiği buradan çıkıyor.'**
  String get tourMoodJournalBody;

  /// No description provided for @tourReportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün notu'**
  String get tourReportTitle;

  /// No description provided for @tourReportBody.
  ///
  /// In tr, this message translates to:
  /// **'Ana ekranda her gün, o güne dair kısa bir özet ve birkaç küçük öneri bulursun — ruh halinden, günlüğünden ve konuştuklarından derlenir.\n\nHaftalık özet ve yaşam analizi ise daha geniş resmi gösterir: neyin tekrar ettiğini, neyin değiştiğini.'**
  String get tourReportBody;

  /// No description provided for @tourCommunityTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yalnız değilsin'**
  String get tourCommunityTitle;

  /// No description provided for @tourCommunityBody.
  ///
  /// In tr, this message translates to:
  /// **'Hikayeler\'de başkalarının kendi deneyimlerini okuyabilir, istersen kendi hikayeni (istersen isimsiz) paylaşabilirsin. Her hikaye yayınlanmadan önce incelenir.\n\nRehber\'de ise tanılar hakkında araştırmaya dayalı, sade anlatımlar var.'**
  String get tourCommunityBody;

  /// No description provided for @tourPrivacyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Verilerin ve güvenliğin'**
  String get tourPrivacyTitle;

  /// No description provided for @tourPrivacyBody.
  ///
  /// In tr, this message translates to:
  /// **'Yazdıkların hesabına özeldir; hikaye olarak paylaşmadıkça kimse göremez. Hesabını ve tüm verilerini istediğin an tek adımda silebilirsin.\n\nCiddi bir risk söz konusu olduğunda uygulama bunu görmezden gelmez — acil durumda 112\'yi aramanı hatırlatır. Hearth tıbbi tavsiye vermez, teşhis koymaz.'**
  String get tourPrivacyBody;

  /// No description provided for @boundariesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sohbetlerde neyi istemezsin?'**
  String get boundariesTitle;

  /// No description provided for @boundariesIntro.
  ///
  /// In tr, this message translates to:
  /// **'Herkesin duymak istemediği bir şey vardır. Sana uyanları işaretle — uymamaya başladığında da istediğin gibi değiştir.'**
  String get boundariesIntro;

  /// No description provided for @boundariesEffectNote.
  ///
  /// In tr, this message translates to:
  /// **'Seçtiklerin doğrudan sohbete işler: Hearth bundan sonra bu sınırların içinde konuşur. Tek istisna, hayati bir risk söz konusu olduğunda güvenliğini önceliklendirmesidir.'**
  String get boundariesEffectNote;

  /// No description provided for @boundariesNoteLabel.
  ///
  /// In tr, this message translates to:
  /// **'Eklemek istediğin bir şey var mı?'**
  String get boundariesNoteLabel;

  /// No description provided for @boundariesNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. bana acıyan bir dille yaklaşılmasını istemiyorum'**
  String get boundariesNoteHint;

  /// No description provided for @boundariesChangeLater.
  ///
  /// In tr, this message translates to:
  /// **'Bunları istediğin zaman Ayarlar > Sohbet tercihlerim\'den değiştirebilirsin.'**
  String get boundariesChangeLater;

  /// No description provided for @boundaryNoAdvice.
  ///
  /// In tr, this message translates to:
  /// **'Bana tavsiye verilmesin'**
  String get boundaryNoAdvice;

  /// No description provided for @boundaryNoAdviceBody.
  ///
  /// In tr, this message translates to:
  /// **'İstemediğim sürece öneri, teknik ya da \"şunu dene\" yok. Sadece dinlensin.'**
  String get boundaryNoAdviceBody;

  /// No description provided for @boundaryNoReferrals.
  ///
  /// In tr, this message translates to:
  /// **'\"Bir uzmana görün\" denmesin'**
  String get boundaryNoReferrals;

  /// No description provided for @boundaryNoReferralsBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu seçeneği zaten biliyorum; her konuşmada hatırlatılmasını istemiyorum.'**
  String get boundaryNoReferralsBody;

  /// No description provided for @boundaryNoToxicPositivity.
  ///
  /// In tr, this message translates to:
  /// **'Aşırı pozitif konuşulmasın'**
  String get boundaryNoToxicPositivity;

  /// No description provided for @boundaryNoToxicPositivityBody.
  ///
  /// In tr, this message translates to:
  /// **'\"Her şey güzel olacak\" tarzı motivasyon cümleleri yerine olduğu gibi konuşulsun.'**
  String get boundaryNoToxicPositivityBody;

  /// No description provided for @boundaryNoQuestions.
  ///
  /// In tr, this message translates to:
  /// **'Bana çok soru sorulmasın'**
  String get boundaryNoQuestions;

  /// No description provided for @boundaryNoQuestionsBody.
  ///
  /// In tr, this message translates to:
  /// **'Sorgu gibi hissettirmesin; peş peşe sorular yerine sade cevaplar olsun.'**
  String get boundaryNoQuestionsBody;

  /// No description provided for @boundaryNoClinicalTerms.
  ///
  /// In tr, this message translates to:
  /// **'Klinik terimler kullanılmasın'**
  String get boundaryNoClinicalTerms;

  /// No description provided for @boundaryNoClinicalTermsBody.
  ///
  /// In tr, this message translates to:
  /// **'Tanı isimleri ve terapi jargonu yerine günlük dille konuşulsun.'**
  String get boundaryNoClinicalTermsBody;

  /// No description provided for @boundaryNoReligious.
  ///
  /// In tr, this message translates to:
  /// **'Dini/manevi çerçeve olmasın'**
  String get boundaryNoReligious;

  /// No description provided for @boundaryNoReligiousBody.
  ///
  /// In tr, this message translates to:
  /// **'İnanç temelli teselli ya da benzetmeler kullanılmasın.'**
  String get boundaryNoReligiousBody;

  /// No description provided for @boundaryNoToughLove.
  ///
  /// In tr, this message translates to:
  /// **'Sert/yüzleştirici bir ton olmasın'**
  String get boundaryNoToughLove;

  /// No description provided for @boundaryNoToughLoveBody.
  ///
  /// In tr, this message translates to:
  /// **'\"Kendine gel\" tarzı zorlayıcı bir yaklaşım istemiyorum.'**
  String get boundaryNoToughLoveBody;

  /// No description provided for @boundaryNoHistoryCallbacks.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş kayıtlarım hatırlatılmasın'**
  String get boundaryNoHistoryCallbacks;

  /// No description provided for @boundaryNoHistoryCallbacksBody.
  ///
  /// In tr, this message translates to:
  /// **'Eski günlüklerim ve kayıtlarım ben açmadıkça konuşmaya getirilmesin.'**
  String get boundaryNoHistoryCallbacksBody;

  /// No description provided for @introGotIt.
  ///
  /// In tr, this message translates to:
  /// **'Anladım'**
  String get introGotIt;

  /// No description provided for @introMoodTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ruh hali kaydı nedir?'**
  String get introMoodTitle;

  /// No description provided for @introMoodBody.
  ///
  /// In tr, this message translates to:
  /// **'Günde bir kez, o an nasıl hissettiğini birkaç kelimeyle işaretliyorsun. Altındaki iki çubuğu elinle de oynatabilirsin.\n\nBu kayıtlar, bugünün notunu ve haftalık özetini oluşturan ana veri — birkaç gün üst üste girdiğinde örüntüler görünmeye başlar.'**
  String get introMoodBody;

  /// No description provided for @introJournalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük nasıl işler?'**
  String get introJournalTitle;

  /// No description provided for @introJournalBody.
  ///
  /// In tr, this message translates to:
  /// **'Günde bir giriş yazabilirsin: aklından geçenler, o gün yaşadıkların, kimseye söylemediklerin. Yazdıkların yalnızca sana ait; paylaşılmaz.\n\nYarım kalan yazın taslak olarak saklanır, istersen sonra devam edersin. Geçmiş girişlerin aşağıdaki arşivde durur.'**
  String get introJournalBody;

  /// No description provided for @introChatTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet hakkında'**
  String get introChatTitle;

  /// No description provided for @introChatBody.
  ///
  /// In tr, this message translates to:
  /// **'Buraya istediğini yazabilirsin — dertleşmek, bir şeyi anlamaya çalışmak ya da sadece günü anlatmak için.\n\nHearth ruh hali kayıtlarını, günlüklerini ve sohbet tercihlerini bilerek cevap verir. Tıbbi tavsiye vermez; acil bir durumda 112\'yi hatırlatır.'**
  String get introChatBody;

  /// No description provided for @milestoneContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get milestoneContinue;

  /// No description provided for @milestoneFirstMoodTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlk ruh hali kaydın alındı'**
  String get milestoneFirstMoodTitle;

  /// No description provided for @milestoneFirstMoodBody.
  ///
  /// In tr, this message translates to:
  /// **'Güzel bir başlangıç. Birkaç gün daha işaretlersen, ana ekranındaki not ve grafikler senin örüntülerini göstermeye başlayacak.'**
  String get milestoneFirstMoodBody;

  /// No description provided for @milestoneFirstJournalTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlk günlük girişin hazır'**
  String get milestoneFirstJournalTitle;

  /// No description provided for @milestoneFirstJournalBody.
  ///
  /// In tr, this message translates to:
  /// **'Yazdıkların yalnızca sana ait. Yarın yeni bir giriş yazabilirsin; eskiler arşivinde seni bekliyor.'**
  String get milestoneFirstJournalBody;

  /// No description provided for @milestoneFirstChatTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlk sohbetin başladı'**
  String get milestoneFirstChatTitle;

  /// No description provided for @milestoneFirstChatBody.
  ///
  /// In tr, this message translates to:
  /// **'Konuştuklarınız hatırlanır, yani bir dahaki sefere baştan anlatmana gerek yok. Nasıl konuşulmasını istediğini Ayarlar\'dan her zaman değiştirebilirsin.'**
  String get milestoneFirstChatBody;

  /// No description provided for @assessmentOnboardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Seni biraz tanıyalım'**
  String get assessmentOnboardTitle;

  /// No description provided for @assessmentOnboardIntro.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı tamamlaman gereken, son iki haftana dair birkaç kısa test var — toplam {total} soru: ruh halin, kaygın, genel iyi oluşun ve daha fazlası. Sana nasıl yaklaşacağımızı bu belirler; istersen şimdi atlayıp sonra Ayarlar\'dan yapabilirsin.'**
  String assessmentOnboardIntro(int total);

  /// No description provided for @assessmentStart.
  ///
  /// In tr, this message translates to:
  /// **'Başla'**
  String get assessmentStart;

  /// No description provided for @assessmentSkip.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi değil'**
  String get assessmentSkip;

  /// No description provided for @assessmentProgress.
  ///
  /// In tr, this message translates to:
  /// **'{current} / {total}'**
  String assessmentProgress(int current, int total);

  /// No description provided for @assessmentSectionMood.
  ///
  /// In tr, this message translates to:
  /// **'Son iki hafta — ruh halin'**
  String get assessmentSectionMood;

  /// No description provided for @assessmentSectionAnxiety.
  ///
  /// In tr, this message translates to:
  /// **'Son iki hafta — kaygın'**
  String get assessmentSectionAnxiety;

  /// No description provided for @assessmentSectionWellbeing.
  ///
  /// In tr, this message translates to:
  /// **'Son iki hafta — genel iyi oluşun'**
  String get assessmentSectionWellbeing;

  /// No description provided for @assessmentSectionSomatic.
  ///
  /// In tr, this message translates to:
  /// **'Son dört hafta — bedensel belirtilerin'**
  String get assessmentSectionSomatic;

  /// No description provided for @assessmentSectionPtsd.
  ///
  /// In tr, this message translates to:
  /// **'Travmatik bir olay'**
  String get assessmentSectionPtsd;

  /// No description provided for @assessmentSectionAlcohol.
  ///
  /// In tr, this message translates to:
  /// **'Son bir yıl — alkol kullanımın'**
  String get assessmentSectionAlcohol;

  /// No description provided for @assessmentSectionSubstance.
  ///
  /// In tr, this message translates to:
  /// **'Son bir yıl — madde kullanımın'**
  String get assessmentSectionSubstance;

  /// No description provided for @assessmentPtsd5Intro.
  ///
  /// In tr, this message translates to:
  /// **'Bazen insanlar çok stresli olaylar yaşar — ciddi bir kaza, doğal afet, fiziksel ya da cinsel saldırı, savaş, ciddi şekilde dövülme ya da birinin ölümüne tanık olma gibi. Böyle bir şey yaşadıysan, geçen ay içinde şunları yaşadın mı?'**
  String get assessmentPtsd5Intro;

  /// No description provided for @assessmentAnswer0.
  ///
  /// In tr, this message translates to:
  /// **'Hiçbir zaman'**
  String get assessmentAnswer0;

  /// No description provided for @assessmentAnswer1.
  ///
  /// In tr, this message translates to:
  /// **'Bazı günler'**
  String get assessmentAnswer1;

  /// No description provided for @assessmentAnswer2.
  ///
  /// In tr, this message translates to:
  /// **'Günlerin yarıdan fazlasında'**
  String get assessmentAnswer2;

  /// No description provided for @assessmentAnswer3.
  ///
  /// In tr, this message translates to:
  /// **'Hemen hemen her gün'**
  String get assessmentAnswer3;

  /// No description provided for @assessmentAnswerNo.
  ///
  /// In tr, this message translates to:
  /// **'Hayır'**
  String get assessmentAnswerNo;

  /// No description provided for @assessmentAnswerYes.
  ///
  /// In tr, this message translates to:
  /// **'Evet'**
  String get assessmentAnswerYes;

  /// No description provided for @who5Answer0.
  ///
  /// In tr, this message translates to:
  /// **'Hiçbir zaman'**
  String get who5Answer0;

  /// No description provided for @who5Answer1.
  ///
  /// In tr, this message translates to:
  /// **'Ara sıra'**
  String get who5Answer1;

  /// No description provided for @who5Answer2.
  ///
  /// In tr, this message translates to:
  /// **'Yarıdan az bir sürede'**
  String get who5Answer2;

  /// No description provided for @who5Answer3.
  ///
  /// In tr, this message translates to:
  /// **'Yarıdan fazla bir sürede'**
  String get who5Answer3;

  /// No description provided for @who5Answer4.
  ///
  /// In tr, this message translates to:
  /// **'Çoğu zaman'**
  String get who5Answer4;

  /// No description provided for @who5Answer5.
  ///
  /// In tr, this message translates to:
  /// **'Her zaman'**
  String get who5Answer5;

  /// No description provided for @phq15Answer0.
  ///
  /// In tr, this message translates to:
  /// **'Hiç rahatsız etmedi'**
  String get phq15Answer0;

  /// No description provided for @phq15Answer1.
  ///
  /// In tr, this message translates to:
  /// **'Biraz rahatsız etti'**
  String get phq15Answer1;

  /// No description provided for @phq15Answer2.
  ///
  /// In tr, this message translates to:
  /// **'Çok rahatsız etti'**
  String get phq15Answer2;

  /// No description provided for @assessmentResultTitle.
  ///
  /// In tr, this message translates to:
  /// **'Teşekkürler'**
  String get assessmentResultTitle;

  /// No description provided for @assessmentResultNote.
  ///
  /// In tr, this message translates to:
  /// **'Bu bir tanı değil, sana nasıl yaklaşacağımızı ayarlamamıza yardımcı olan bir tarama sinyali.'**
  String get assessmentResultNote;

  /// No description provided for @assessmentResultDepression.
  ///
  /// In tr, this message translates to:
  /// **'Ruh hali taraması'**
  String get assessmentResultDepression;

  /// No description provided for @assessmentResultAnxiety.
  ///
  /// In tr, this message translates to:
  /// **'Kaygı taraması'**
  String get assessmentResultAnxiety;

  /// No description provided for @assessmentResultWellbeing.
  ///
  /// In tr, this message translates to:
  /// **'İyi oluş taraması'**
  String get assessmentResultWellbeing;

  /// No description provided for @assessmentResultSomatic.
  ///
  /// In tr, this message translates to:
  /// **'Bedensel belirti taraması'**
  String get assessmentResultSomatic;

  /// No description provided for @assessmentResultPtsd.
  ///
  /// In tr, this message translates to:
  /// **'Travma sonrası stres taraması'**
  String get assessmentResultPtsd;

  /// No description provided for @assessmentResultAlcohol.
  ///
  /// In tr, this message translates to:
  /// **'Alkol kullanım taraması'**
  String get assessmentResultAlcohol;

  /// No description provided for @assessmentResultSubstance.
  ///
  /// In tr, this message translates to:
  /// **'Madde kullanım taraması'**
  String get assessmentResultSubstance;

  /// No description provided for @assessmentBandMinimal.
  ///
  /// In tr, this message translates to:
  /// **'Minimal'**
  String get assessmentBandMinimal;

  /// No description provided for @assessmentBandMild.
  ///
  /// In tr, this message translates to:
  /// **'Hafif'**
  String get assessmentBandMild;

  /// No description provided for @assessmentBandModerate.
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get assessmentBandModerate;

  /// No description provided for @assessmentBandModeratelySevere.
  ///
  /// In tr, this message translates to:
  /// **'Orta-ağır'**
  String get assessmentBandModeratelySevere;

  /// No description provided for @assessmentBandSevere.
  ///
  /// In tr, this message translates to:
  /// **'Ağır'**
  String get assessmentBandSevere;

  /// No description provided for @assessmentBandVeryLow.
  ///
  /// In tr, this message translates to:
  /// **'Çok düşük'**
  String get assessmentBandVeryLow;

  /// No description provided for @assessmentBandLow.
  ///
  /// In tr, this message translates to:
  /// **'Düşük'**
  String get assessmentBandLow;

  /// No description provided for @assessmentBandMedium.
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get assessmentBandMedium;

  /// No description provided for @assessmentBandHigh.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek'**
  String get assessmentBandHigh;

  /// No description provided for @assessmentBandGood.
  ///
  /// In tr, this message translates to:
  /// **'İyi'**
  String get assessmentBandGood;

  /// No description provided for @assessmentBandCaution.
  ///
  /// In tr, this message translates to:
  /// **'Dikkat'**
  String get assessmentBandCaution;

  /// No description provided for @assessmentBandBelowThreshold.
  ///
  /// In tr, this message translates to:
  /// **'Eşiğin altında'**
  String get assessmentBandBelowThreshold;

  /// No description provided for @assessmentBandPositiveScreen.
  ///
  /// In tr, this message translates to:
  /// **'Daha yakından bakmaya değer'**
  String get assessmentBandPositiveScreen;

  /// No description provided for @assessmentContinueCta.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get assessmentContinueCta;

  /// No description provided for @assessmentSubmitError.
  ///
  /// In tr, this message translates to:
  /// **'Gönderilemedi, tekrar dener misin?'**
  String get assessmentSubmitError;

  /// No description provided for @assessmentRetakeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Öz-değerlendirme'**
  String get assessmentRetakeTitle;

  /// No description provided for @assessmentRetakeIntro.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı tamamlaman gereken testler var: yedi kısa test, toplam {total} soru — ruh halin, kaygın, genel iyi oluşun ve daha fazlası hakkında. Sonuçlar, sohbet ve önerilerinin arka planında kullanılır.'**
  String assessmentRetakeIntro(int total);

  /// No description provided for @assessmentRetakeCta.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirmeyi başlat'**
  String get assessmentRetakeCta;

  /// No description provided for @assessmentRetakeAgain.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden değerlendir'**
  String get assessmentRetakeAgain;

  /// No description provided for @assessmentLastTakenToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün yapıldı'**
  String get assessmentLastTakenToday;

  /// No description provided for @assessmentLastTaken.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün önce yapıldı'**
  String assessmentLastTaken(int days);

  /// No description provided for @assessmentNeverTaken.
  ///
  /// In tr, this message translates to:
  /// **'Henüz yapılmadı'**
  String get assessmentNeverTaken;

  /// No description provided for @phq9Q1.
  ///
  /// In tr, this message translates to:
  /// **'Yaptığınız işlere karşı ilgi azlığı ya da yaptığınız işlerden zevk almama'**
  String get phq9Q1;

  /// No description provided for @phq9Q2.
  ///
  /// In tr, this message translates to:
  /// **'Kendini çökkün, depresif ya da ümitsiz hissetme'**
  String get phq9Q2;

  /// No description provided for @phq9Q3.
  ///
  /// In tr, this message translates to:
  /// **'Uykuya dalmakta güçlük çekme, uykuyu sürdürmekte güçlük çekme ya da fazla uyuma'**
  String get phq9Q3;

  /// No description provided for @phq9Q4.
  ///
  /// In tr, this message translates to:
  /// **'Kendini yorgun hissetme ya da enerjinin az olması'**
  String get phq9Q4;

  /// No description provided for @phq9Q5.
  ///
  /// In tr, this message translates to:
  /// **'İştah azlığı ya da aşırı yeme'**
  String get phq9Q5;

  /// No description provided for @phq9Q6.
  ///
  /// In tr, this message translates to:
  /// **'Kendini kötü hissetme; kendini ya da ailesini hayal kırıklığına uğrattığını düşünme'**
  String get phq9Q6;

  /// No description provided for @phq9Q7.
  ///
  /// In tr, this message translates to:
  /// **'Gazete okumak ya da televizyon izlemek gibi işlere yoğunlaşmakta güçlük çekme'**
  String get phq9Q7;

  /// No description provided for @phq9Q8.
  ///
  /// In tr, this message translates to:
  /// **'Başkalarının fark edebileceği kadar yavaş hareket etme ya da konuşma; ya da tam tersi, her zamankinden daha hareketli ve huzursuz olma'**
  String get phq9Q8;

  /// No description provided for @phq9Q9.
  ///
  /// In tr, this message translates to:
  /// **'Ölü olsan daha iyi olur diye düşünme ya da bir şekilde kendine zarar verme'**
  String get phq9Q9;

  /// No description provided for @gad7Q1.
  ///
  /// In tr, this message translates to:
  /// **'Sinirli, kaygılı ya da gergin hissetme'**
  String get gad7Q1;

  /// No description provided for @gad7Q2.
  ///
  /// In tr, this message translates to:
  /// **'Endişelerini kontrol edememe ya da durduramama'**
  String get gad7Q2;

  /// No description provided for @gad7Q3.
  ///
  /// In tr, this message translates to:
  /// **'Farklı konularda çok fazla endişelenme'**
  String get gad7Q3;

  /// No description provided for @gad7Q4.
  ///
  /// In tr, this message translates to:
  /// **'Gevşeyip rahatlayamama'**
  String get gad7Q4;

  /// No description provided for @gad7Q5.
  ///
  /// In tr, this message translates to:
  /// **'Yerinde duramayacak kadar huzursuz olma'**
  String get gad7Q5;

  /// No description provided for @gad7Q6.
  ///
  /// In tr, this message translates to:
  /// **'Çabuk sinirlenme ya da huysuzlaşma'**
  String get gad7Q6;

  /// No description provided for @gad7Q7.
  ///
  /// In tr, this message translates to:
  /// **'Kötü bir şey olacakmış gibi korku hissetme'**
  String get gad7Q7;

  /// No description provided for @who5Q1.
  ///
  /// In tr, this message translates to:
  /// **'Kendimi neşeli ve keyifli hissettim.'**
  String get who5Q1;

  /// No description provided for @who5Q2.
  ///
  /// In tr, this message translates to:
  /// **'Kendimi sakin ve huzurlu hissettim.'**
  String get who5Q2;

  /// No description provided for @who5Q3.
  ///
  /// In tr, this message translates to:
  /// **'Kendimi enerjik ve aktif hissettim.'**
  String get who5Q3;

  /// No description provided for @who5Q4.
  ///
  /// In tr, this message translates to:
  /// **'Uyandığımda kendimi dinlenmiş ve zinde hissettim.'**
  String get who5Q4;

  /// No description provided for @who5Q5.
  ///
  /// In tr, this message translates to:
  /// **'Günlük hayatım ilgimi çeken şeylerle doluydu.'**
  String get who5Q5;

  /// No description provided for @phq15Q1.
  ///
  /// In tr, this message translates to:
  /// **'Mide ağrısı'**
  String get phq15Q1;

  /// No description provided for @phq15Q2.
  ///
  /// In tr, this message translates to:
  /// **'Sırt ağrısı'**
  String get phq15Q2;

  /// No description provided for @phq15Q3.
  ///
  /// In tr, this message translates to:
  /// **'Kollarda, bacaklarda veya eklemlerde ağrı'**
  String get phq15Q3;

  /// No description provided for @phq15Q4.
  ///
  /// In tr, this message translates to:
  /// **'Adet dönemiyle ilgili kramplar veya diğer sorunlar (kadınsan)'**
  String get phq15Q4;

  /// No description provided for @phq15Q5.
  ///
  /// In tr, this message translates to:
  /// **'Baş ağrısı'**
  String get phq15Q5;

  /// No description provided for @phq15Q6.
  ///
  /// In tr, this message translates to:
  /// **'Göğüs ağrısı'**
  String get phq15Q6;

  /// No description provided for @phq15Q7.
  ///
  /// In tr, this message translates to:
  /// **'Baş dönmesi'**
  String get phq15Q7;

  /// No description provided for @phq15Q8.
  ///
  /// In tr, this message translates to:
  /// **'Bayılma nöbetleri'**
  String get phq15Q8;

  /// No description provided for @phq15Q9.
  ///
  /// In tr, this message translates to:
  /// **'Kalbinin çarpması veya hızlı atması'**
  String get phq15Q9;

  /// No description provided for @phq15Q10.
  ///
  /// In tr, this message translates to:
  /// **'Nefes darlığı'**
  String get phq15Q10;

  /// No description provided for @phq15Q11.
  ///
  /// In tr, this message translates to:
  /// **'Cinsel ilişki sırasında ağrı veya başka sorunlar'**
  String get phq15Q11;

  /// No description provided for @phq15Q12.
  ///
  /// In tr, this message translates to:
  /// **'Kabızlık, gevşek bağırsak veya ishal'**
  String get phq15Q12;

  /// No description provided for @phq15Q13.
  ///
  /// In tr, this message translates to:
  /// **'Mide bulantısı, gaz veya hazımsızlık'**
  String get phq15Q13;

  /// No description provided for @phq15Q14.
  ///
  /// In tr, this message translates to:
  /// **'Kendini yorgun hissetme veya enerjisiz olma'**
  String get phq15Q14;

  /// No description provided for @phq15Q15.
  ///
  /// In tr, this message translates to:
  /// **'Uyku sorunları'**
  String get phq15Q15;

  /// No description provided for @ptsd5Q1.
  ///
  /// In tr, this message translates to:
  /// **'O olayla ilgili kabuslar gördün ya da istemeden aklına geldi mi?'**
  String get ptsd5Q1;

  /// No description provided for @ptsd5Q2.
  ///
  /// In tr, this message translates to:
  /// **'Olayı düşünmemek için çok çaba gösterdin ya da seni ona dair hatırlatan durumlardan kaçındın mı?'**
  String get ptsd5Q2;

  /// No description provided for @ptsd5Q3.
  ///
  /// In tr, this message translates to:
  /// **'Sürekli tetikte, dikkatli ya da kolayca irkilir durumda mıydın?'**
  String get ptsd5Q3;

  /// No description provided for @ptsd5Q4.
  ///
  /// In tr, this message translates to:
  /// **'Kendini uyuşmuş ya da çevrenden, uğraşlarından ya da insanlardan kopmuş hissettin mi?'**
  String get ptsd5Q4;

  /// No description provided for @ptsd5Q5.
  ///
  /// In tr, this message translates to:
  /// **'Olayla ilgili suçluluk hissettin ya da kendini ya da başkasını suçladın mı?'**
  String get ptsd5Q5;

  /// No description provided for @auditcQ1.
  ///
  /// In tr, this message translates to:
  /// **'Ne sıklıkla alkollü içecek içtin?'**
  String get auditcQ1;

  /// No description provided for @auditcQ1Opt0.
  ///
  /// In tr, this message translates to:
  /// **'Hiç'**
  String get auditcQ1Opt0;

  /// No description provided for @auditcQ1Opt1.
  ///
  /// In tr, this message translates to:
  /// **'Ayda bir veya daha az'**
  String get auditcQ1Opt1;

  /// No description provided for @auditcQ1Opt2.
  ///
  /// In tr, this message translates to:
  /// **'Ayda 2-4 kez'**
  String get auditcQ1Opt2;

  /// No description provided for @auditcQ1Opt3.
  ///
  /// In tr, this message translates to:
  /// **'Haftada 2-3 kez'**
  String get auditcQ1Opt3;

  /// No description provided for @auditcQ1Opt4.
  ///
  /// In tr, this message translates to:
  /// **'Haftada 4 veya daha fazla'**
  String get auditcQ1Opt4;

  /// No description provided for @auditcQ2.
  ///
  /// In tr, this message translates to:
  /// **'Alkol içtiğin tipik bir günde kaç kadeh içtin?'**
  String get auditcQ2;

  /// No description provided for @auditcQ2Opt0.
  ///
  /// In tr, this message translates to:
  /// **'1 veya 2'**
  String get auditcQ2Opt0;

  /// No description provided for @auditcQ2Opt1.
  ///
  /// In tr, this message translates to:
  /// **'3 veya 4'**
  String get auditcQ2Opt1;

  /// No description provided for @auditcQ2Opt2.
  ///
  /// In tr, this message translates to:
  /// **'5 veya 6'**
  String get auditcQ2Opt2;

  /// No description provided for @auditcQ2Opt3.
  ///
  /// In tr, this message translates to:
  /// **'7 ile 9 arası'**
  String get auditcQ2Opt3;

  /// No description provided for @auditcQ2Opt4.
  ///
  /// In tr, this message translates to:
  /// **'10 veya daha fazla'**
  String get auditcQ2Opt4;

  /// No description provided for @auditcQ3.
  ///
  /// In tr, this message translates to:
  /// **'Ne sıklıkla tek seferde 6 veya daha fazla kadeh içtin?'**
  String get auditcQ3;

  /// No description provided for @auditcQ3Opt0.
  ///
  /// In tr, this message translates to:
  /// **'Hiçbir zaman'**
  String get auditcQ3Opt0;

  /// No description provided for @auditcQ3Opt1.
  ///
  /// In tr, this message translates to:
  /// **'Ayda birden az'**
  String get auditcQ3Opt1;

  /// No description provided for @auditcQ3Opt2.
  ///
  /// In tr, this message translates to:
  /// **'Ayda bir kez'**
  String get auditcQ3Opt2;

  /// No description provided for @auditcQ3Opt3.
  ///
  /// In tr, this message translates to:
  /// **'Haftada bir kez'**
  String get auditcQ3Opt3;

  /// No description provided for @auditcQ3Opt4.
  ///
  /// In tr, this message translates to:
  /// **'Her gün ya da hemen her gün'**
  String get auditcQ3Opt4;

  /// No description provided for @cageaidQ1.
  ///
  /// In tr, this message translates to:
  /// **'Alkol ya da madde kullanımını azaltman gerektiğini hiç hissettin mi?'**
  String get cageaidQ1;

  /// No description provided for @cageaidQ2.
  ///
  /// In tr, this message translates to:
  /// **'İnsanlar alkol ya da madde kullanımını eleştirdiğinde rahatsız oldun mu?'**
  String get cageaidQ2;

  /// No description provided for @cageaidQ3.
  ///
  /// In tr, this message translates to:
  /// **'Alkol ya da madde kullanımın yüzünden kendini suçlu hissettin mi?'**
  String get cageaidQ3;

  /// No description provided for @cageaidQ4.
  ///
  /// In tr, this message translates to:
  /// **'Sinirlerini yatıştırmak ya da kendini daha iyi hissetmek için sabah ilk iş olarak alkol ya da madde kullandığın oldu mu?'**
  String get cageaidQ4;

  /// No description provided for @storiesAnonymousToggle.
  ///
  /// In tr, this message translates to:
  /// **'Anonim paylaş'**
  String get storiesAnonymousToggle;

  /// No description provided for @storiesAnonymousOnBody.
  ///
  /// In tr, this message translates to:
  /// **'Adın ve fotoğrafın görünmeyecek.'**
  String get storiesAnonymousOnBody;

  /// No description provided for @storiesAnonymousOffBody.
  ///
  /// In tr, this message translates to:
  /// **'Adın ve fotoğrafınla paylaşılacak.'**
  String get storiesAnonymousOffBody;

  /// No description provided for @profileStatStories.
  ///
  /// In tr, this message translates to:
  /// **'Hikaye'**
  String get profileStatStories;

  /// No description provided for @profileStatFollowers.
  ///
  /// In tr, this message translates to:
  /// **'Takipçi'**
  String get profileStatFollowers;

  /// No description provided for @profileStatFollowing.
  ///
  /// In tr, this message translates to:
  /// **'Takip'**
  String get profileStatFollowing;

  /// No description provided for @profileFollow.
  ///
  /// In tr, this message translates to:
  /// **'Takip et'**
  String get profileFollow;

  /// No description provided for @profileUnfollow.
  ///
  /// In tr, this message translates to:
  /// **'Takibi bırak'**
  String get profileUnfollow;

  /// No description provided for @profileNobodyYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kimse yok'**
  String get profileNobodyYet;

  /// No description provided for @myProfileEdit.
  ///
  /// In tr, this message translates to:
  /// **'Profili Düzenle'**
  String get myProfileEdit;

  /// No description provided for @myProfileStories.
  ///
  /// In tr, this message translates to:
  /// **'Hikayelerim'**
  String get myProfileStories;

  /// No description provided for @settingsDmPrivacy.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj gizliliği'**
  String get settingsDmPrivacy;

  /// No description provided for @settingsDmEveryone.
  ///
  /// In tr, this message translates to:
  /// **'Herkesten mesaj kabul et'**
  String get settingsDmEveryone;

  /// No description provided for @settingsDmFollowing.
  ///
  /// In tr, this message translates to:
  /// **'Sadece takip ettiklerimden kabul et'**
  String get settingsDmFollowing;

  /// No description provided for @settingsDmNoReceipts.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlarda okundu bilgisi yoktur.'**
  String get settingsDmNoReceipts;

  /// No description provided for @dmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlar'**
  String get dmTitle;

  /// No description provided for @dmTabInbox.
  ///
  /// In tr, this message translates to:
  /// **'Sohbetler'**
  String get dmTabInbox;

  /// No description provided for @dmTabRequests.
  ///
  /// In tr, this message translates to:
  /// **'İstekler'**
  String get dmTabRequests;

  /// No description provided for @dmNoThreads.
  ///
  /// In tr, this message translates to:
  /// **'Henüz sohbet yok'**
  String get dmNoThreads;

  /// No description provided for @dmNoRequests.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen istek yok'**
  String get dmNoRequests;

  /// No description provided for @dmMessage.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj gönder'**
  String get dmMessage;

  /// No description provided for @dmFollowersOnly.
  ///
  /// In tr, this message translates to:
  /// **'Sadece takip ettiklerinden mesaj alıyor'**
  String get dmFollowersOnly;

  /// No description provided for @dmRequestTitle.
  ///
  /// In tr, this message translates to:
  /// **'{name} kişisine yaz'**
  String dmRequestTitle(String name);

  /// No description provided for @dmRequestBody.
  ///
  /// In tr, this message translates to:
  /// **'İlk mesajın istek olarak gider. Kabul edilene kadar ikinci bir mesaj gönderemezsin.'**
  String get dmRequestBody;

  /// No description provided for @dmRequestHint.
  ///
  /// In tr, this message translates to:
  /// **'Bir şeyler yaz...'**
  String get dmRequestHint;

  /// No description provided for @dmRequestSent.
  ///
  /// In tr, this message translates to:
  /// **'İsteğin gönderildi.'**
  String get dmRequestSent;

  /// No description provided for @dmSend.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get dmSend;

  /// No description provided for @dmSendFailed.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj gönderilemedi.'**
  String get dmSendFailed;

  /// No description provided for @dmComposerHint.
  ///
  /// In tr, this message translates to:
  /// **'Bir şey yaz...'**
  String get dmComposerHint;

  /// No description provided for @dmAccept.
  ///
  /// In tr, this message translates to:
  /// **'Kabul et'**
  String get dmAccept;

  /// No description provided for @dmDecline.
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get dmDecline;

  /// No description provided for @dmAcceptPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Bu kişi seninle konuşmak istiyor. Cevap verirsen istek otomatik kabul edilir.'**
  String get dmAcceptPrompt;

  /// No description provided for @dmWaiting.
  ///
  /// In tr, this message translates to:
  /// **'Bekliyor'**
  String get dmWaiting;

  /// No description provided for @dmNewRequest.
  ///
  /// In tr, this message translates to:
  /// **'Yeni istek'**
  String get dmNewRequest;

  /// No description provided for @dmWaitingBody.
  ///
  /// In tr, this message translates to:
  /// **'İsteğin gönderildi. Kabul edilince yazabilirsin.'**
  String get dmWaitingBody;

  /// No description provided for @dmLeave.
  ///
  /// In tr, this message translates to:
  /// **'Sohbetten çık'**
  String get dmLeave;

  /// No description provided for @recapEntryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık Özetin'**
  String get recapEntryTitle;

  /// No description provided for @recapEntrySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu haftanı gör ve paylaş'**
  String get recapEntrySubtitle;

  /// No description provided for @recapTitle.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık Özet'**
  String get recapTitle;

  /// No description provided for @recapCheckins.
  ///
  /// In tr, this message translates to:
  /// **'Ruh hali girişi'**
  String get recapCheckins;

  /// No description provided for @recapJournalEntries.
  ///
  /// In tr, this message translates to:
  /// **'Günlük yazısı'**
  String get recapJournalEntries;

  /// No description provided for @recapActiveDays.
  ///
  /// In tr, this message translates to:
  /// **'Aktif gün'**
  String get recapActiveDays;

  /// No description provided for @recapMoodVeryPositive.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta oldukça keyifliydin.'**
  String get recapMoodVeryPositive;

  /// No description provided for @recapMoodPositive.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta genelde iyiydin.'**
  String get recapMoodPositive;

  /// No description provided for @recapMoodNeutral.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta dengeliydin.'**
  String get recapMoodNeutral;

  /// No description provided for @recapMoodMixed.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta inişli çıkışlıydı.'**
  String get recapMoodMixed;

  /// No description provided for @recapMoodHard.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta zorlu geçti. Kendine nazik davran.'**
  String get recapMoodHard;

  /// No description provided for @recapMoodEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta henüz check-in yapmadın.'**
  String get recapMoodEmpty;

  /// No description provided for @recapShare.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get recapShare;

  /// No description provided for @recapShareText.
  ///
  /// In tr, this message translates to:
  /// **'Hearth\'te bu hafta {checkins} ruh hali girişi yaptım, {streak} günlük serim var.'**
  String recapShareText(int checkins, int streak);

  /// No description provided for @lifeMoodHistoryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ruh Hali Geçmişin'**
  String get lifeMoodHistoryTitle;

  /// No description provided for @lifeMoodHistoryEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz check-in yok'**
  String get lifeMoodHistoryEmpty;

  /// No description provided for @lifeMoodHistoryLegendLow.
  ///
  /// In tr, this message translates to:
  /// **'Zorlu'**
  String get lifeMoodHistoryLegendLow;

  /// No description provided for @lifeMoodHistoryLegendHigh.
  ///
  /// In tr, this message translates to:
  /// **'Keyifli'**
  String get lifeMoodHistoryLegendHigh;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabı Sil'**
  String get settingsDeleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabını silmek istediğine emin misin?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem geri alınamaz. Ruh hali kayıtların, günlüklerin, hikayelerin, mesajların ve hesabınla ilgili her şey kalıcı olarak silinir.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountPasswordHint.
  ///
  /// In tr, this message translates to:
  /// **'Onaylamak için şifreni gir'**
  String get deleteAccountPasswordHint;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Kalıcı Olarak Sil'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountWrongPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre yanlış.'**
  String get deleteAccountWrongPassword;

  /// No description provided for @deleteAccountDone.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın silindi.'**
  String get deleteAccountDone;

  /// No description provided for @storiesReactionDestek.
  ///
  /// In tr, this message translates to:
  /// **'Yalnız değilsin'**
  String get storiesReactionDestek;

  /// No description provided for @storiesReactionGuclusun.
  ///
  /// In tr, this message translates to:
  /// **'Güçlüsün'**
  String get storiesReactionGuclusun;

  /// No description provided for @storiesReactionAnliyorum.
  ///
  /// In tr, this message translates to:
  /// **'Anlıyorum'**
  String get storiesReactionAnliyorum;

  /// No description provided for @storiesHighlightsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Öne Çıkanlar'**
  String get storiesHighlightsTitle;

  /// No description provided for @settingsPremiumRow.
  ///
  /// In tr, this message translates to:
  /// **'Hearth Plus'**
  String get settingsPremiumRow;

  /// No description provided for @premiumTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hearth Plus'**
  String get premiumTitle;

  /// No description provided for @premiumPitch.
  ///
  /// In tr, this message translates to:
  /// **'Hearth\'i daha derinlemesine kullanmak isteyenler için.'**
  String get premiumPitch;

  /// No description provided for @premiumFeatureChat.
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız AI sohbet'**
  String get premiumFeatureChat;

  /// No description provided for @premiumFeatureAnalysis.
  ///
  /// In tr, this message translates to:
  /// **'Daha sık yaşam analizi'**
  String get premiumFeatureAnalysis;

  /// No description provided for @premiumFeatureInsights.
  ///
  /// In tr, this message translates to:
  /// **'Gelişmiş, kişiselleştirilmiş içgörüler'**
  String get premiumFeatureInsights;

  /// No description provided for @premiumPricePerMonth.
  ///
  /// In tr, this message translates to:
  /// **'{price} / ay'**
  String premiumPricePerMonth(String price);

  /// No description provided for @premiumSubscribe.
  ///
  /// In tr, this message translates to:
  /// **'Abone Ol'**
  String get premiumSubscribe;

  /// No description provided for @premiumRestore.
  ///
  /// In tr, this message translates to:
  /// **'Satın Almaları Geri Yükle'**
  String get premiumRestore;

  /// No description provided for @premiumActiveUntil.
  ///
  /// In tr, this message translates to:
  /// **'Aboneliğin {date} tarihine kadar aktif.'**
  String premiumActiveUntil(String date);

  /// No description provided for @premiumAlreadyActive.
  ///
  /// In tr, this message translates to:
  /// **'Hearth Plus zaten aktif'**
  String get premiumAlreadyActive;

  /// No description provided for @premiumTerms.
  ///
  /// In tr, this message translates to:
  /// **'Abonelik otomatik olarak yenilenir; mevcut dönem bitmeden en az 24 saat önce iptal etmezsen ücret otomatik tahsil edilir. Aboneliği istediğin zaman App Store > Ayarlar üzerinden iptal edebilirsin.'**
  String get premiumTerms;

  /// No description provided for @premiumUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma şu anda kullanılamıyor.'**
  String get premiumUnavailable;

  /// No description provided for @premiumRestored.
  ///
  /// In tr, this message translates to:
  /// **'Satın almaların geri yüklendi.'**
  String get premiumRestored;

  /// No description provided for @premiumPrivacyPolicy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get premiumPrivacyPolicy;

  /// No description provided for @premiumTermsOfUse.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Koşulları'**
  String get premiumTermsOfUse;

  /// No description provided for @chatQuotaExceeded.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü ücretsiz sohbet hakkın doldu. Hearth Plus ile sınırsız sohbet edebilirsin.'**
  String get chatQuotaExceeded;

  /// No description provided for @voiceDictate.
  ///
  /// In tr, this message translates to:
  /// **'Sesle yaz'**
  String get voiceDictate;

  /// No description provided for @voiceListening.
  ///
  /// In tr, this message translates to:
  /// **'Dinliyorum…'**
  String get voiceListening;

  /// No description provided for @voiceUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihazda sesle yazma şu an kullanılamıyor.'**
  String get voiceUnavailable;

  /// No description provided for @voicePermissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'Sesle yazmak için mikrofon izni gerekiyor. Telefonunun ayarlarından Hearth\'e izin verebilirsin.'**
  String get voicePermissionDenied;

  /// No description provided for @voiceSpeak.
  ///
  /// In tr, this message translates to:
  /// **'Sesli oku'**
  String get voiceSpeak;

  /// No description provided for @voiceStopSpeaking.
  ///
  /// In tr, this message translates to:
  /// **'Okumayı durdur'**
  String get voiceStopSpeaking;

  /// No description provided for @discoveriesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Seni iyi hissettirenler'**
  String get discoveriesTitle;

  /// No description provided for @discoveriesSeeAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get discoveriesSeeAll;

  /// No description provided for @discoveriesKindLifts.
  ///
  /// In tr, this message translates to:
  /// **'İyi geliyor'**
  String get discoveriesKindLifts;

  /// No description provided for @discoveriesKindDrains.
  ///
  /// In tr, this message translates to:
  /// **'Yoruyor'**
  String get discoveriesKindDrains;

  /// No description provided for @discoveriesKindRhythm.
  ///
  /// In tr, this message translates to:
  /// **'Döngü'**
  String get discoveriesKindRhythm;

  /// No description provided for @discoveriesError.
  ///
  /// In tr, this message translates to:
  /// **'Keşiflerin şu an yüklenemedi.'**
  String get discoveriesError;

  /// No description provided for @discoveriesEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz belirgin bir şey yok'**
  String get discoveriesEmptyTitle;

  /// No description provided for @discoveriesEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlarında şimdilik tekrar eden net bir örüntü görünmüyor. Ruh haline birkaç kelime ya da kısa bir not ekledikçe burası dolacak.'**
  String get discoveriesEmptyBody;

  /// No description provided for @discoveriesFootnote.
  ///
  /// In tr, this message translates to:
  /// **'Bu, yalnızca senin kayıtlarında görülen bir eğilim; kesin bir sonuç ya da tanı değil.'**
  String get discoveriesFootnote;

  /// No description provided for @discoveriesLockedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Keşiflerin yolda'**
  String get discoveriesLockedTitle;

  /// No description provided for @discoveriesLockedBody.
  ///
  /// In tr, this message translates to:
  /// **'Seni neyin iyi hissettirdiğini görebilmem için birkaç gün daha ruh hali kaydı gerekiyor.'**
  String get discoveriesLockedBody;

  /// No description provided for @discoveriesLockedProgress.
  ///
  /// In tr, this message translates to:
  /// **'{logged}/{needed} gün'**
  String discoveriesLockedProgress(int logged, int needed);

  /// No description provided for @notificationsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notificationsTitle;

  /// No description provided for @notificationsCheckinTitle.
  ///
  /// In tr, this message translates to:
  /// **'Akşam kontrolü'**
  String get notificationsCheckinTitle;

  /// No description provided for @notificationsCheckinBody.
  ///
  /// In tr, this message translates to:
  /// **'O gün ruh halini kaydetmediysen, seçtiğin saatte tek bir nazik hatırlatma gelir. Kaydettiysen hiç rahatsız etmez.'**
  String get notificationsCheckinBody;

  /// No description provided for @notificationsTimeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Saat'**
  String get notificationsTimeLabel;

  /// No description provided for @notificationsPreviewLabel.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim böyle görünür'**
  String get notificationsPreviewLabel;

  /// No description provided for @notificationsPreviewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugün nasıldı?'**
  String get notificationsPreviewTitle;

  /// No description provided for @notificationsPreviewBody.
  ///
  /// In tr, this message translates to:
  /// **'Yarım dakika yeter — bugün nasıl hissettiğin, yarınki notunu şekillendirir.'**
  String get notificationsPreviewBody;

  /// No description provided for @notificationsWebNote.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler şimdilik yalnızca telefon uygulamasında gelir; tercihin yine de kaydedilir.'**
  String get notificationsWebNote;

  /// No description provided for @settingsNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsOn.
  ///
  /// In tr, this message translates to:
  /// **'Akşam kontrolü · {time}'**
  String settingsNotificationsOn(String time);

  /// No description provided for @settingsNotificationsOff.
  ///
  /// In tr, this message translates to:
  /// **'Akşam kontrolü kapalı'**
  String get settingsNotificationsOff;

  /// No description provided for @metooButton.
  ///
  /// In tr, this message translates to:
  /// **'Bende de oldu'**
  String get metooButton;

  /// No description provided for @metooCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} kişi'**
  String metooCount(int count);

  /// No description provided for @metooWithYou.
  ///
  /// In tr, this message translates to:
  /// **'Sen ve {count} kişi daha'**
  String metooWithYou(int count);

  /// No description provided for @metooYouSaidIt.
  ///
  /// In tr, this message translates to:
  /// **'Yazana iletildi'**
  String get metooYouSaidIt;

  /// No description provided for @metooSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu senin de hikayen mi?'**
  String get metooSheetTitle;

  /// No description provided for @metooSheetBody.
  ///
  /// In tr, this message translates to:
  /// **'Yazana kim olduğun asla gösterilmez. İstersen ona kısa bir not bırakabilirsin.'**
  String get metooSheetBody;

  /// No description provided for @metooNoteNotAlone.
  ///
  /// In tr, this message translates to:
  /// **'Yalnız değilsin'**
  String get metooNoteNotAlone;

  /// No description provided for @metooNoteSameHere.
  ///
  /// In tr, this message translates to:
  /// **'Ben de benzerini yaşadım'**
  String get metooNoteSameHere;

  /// No description provided for @metooNoteThanks.
  ///
  /// In tr, this message translates to:
  /// **'Paylaştığın için teşekkürler'**
  String get metooNoteThanks;

  /// No description provided for @metooNoteStrength.
  ///
  /// In tr, this message translates to:
  /// **'Sana güç yolluyorum'**
  String get metooNoteStrength;

  /// No description provided for @metooJustMark.
  ///
  /// In tr, this message translates to:
  /// **'Not bırakmadan işaretle'**
  String get metooJustMark;

  /// No description provided for @metooSent.
  ///
  /// In tr, this message translates to:
  /// **'Yazana iletildi. Kim olduğun gösterilmedi.'**
  String get metooSent;

  /// No description provided for @metooOwnCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} kişi bu hikayede kendini buldu'**
  String metooOwnCount(int count);

  /// No description provided for @metooOwnPrivacy.
  ///
  /// In tr, this message translates to:
  /// **'Kim oldukları sana gösterilmez; yalnızca bıraktıkları notları görürsün.'**
  String get metooOwnPrivacy;

  /// No description provided for @sessionEntryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Seans öncesi özetim'**
  String get sessionEntryTitle;

  /// No description provided for @sessionEntryBody.
  ///
  /// In tr, this message translates to:
  /// **'Terapistine götürmek için son dönemini tek sayfada hazırla.'**
  String get sessionEntryBody;

  /// No description provided for @sessionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Seans öncesi özet'**
  String get sessionTitle;

  /// No description provided for @sessionIntro.
  ///
  /// In tr, this message translates to:
  /// **'Terapistine ya da psikiyatristine götürebileceğin tek sayfalık bir özet: bu dönem nasıl geçti, neler tekrar etti, neler zorladı, neler iyi geldi. Yalnızca senin kendi kayıtlarından hazırlanır.'**
  String get sessionIntro;

  /// No description provided for @sessionPeriodLabel.
  ///
  /// In tr, this message translates to:
  /// **'Hangi dönemi özetleyelim?'**
  String get sessionPeriodLabel;

  /// No description provided for @sessionPeriodWeek.
  ///
  /// In tr, this message translates to:
  /// **'Son 1 hafta'**
  String get sessionPeriodWeek;

  /// No description provided for @sessionPeriodTwoWeeks.
  ///
  /// In tr, this message translates to:
  /// **'Son 2 hafta'**
  String get sessionPeriodTwoWeeks;

  /// No description provided for @sessionPeriodMonth.
  ///
  /// In tr, this message translates to:
  /// **'Son 1 ay'**
  String get sessionPeriodMonth;

  /// No description provided for @sessionNoteLabel.
  ///
  /// In tr, this message translates to:
  /// **'Bu seansta konuşmak istediğin bir şey var mı?'**
  String get sessionNoteLabel;

  /// No description provided for @sessionNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'İsteğe bağlı. Örn. uyku sorunlarım, işteki gerginlik'**
  String get sessionNoteHint;

  /// No description provided for @sessionGenerate.
  ///
  /// In tr, this message translates to:
  /// **'Özeti hazırla'**
  String get sessionGenerate;

  /// No description provided for @sessionRegenerate.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden hazırla'**
  String get sessionRegenerate;

  /// No description provided for @sessionGenerating.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtların okunuyor…'**
  String get sessionGenerating;

  /// No description provided for @sessionGeneratingBody.
  ///
  /// In tr, this message translates to:
  /// **'Ruh hali kayıtların, günlüklerin ve sohbetlerin bir araya getiriliyor. Bu yarım dakika kadar sürebilir.'**
  String get sessionGeneratingBody;

  /// No description provided for @sessionDocTitle.
  ///
  /// In tr, this message translates to:
  /// **'Seans öncesi özet'**
  String get sessionDocTitle;

  /// No description provided for @sessionStats.
  ///
  /// In tr, this message translates to:
  /// **'{moodDays} gün ruh hali kaydı · {journals} günlük'**
  String sessionStats(int moodDays, int journals);

  /// No description provided for @sessionOverview.
  ///
  /// In tr, this message translates to:
  /// **'Genel tablo'**
  String get sessionOverview;

  /// No description provided for @sessionMoodCourse.
  ///
  /// In tr, this message translates to:
  /// **'Ruh hali seyri'**
  String get sessionMoodCourse;

  /// No description provided for @sessionThemes.
  ///
  /// In tr, this message translates to:
  /// **'Öne çıkan konular'**
  String get sessionThemes;

  /// No description provided for @sessionHardMoments.
  ///
  /// In tr, this message translates to:
  /// **'Zorlayan anlar'**
  String get sessionHardMoments;

  /// No description provided for @sessionWhatHelped.
  ///
  /// In tr, this message translates to:
  /// **'İyi gelenler'**
  String get sessionWhatHelped;

  /// No description provided for @sessionQuestions.
  ///
  /// In tr, this message translates to:
  /// **'Konuşmak istediklerim'**
  String get sessionQuestions;

  /// No description provided for @sessionScreening.
  ///
  /// In tr, this message translates to:
  /// **'Son öz değerlendirme'**
  String get sessionScreening;

  /// No description provided for @sessionScreeningAgo.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün önce'**
  String sessionScreeningAgo(int days);

  /// No description provided for @sessionScreeningDepression.
  ///
  /// In tr, this message translates to:
  /// **'Depresyon (PHQ-9)'**
  String get sessionScreeningDepression;

  /// No description provided for @sessionScreeningAnxiety.
  ///
  /// In tr, this message translates to:
  /// **'Kaygı (GAD-7)'**
  String get sessionScreeningAnxiety;

  /// No description provided for @sessionScreeningWellbeing.
  ///
  /// In tr, this message translates to:
  /// **'İyi oluş (WHO-5)'**
  String get sessionScreeningWellbeing;

  /// No description provided for @sessionShare.
  ///
  /// In tr, this message translates to:
  /// **'PDF olarak paylaş'**
  String get sessionShare;

  /// No description provided for @sessionNotEnough.
  ///
  /// In tr, this message translates to:
  /// **'Bu dönemde hiç ruh hali ya da günlük kaydın yok. Daha uzun bir dönem seç ya da birkaç gün kayıt girip tekrar dene.'**
  String get sessionNotEnough;

  /// No description provided for @sessionDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Bu özet senin kendi kayıtlarından hazırlandı; tanı ya da tıbbi değerlendirme değildir.'**
  String get sessionDisclaimer;

  /// No description provided for @sessionPdfFooter.
  ///
  /// In tr, this message translates to:
  /// **'Hearth · kişinin kendi kayıtlarından hazırlanmıştır, tanı değildir'**
  String get sessionPdfFooter;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
