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
  String get navStories => 'Hikayeler';

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
  String get homeDiagnosesTitle => 'Tanılarım';

  @override
  String get homeToday => 'Bugünün notu';

  @override
  String get streakLabel => 'Seri';

  @override
  String get streakDays => 'gün';

  @override
  String get streakJournalLabel => 'gün seri';

  @override
  String get streakPeriodLabel => 'Dönem serisi';

  @override
  String streakPeriodValue(int active, int total) {
    return '$active / $total gün';
  }

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
  String get guideResearchFeed => 'Bu hafta okunanlardan';

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
  String get settingsAppearance => 'Görünüm';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsThemeLight => 'Açık';

  @override
  String get settingsThemeDark => 'Koyu';

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
  String get settingsCommunity => 'Topluluk';

  @override
  String get settingsStories => 'Hikayeler';

  @override
  String get settingsModeration => 'Moderasyon';

  @override
  String get settingsAdminBadge => 'Admin';

  @override
  String get settingsAccount => 'Hesap';

  @override
  String get settingsProfile => 'Profilim';

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
  String diagnosesCatalogSize(int categories, int total) {
    return '$categories kategori · $total tanı';
  }

  @override
  String get diagnosesSaved => 'Tanıların kaydedildi.';

  @override
  String get diagnosesLoadFailed => 'Kategoriler yüklenemedi.';

  @override
  String get authRegisterTitle => 'Hesabını oluştur';

  @override
  String get authRegisterNote =>
      'Birkaç saniye sürer. Hiçbir şey paylaşmak zorunda değilsin.';

  @override
  String get authWelcomeBack => 'Tekrar hoş geldin';

  @override
  String get authWelcomeNote =>
      'Kaldığın yerden devam edelim. Hiçbir şey paylaşmak zorunda değilsin.';

  @override
  String get authLoginTitle => 'Hesabına giriş yap';

  @override
  String get authPasswordLabel => 'Şifre';

  @override
  String get authPasswordRule => 'En az 8 karakter.';

  @override
  String get authShowPassword => 'Göster';

  @override
  String get authHidePassword => 'Gizle';

  @override
  String get authHaveAccount => 'Zaten hesabın var mı?';

  @override
  String get authNoAccount => 'Hesabın yok mu?';

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
  String get authDisplayNameLabel => 'Adın';

  @override
  String get authDisplayNameHint => 'Sana nasıl seslenelim?';

  @override
  String get moodDoneToday => 'Bugünkü kaydın alındı';

  @override
  String get moodHowAreYou => 'Şu an sana en yakın olan hangisi?';

  @override
  String get moodPickHint => 'Birkaçını seçebilirsin. Doğru cevap yok.';

  @override
  String get moodWhereItLands => 'Nereye düşüyor';

  @override
  String get moodAxisHint =>
      'Seçtiklerin bu iki eksene çevriliyor — noktayı elle de oynatabilirsin.';

  @override
  String get moodOncePerDay =>
      'Günde bir kez kaydediliyor · sonraki 24 sa sonra';

  @override
  String get moodWordCalm => 'Sakin';

  @override
  String get moodWordHopeful => 'Umutlu';

  @override
  String get moodWordTired => 'Yorgun';

  @override
  String get moodWordTense => 'Gergin';

  @override
  String get moodWordUnsure => 'Kararsız';

  @override
  String get moodWordRelieved => 'Hafiflemiş';

  @override
  String get moodWordHeavy => 'Ağır';

  @override
  String get moodWordJoyful => 'Neşeli';

  @override
  String get moodWordAngry => 'Kızgın';

  @override
  String get moodWordEmpty => 'Boşlukta';

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
  String journalCharCount(int count) {
    return '$count karakter';
  }

  @override
  String get journalHint => 'Yarım cümle de olur...';

  @override
  String get journalPrompt => 'Bugün aklından ne geçti?';

  @override
  String get journalPromptNote => 'Kimse okumuyor. Yarım cümle de olur.';

  @override
  String get journalDraftSaved => 'Taslak kaydedildi';

  @override
  String get journalPast => 'Önceki günler';

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
  String get chatToday => 'bugün';

  @override
  String get chatCrisisTitle => 'Bunu yalnız taşımak zorunda değilsin';

  @override
  String get chatCallEmergency => '112\'yi ara';

  @override
  String get chatContinue => 'Devam et';

  @override
  String get lifeTitle => 'Yaşam Analizi';

  @override
  String get lifeCooldownTooltip => 'Haftada bir yenilenebilir';

  @override
  String lifeNextOn(String date) {
    return 'sonraki $date';
  }

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

  @override
  String get storiesEntryTitle => 'Topluluk Hikayeleri';

  @override
  String get storiesEntryBody =>
      'Aynı şeyi yaşayanların deneyimlerini oku ya da kendi hikayeni paylaş.';

  @override
  String get storiesTitle => 'Hikayeler';

  @override
  String get storiesSearchHint => 'Tanı veya kategori ara';

  @override
  String get storiesAnonymous => 'isimsiz';

  @override
  String get storiesTabFeed => 'Hikayeler';

  @override
  String get storiesTabMine => 'Hikayem';

  @override
  String get storiesWriteCta => 'Hikayeni paylaş';

  @override
  String get storiesFeedEmpty => 'Henüz paylaşılan hikaye yok';

  @override
  String get storiesFeedEmptyBody => 'Onaylanan hikayeler burada listelenecek.';

  @override
  String get storiesMineEmpty => 'Henüz bir hikaye yazmadın';

  @override
  String get storiesMineEmptyBody =>
      'Yaşadıklarını, neyin işine yaradığını ya da yaramadığını başkalarıyla paylaşabilirsin. Gönderdiğin hikaye yayınlanmadan önce incelenir.';

  @override
  String get storiesStatusPending => 'İnceleniyor';

  @override
  String get storiesStatusApproved => 'Yayında';

  @override
  String get storiesStatusRejected => 'Yayınlanmadı';

  @override
  String get storiesWithdrawTitle => 'Hikayeni kaldır';

  @override
  String get storiesWithdrawBody =>
      'Bu hikaye kalıcı olarak silinecek. Emin misin?';

  @override
  String get storiesWithdraw => 'Kaldır';

  @override
  String get storiesReportTitle => 'Bu hikayeyi bildir';

  @override
  String get storiesReportNoteHint => 'İsteğe bağlı not';

  @override
  String get storiesReport => 'Bildir';

  @override
  String get storiesReportSent => 'Bildirimin alındı, teşekkürler.';

  @override
  String get storiesSubmitTitle => 'Hikayeni Yaz';

  @override
  String get storiesSubmitHint =>
      'Neler yaşadın, neyin işine yaradı, neyin yaramadı? Kendi cümlelerinle anlat...';

  @override
  String get storiesPickDiagnosis => 'Hangi tanı hakkında?';

  @override
  String storiesCharCount(int count) {
    return '$count karakter · en az 8 satır önerilir';
  }

  @override
  String get storiesDisclaimer =>
      'Bu bir tıbbi tavsiye değildir. İlaç ve tedavi kararlarını mutlaka bir hekimle birlikte al. Burada paylaştığın kendi kişisel deneyimindir — başka birinin durumu farklı olabilir.';

  @override
  String get storiesConsentLabel =>
      'Bu hikayenin, onaylandıktan sonra diğer kullanıcılarla (kimliğim gösterilmeden) paylaşılacağını biliyorum.';

  @override
  String get storiesModerationNotice =>
      'Hikayen yayınlanmadan önce incelenir. İstediğin zaman geri çekebilirsin.';

  @override
  String get storiesSubmit => 'Gönder';

  @override
  String get storiesSubmitSuccess => 'Hikayen incelemeye gönderildi.';

  @override
  String get storiesModerationTitle => 'Hikaye Moderasyonu';

  @override
  String storiesModerationQueueTab(int count) {
    return '$count bekleyen';
  }

  @override
  String storiesModerationReportsTab(int count) {
    return '$count bildirilen';
  }

  @override
  String get storiesModerationEmpty => 'Bekleyen hikaye yok';

  @override
  String get storiesModerationNoReports => 'Bildirilen hikaye yok';

  @override
  String get storiesModerationApprove => 'Onayla';

  @override
  String get storiesModerationReject => 'Reddet';

  @override
  String get storiesModerationKeep => 'Yayında tut';

  @override
  String get storiesModerationCrisisFlag => 'Kriz dili';

  @override
  String get storiesModerationReporterNote => 'Bildiren notu:';

  @override
  String get settingsAssessment => 'Öz-değerlendirme';

  @override
  String get settingsMyStories => 'Hikayelerim';

  @override
  String get assessmentOnboardTitle => 'Seni biraz tanıyalım';

  @override
  String get assessmentOnboardIntro =>
      'Son iki haftaya dair 16 kısa soru. Sana nasıl yaklaşacağımızı bu belirler; istersen şimdi atlayıp sonra Ayarlar\'dan yapabilirsin.';

  @override
  String get assessmentStart => 'Başla';

  @override
  String get assessmentSkip => 'Şimdi değil';

  @override
  String assessmentProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get assessmentSectionMood => 'Son iki hafta — ruh halin';

  @override
  String get assessmentSectionAnxiety => 'Son iki hafta — kaygın';

  @override
  String get assessmentAnswer0 => 'Hiçbir zaman';

  @override
  String get assessmentAnswer1 => 'Bazı günler';

  @override
  String get assessmentAnswer2 => 'Günlerin yarıdan fazlasında';

  @override
  String get assessmentAnswer3 => 'Hemen hemen her gün';

  @override
  String get assessmentResultTitle => 'Teşekkürler';

  @override
  String get assessmentResultNote =>
      'Bu bir tanı değil, sana nasıl yaklaşacağımızı ayarlamamıza yardımcı olan bir tarama sinyali.';

  @override
  String get assessmentResultDepression => 'Ruh hali taraması';

  @override
  String get assessmentResultAnxiety => 'Kaygı taraması';

  @override
  String get assessmentBandMinimal => 'Minimal';

  @override
  String get assessmentBandMild => 'Hafif';

  @override
  String get assessmentBandModerate => 'Orta';

  @override
  String get assessmentBandModeratelySevere => 'Orta-ağır';

  @override
  String get assessmentBandSevere => 'Ağır';

  @override
  String get assessmentContinueCta => 'Devam et';

  @override
  String get assessmentSubmitError => 'Gönderilemedi, tekrar dener misin?';

  @override
  String get assessmentRetakeTitle => 'Öz-değerlendirme';

  @override
  String get assessmentRetakeIntro =>
      'PHQ-9 ve GAD-7 — son iki haftana dair 16 kısa soru. Sonuçlar, sohbet ve önerilerinin arka planında kullanılır.';

  @override
  String get assessmentRetakeCta => 'Değerlendirmeyi başlat';

  @override
  String get assessmentRetakeAgain => 'Yeniden değerlendir';

  @override
  String get assessmentLastTakenToday => 'Bugün yapıldı';

  @override
  String assessmentLastTaken(int days) {
    return '$days gün önce yapıldı';
  }

  @override
  String get assessmentNeverTaken => 'Henüz yapılmadı';

  @override
  String get phq9Q1 =>
      'Yaptığınız işlere karşı ilgi azlığı ya da yaptığınız işlerden zevk almama';

  @override
  String get phq9Q2 => 'Kendini çökkün, depresif ya da ümitsiz hissetme';

  @override
  String get phq9Q3 =>
      'Uykuya dalmakta güçlük çekme, uykuyu sürdürmekte güçlük çekme ya da fazla uyuma';

  @override
  String get phq9Q4 => 'Kendini yorgun hissetme ya da enerjinin az olması';

  @override
  String get phq9Q5 => 'İştah azlığı ya da aşırı yeme';

  @override
  String get phq9Q6 =>
      'Kendini kötü hissetme; kendini ya da ailesini hayal kırıklığına uğrattığını düşünme';

  @override
  String get phq9Q7 =>
      'Gazete okumak ya da televizyon izlemek gibi işlere yoğunlaşmakta güçlük çekme';

  @override
  String get phq9Q8 =>
      'Başkalarının fark edebileceği kadar yavaş hareket etme ya da konuşma; ya da tam tersi, her zamankinden daha hareketli ve huzursuz olma';

  @override
  String get phq9Q9 =>
      'Ölü olsan daha iyi olur diye düşünme ya da bir şekilde kendine zarar verme';

  @override
  String get gad7Q1 => 'Sinirli, kaygılı ya da gergin hissetme';

  @override
  String get gad7Q2 => 'Endişelerini kontrol edememe ya da durduramama';

  @override
  String get gad7Q3 => 'Farklı konularda çok fazla endişelenme';

  @override
  String get gad7Q4 => 'Gevşeyip rahatlayamama';

  @override
  String get gad7Q5 => 'Yerinde duramayacak kadar huzursuz olma';

  @override
  String get gad7Q6 => 'Çabuk sinirlenme ya da huysuzlaşma';

  @override
  String get gad7Q7 => 'Kötü bir şey olacakmış gibi korku hissetme';

  @override
  String get storiesAnonymousToggle => 'Anonim paylaş';

  @override
  String get storiesAnonymousOnBody => 'Adın ve fotoğrafın görünmeyecek.';

  @override
  String get storiesAnonymousOffBody => 'Adın ve fotoğrafınla paylaşılacak.';

  @override
  String get profileStatStories => 'Hikaye';

  @override
  String get profileStatFollowers => 'Takipçi';

  @override
  String get profileStatFollowing => 'Takip';

  @override
  String get profileFollow => 'Takip et';

  @override
  String get profileUnfollow => 'Takibi bırak';

  @override
  String get profileNobodyYet => 'Henüz kimse yok';

  @override
  String get settingsDmPrivacy => 'Mesaj gizliliği';

  @override
  String get settingsDmEveryone => 'Herkesten mesaj kabul et';

  @override
  String get settingsDmFollowing => 'Sadece takip ettiklerimden kabul et';

  @override
  String get settingsDmNoReceipts => 'Mesajlarda okundu bilgisi yoktur.';

  @override
  String get dmTitle => 'Mesajlar';

  @override
  String get dmTabInbox => 'Sohbetler';

  @override
  String get dmTabRequests => 'İstekler';

  @override
  String get dmNoThreads => 'Henüz sohbet yok';

  @override
  String get dmNoRequests => 'Bekleyen istek yok';

  @override
  String get dmMessage => 'Mesaj gönder';

  @override
  String get dmFollowersOnly => 'Sadece takip ettiklerinden mesaj alıyor';

  @override
  String dmRequestTitle(String name) {
    return '$name kişisine yaz';
  }

  @override
  String get dmRequestBody =>
      'İlk mesajın istek olarak gider. Kabul edilene kadar ikinci bir mesaj gönderemezsin.';

  @override
  String get dmRequestHint => 'Bir şeyler yaz...';

  @override
  String get dmRequestSent => 'İsteğin gönderildi.';

  @override
  String get dmSend => 'Gönder';

  @override
  String get dmSendFailed => 'Mesaj gönderilemedi.';

  @override
  String get dmComposerHint => 'Bir şey yaz...';

  @override
  String get dmAccept => 'Kabul et';

  @override
  String get dmDecline => 'Reddet';

  @override
  String get dmAcceptPrompt =>
      'Bu kişi seninle konuşmak istiyor. Cevap verirsen istek otomatik kabul edilir.';

  @override
  String get dmWaiting => 'Bekliyor';

  @override
  String get dmNewRequest => 'Yeni istek';

  @override
  String get dmWaitingBody =>
      'İsteğin gönderildi. Kabul edilince yazabilirsin.';

  @override
  String get dmLeave => 'Sohbetten çık';
}
