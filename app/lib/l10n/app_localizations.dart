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
  /// **'Mental AI'**
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

  /// No description provided for @navChat.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet'**
  String get navChat;

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
  /// **'TANILARIM'**
  String get homeDiagnosesTitle;

  /// No description provided for @homeToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get homeToday;

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
  /// **'Mental AI lisanslı bir sağlık uzmanının yerini tutmaz. Acil bir durumdaysan 112\'yi ara.'**
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

  /// No description provided for @settingsStoriesBody.
  ///
  /// In tr, this message translates to:
  /// **'Deneyimini paylaş, başkalarının hikayelerini oku.'**
  String get settingsStoriesBody;

  /// No description provided for @settingsModeration.
  ///
  /// In tr, this message translates to:
  /// **'Moderasyon'**
  String get settingsModeration;

  /// No description provided for @settingsModerationBody.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen ve bildirilen hikayeleri incele.'**
  String get settingsModerationBody;

  /// No description provided for @settingsAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get settingsAccount;

  /// No description provided for @settingsProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profilim'**
  String get settingsProfile;

  /// No description provided for @settingsProfileBody.
  ///
  /// In tr, this message translates to:
  /// **'E-posta, yaş, dil ve tanıların.'**
  String get settingsProfileBody;

  /// No description provided for @settingsLogout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yap'**
  String get settingsLogout;

  /// No description provided for @profileTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profilim'**
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

  /// No description provided for @authLoginTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabına giriş yap'**
  String get authLoginTitle;

  /// No description provided for @authPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre (en az 8 karakter)'**
  String get authPassword;

  /// No description provided for @authDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Mental AI lisanslı bir psikolog, psikiyatrist ya da tıbbi bir cihaz değildir; tanı koymaz. Kriz anında lütfen 112\'yi veya bir uzmanı ara.'**
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

  /// No description provided for @moodDoneToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü kaydın alındı'**
  String get moodDoneToday;

  /// No description provided for @moodHowAreYou.
  ///
  /// In tr, this message translates to:
  /// **'Şu an nasılsın?'**
  String get moodHowAreYou;

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

  /// No description provided for @journalHint.
  ///
  /// In tr, this message translates to:
  /// **'Bugün aklından ne geçti?'**
  String get journalHint;

  /// No description provided for @journalPast.
  ///
  /// In tr, this message translates to:
  /// **'GEÇMİŞ GÜNLÜKLER'**
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

  /// No description provided for @storiesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hikayeler'**
  String get storiesTitle;

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
