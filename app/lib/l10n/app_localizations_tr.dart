// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Mental AI';

  @override
  String get commonRetry => 'Tekrar dene';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonCancel => 'Vazgeç';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonError => 'Bir şeyler ters gitti';

  @override
  String get commonLoading => 'Yükleniyor';

  @override
  String get navReport => 'Ana Ekran';

  @override
  String get navMood => 'Ruh Hali';

  @override
  String get navJournal => 'Günlük';

  @override
  String get navChat => 'Sohbet';

  @override
  String get navGuide => 'Rehber';

  @override
  String get navLife => 'Yaşam';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get greetingNight => 'İyi geceler';

  @override
  String get greetingMorning => 'Günaydın';

  @override
  String get greetingDay => 'İyi günler';

  @override
  String get greetingEvening => 'İyi akşamlar';

  @override
  String get homeStateNoData => 'Henüz bir kayıt yok';

  @override
  String get homeStateNoDataNote =>
      'Bir ruh hali kaydı ekle ya da sohbet et; durumun buraya yansısın.';

  @override
  String get homeMoodLabel => 'Keyif';

  @override
  String get homeEnergyLabel => 'Enerji';

  @override
  String get homeBarBad => 'KÖTÜ';

  @override
  String get homeBarGood => 'İYİ';

  @override
  String homeBasedOn(String sources) {
    return 'Şuna göre: $sources';
  }

  @override
  String get homeDiagnosesTitle => 'TANILARIM';

  @override
  String get homeToday => 'Bugün';

  @override
  String get homeRecommendations => 'Öneriler';

  @override
  String get homeNoReport => 'Henüz bugüne ait bir raporun yok.';

  @override
  String get homeGenerateReport => 'Rapor oluştur';

  @override
  String get homeRefreshing => 'Durumun yeniden değerlendiriliyor';

  @override
  String get homeCrisisWarning =>
      'Son kayıtlarında zorlu ifadeler fark ettik. Acil durumdaysan 112\'yi ara; konuşmak istersen bir uzmana ulaşmayı düşünebilirsin.';

  @override
  String get guideTitle => 'Rehber';

  @override
  String get guideSearchHint => 'Tanı ara';

  @override
  String guideSearchEmpty(String query) {
    return '\"$query\" için sonuç yok';
  }

  @override
  String get guideCategoryAll => 'Genel';

  @override
  String guideDisorderCount(int count) {
    return '$count tanı';
  }

  @override
  String get guideOpenCard => 'Bilgi kartını gör';

  @override
  String get guideResearchInCategory => 'Bu kategoriden araştırmalar';

  @override
  String get guideEmptyInCategory => 'Bu kategoride henüz araştırma kartı yok';

  @override
  String get guideEmptyFeed => 'Henüz bir içgörü yok';

  @override
  String get guideEmptyInCategoryBody =>
      'Yukarıdaki başlıklardan birine dokunarak o durumla ilgili bilgi kartını okuyabilirsin. Araştırma kartları, arka plandaki servis bu kategoride yeni makale buldukça burada birikir.';

  @override
  String get guideEmptyFeedBody =>
      'Arka planda çalışan araştırma servisi yeni makaleler topladıkça bu ekran güncellenecek. Beklemek istemezsen zaten toplanmış makalelerden şimdi bir içgörü çıkarabilirsin.';

  @override
  String get guideSynthesizeNow => 'Şimdi oluştur';

  @override
  String get cardTitle => 'Bilgi Kartı';

  @override
  String get cardWhatIsIt => 'Nedir?';

  @override
  String get cardHowDevelops => 'Nasıl gelişir?';

  @override
  String get cardWhatHelps => 'Günlük hayatta ne yardımcı olur?';

  @override
  String get cardProfessionalHelp => 'Profesyonel destek neleri içerir?';

  @override
  String get cardDisclaimer =>
      'Bu sayfa yalnızca bilgilendirme amaçlıdır ve tanı koymaz. Kendinde bu belirtileri görüyorsan bir ruh sağlığı uzmanına danış.';

  @override
  String get cardPreparing => 'Bilgi kartı hazırlanıyor';

  @override
  String get cardPreparingBody =>
      'Bu başlık ilk kez açılıyor; araştırma kaynaklarından derleniyor. Bir sonraki açılışta anında gelecek.';

  @override
  String get cardLoadFailed => 'Bilgi kartı yüklenemedi';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsConnection => 'Bağlantı';

  @override
  String get settingsServer => 'Sunucu adresi';

  @override
  String get settingsDeviceId => 'Cihaz kimliği';

  @override
  String get settingsPrivacy => 'Gizlilik ve Güvenlik';

  @override
  String get settingsDataLocation => 'Verilerin nerede duruyor';

  @override
  String get settingsDataLocationBody =>
      'Yalnızca kendi bilgisayarındaki yerel veritabanında saklanır.';

  @override
  String get settingsLegal => 'Yasal uyarı';

  @override
  String get settingsLegalBody =>
      'Mental AI lisanslı bir sağlık uzmanının yerini tutmaz. Acil bir durumdaysan 112\'yi ara.';

  @override
  String get settingsAccount => 'Hesap';

  @override
  String get settingsProfile => 'Profilim';

  @override
  String get settingsProfileBody => 'E-posta, yaş, dil ve tanıların.';

  @override
  String get settingsLogout => 'Çıkış yap';

  @override
  String get profileTitle => 'Profilim';

  @override
  String get profileEmail => 'E-posta';

  @override
  String get profileLanguage => 'Dil';

  @override
  String get profileLanguageTurkish => 'Türkçe';

  @override
  String get profileLanguageEnglish => 'İngilizce';

  @override
  String get profileBirthYear => 'Doğum yılı';

  @override
  String get profileBirthYearHint => 'örn. 1998';

  @override
  String profileAgeValue(int age) {
    return '$age yaşında';
  }

  @override
  String get profileAgeWhy =>
      'Yaşını bilmek, önerilerin yaşadığın döneme uygun olmasını sağlar.';

  @override
  String get profileDiagnoses => 'Tanılarım';

  @override
  String get profileSaved => 'Profilin kaydedildi.';

  @override
  String get profileInvalidYear => 'Geçerli bir doğum yılı gir.';

  @override
  String get diagnosesTitle => 'Tanılarım';

  @override
  String get diagnosesNote =>
      'Burada seçtiklerin yalnızca senin bildirdiğin bilgilerdir; uygulama tanı koymaz. Seçtiklerin raporlarını ve sohbeti sana göre şekillendirmek için kullanılır.';

  @override
  String diagnosesSelectedCount(int count) {
    return '$count seçili';
  }

  @override
  String get diagnosesSaved => 'Tanıların kaydedildi.';

  @override
  String get diagnosesLoadFailed => 'Kategoriler yüklenemedi.';

  @override
  String get authRegisterTitle => 'Hesabını oluştur';

  @override
  String get authLoginTitle => 'Hesabına giriş yap';

  @override
  String get authPassword => 'Şifre (en az 8 karakter)';

  @override
  String get authDisclaimer =>
      'Mental AI lisanslı bir psikolog, psikiyatrist ya da tıbbi bir cihaz değildir; tanı koymaz. Kriz anında lütfen 112\'yi veya bir uzmanı ara.';

  @override
  String get authRegisterCta => 'Hesap oluştur';

  @override
  String get authLoginCta => 'Giriş yap';

  @override
  String get authSwitchToLogin => 'Zaten hesabın var mı? Giriş yap';

  @override
  String get authSwitchToRegister => 'Hesabın yok mu? Kayıt ol';

  @override
  String get moodDoneToday => 'Bugünkü kaydın alındı';

  @override
  String get moodHowAreYou => 'Şu an nasılsın?';

  @override
  String moodNextIn(String time) {
    return 'Sonraki kayıt $time sonra açılıyor';
  }

  @override
  String get moodDragHint => 'Noktayı hissettiğin yere sürükle';

  @override
  String get moodSaved => 'Kaydedildi. Teşekkürler!';

  @override
  String get moodTryTomorrow => 'Yarın tekrar dene';

  @override
  String get moodEnergetic => 'Enerjik';

  @override
  String get moodCalm => 'Sakin';

  @override
  String get moodUnpleasant => 'Zorlayıcı';

  @override
  String get moodPleasant => 'Keyifli';

  @override
  String get journalSaved => 'Günlük kaydedildi.';

  @override
  String get journalHint => 'Bugün aklından ne geçti?';

  @override
  String get journalPast => 'GEÇMİŞ GÜNLÜKLER';

  @override
  String get journalEmpty => 'Henüz bir günlük yazmadın.';

  @override
  String get journalDoneToday => 'Bugünkü günlüğün yazıldı';

  @override
  String journalNextIn(String time) {
    return 'Sonraki giriş $time sonra açılıyor';
  }

  @override
  String get chatEmptyPrompt => 'Bir şey paylaşmak ister misin?';

  @override
  String get chatInputHint => 'Bir şey yaz...';

  @override
  String get chatCrisis =>
      'Zor bir an gibi görünüyor. Acil durumdaysan 112\'yi ara; konuşmak istersen bir uzmana ulaşmayı düşünebilirsin.';

  @override
  String get lifeTitle => 'Yaşam Analizi';

  @override
  String get lifeCooldownTooltip => 'Haftada bir yenilenebilir';

  @override
  String get lifeRegenerate => 'Yeniden analiz et';

  @override
  String get lifeOverview => 'Genel görünüm';

  @override
  String get lifePatterns => 'Öne çıkan örüntüler';

  @override
  String get lifeDoList => 'Yapman iyi gelenler';

  @override
  String get lifeDontList => 'Sana zorluk çıkaranlar';

  @override
  String get lifeEmpty => 'Henüz bir yaşam analizin yok.';

  @override
  String get lifeEmptyBody =>
      'Tüm ruh hali, günlük, sohbet ve rapor geçmişine bakarak bir analiz oluşturulur.';

  @override
  String get lifeGenerate => 'Analiz oluştur';
}
