// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Hearth';

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
  String get errorNoConnection =>
      'İnternet bağlantını kontrol et ve tekrar dene.';

  @override
  String get errorServer =>
      'Sunucuya şu an ulaşılamıyor. Birazdan tekrar dene.';

  @override
  String get errorTimeout =>
      'Bağlantı zaman aşımına uğradı. Tekrar dener misin?';

  @override
  String get authErrorWrongCredentials => 'E-posta veya şifre hatalı.';

  @override
  String get authErrorEmailTaken => 'Bu e-posta ile zaten bir hesap var.';

  @override
  String get authErrorCheckDetails => 'Bilgileri kontrol et.';

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
  String get navMessages => 'Mesajlar';

  @override
  String get navGuide => 'Rehber';

  @override
  String get navLife => 'Yaşam';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get navProfile => 'Profilim';

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
      'Hearth lisanslı bir sağlık uzmanının yerini tutmaz. Acil bir durumdaysan 112\'yi ara.';

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
  String get settingsProfile => 'Profili Düzenle';

  @override
  String get settingsPrivacyRow => 'Gizlilik';

  @override
  String get settingsLogout => 'Çıkış yap';

  @override
  String get profileTitle => 'Profili Düzenle';

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
      'Hearth lisanslı bir psikolog, psikiyatrist ya da tıbbi bir cihaz değildir; tanı koymaz. Kriz anında lütfen 112\'yi veya bir uzmanı ara.';

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
  String get timeUnitHour => 'sa';

  @override
  String get timeUnitMinute => 'dk';

  @override
  String get timeUnitSecond => 'sn';

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
  String get storiesTranslated => 'Çevrildi';

  @override
  String get storiesShowOriginal => 'Orijinalini gör';

  @override
  String get storiesShowTranslation => 'Çeviriyi gör';

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
  String get storiesEditTitle => 'Hikayeni Düzenle';

  @override
  String get storiesSaveChanges => 'Kaydet';

  @override
  String get storiesEditSuccess =>
      'Hikayen güncellendi ve yeniden incelemeye gönderildi.';

  @override
  String get storiesEditNotice =>
      'Kaydettiğinde bu hikaye yeniden incelemeye gönderilir; onaylanana kadar akışta görünmez.';

  @override
  String get storiesEdit => 'Düzenle';

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
  String get settingsChatBoundaries => 'Sohbet tercihlerim';

  @override
  String get settingsChatBoundariesBody =>
      'Sohbetlerde neyi istemediğini belirle';

  @override
  String get onboardingSkipTour => 'Tanıtımı atla';

  @override
  String get onboardingSkipStep => 'Bu adımı atla';

  @override
  String get introGreeting =>
      'Merhaba, ben Hearth. Her şeyden önce sana tek bir şey sormak istiyorum.';

  @override
  String get introQuestion =>
      'Bu sohbetlerde sana nasıl davranmamı istersin — ve neyi kesinlikle yapmamamı istersin? Kendi cümlelerinle yaz. Bundan sonra söyleyeceğim her şey, şimdi bana anlattığına göre şekillenecek.';

  @override
  String get introExamples =>
      'Örneğin: \"Bana akıl verme, sadece dinle.\" · \"Kısa yaz.\" · \"Terapiste git deme.\" · \"Bana karşı dürüst ol, yumuşatma.\"';

  @override
  String get introInputHint => 'Kendi cümlelerinle yaz…';

  @override
  String get introContinue => 'Devam et';

  @override
  String get introChangeLater =>
      'Kaydedildi. İstediğin zaman Ayarlar > Sohbet tercihlerim\'den değiştirebilirsin.';

  @override
  String get tourNext => 'Devam';

  @override
  String get tourStart => 'Hadi başlayalım';

  @override
  String get tourWelcomeTitle => 'Hearth\'e hoş geldin';

  @override
  String get tourWelcomeBody =>
      'Hearth, ruh haline zamanla eşlik eden bir alan. Ne kadar çok şey paylaşırsan, sana o kadar özel cevaplar verir. Terapistin yerini tutmaz — ama arada geçen günlerde yanında olur.\n\nBunlar geride kaldığına göre, şimdi burada neler var göstereyim — birkaç adım, istediğin an atlayabilirsin.';

  @override
  String get tourChatTitle => 'İstediğin saatte konuş';

  @override
  String get tourChatBody =>
      'Sohbet, gecenin üçünde de açık. Konuştuklarını hatırlar, ruh hali kayıtlarını ve günlüklerini bilir — yani her seferinde baştan anlatmak zorunda değilsin.\n\nBiraz önce sana nasıl davranılmasını istediğini söylemiştin; burada şimdiden geçerli, istediğin an da değiştirebilirsin.';

  @override
  String get tourMoodJournalTitle => 'Ruh hali ve günlük';

  @override
  String get tourMoodJournalBody =>
      'Günde bir kez nasıl hissettiğini birkaç kelimeyle işaretle, istersen gününü günlüğe yaz. İkisi de bir dakikadan kısa sürer.\n\nBunlar sadece kayıt değil: haftalar içinde nelerin seni iyi ya da kötü hissettirdiği buradan çıkıyor.';

  @override
  String get tourReportTitle => 'Bugünün notu';

  @override
  String get tourReportBody =>
      'Ana ekranda her gün, o güne dair kısa bir özet ve birkaç küçük öneri bulursun — ruh halinden, günlüğünden ve konuştuklarından derlenir.\n\nHaftalık özet ve yaşam analizi ise daha geniş resmi gösterir: neyin tekrar ettiğini, neyin değiştiğini.';

  @override
  String get tourCommunityTitle => 'Yalnız değilsin';

  @override
  String get tourCommunityBody =>
      'Hikayeler\'de başkalarının kendi deneyimlerini okuyabilir, istersen kendi hikayeni (istersen isimsiz) paylaşabilirsin. Her hikaye yayınlanmadan önce incelenir.\n\nRehber\'de ise tanılar hakkında araştırmaya dayalı, sade anlatımlar var.';

  @override
  String get tourPrivacyTitle => 'Verilerin ve güvenliğin';

  @override
  String get tourPrivacyBody =>
      'Yazdıkların hesabına özeldir; hikaye olarak paylaşmadıkça kimse göremez. Hesabını ve tüm verilerini istediğin an tek adımda silebilirsin.\n\nCiddi bir risk söz konusu olduğunda uygulama bunu görmezden gelmez — acil durumda 112\'yi aramanı hatırlatır. Hearth tıbbi tavsiye vermez, teşhis koymaz.';

  @override
  String get boundariesTitle => 'Sohbetlerde neyi istemezsin?';

  @override
  String get boundariesIntro =>
      'Herkesin duymak istemediği bir şey vardır. Sana uyanları işaretle — uymamaya başladığında da istediğin gibi değiştir.';

  @override
  String get boundariesEffectNote =>
      'Seçtiklerin doğrudan sohbete işler: Hearth bundan sonra bu sınırların içinde konuşur. Tek istisna, hayati bir risk söz konusu olduğunda güvenliğini önceliklendirmesidir.';

  @override
  String get boundariesNoteLabel => 'Eklemek istediğin bir şey var mı?';

  @override
  String get boundariesNoteHint =>
      'Örn. bana acıyan bir dille yaklaşılmasını istemiyorum';

  @override
  String get boundariesChangeLater =>
      'Bunları istediğin zaman Ayarlar > Sohbet tercihlerim\'den değiştirebilirsin.';

  @override
  String get boundaryNoAdvice => 'Bana tavsiye verilmesin';

  @override
  String get boundaryNoAdviceBody =>
      'İstemediğim sürece öneri, teknik ya da \"şunu dene\" yok. Sadece dinlensin.';

  @override
  String get boundaryNoReferrals => '\"Bir uzmana görün\" denmesin';

  @override
  String get boundaryNoReferralsBody =>
      'Bu seçeneği zaten biliyorum; her konuşmada hatırlatılmasını istemiyorum.';

  @override
  String get boundaryNoToxicPositivity => 'Aşırı pozitif konuşulmasın';

  @override
  String get boundaryNoToxicPositivityBody =>
      '\"Her şey güzel olacak\" tarzı motivasyon cümleleri yerine olduğu gibi konuşulsun.';

  @override
  String get boundaryNoQuestions => 'Bana çok soru sorulmasın';

  @override
  String get boundaryNoQuestionsBody =>
      'Sorgu gibi hissettirmesin; peş peşe sorular yerine sade cevaplar olsun.';

  @override
  String get boundaryNoClinicalTerms => 'Klinik terimler kullanılmasın';

  @override
  String get boundaryNoClinicalTermsBody =>
      'Tanı isimleri ve terapi jargonu yerine günlük dille konuşulsun.';

  @override
  String get boundaryNoReligious => 'Dini/manevi çerçeve olmasın';

  @override
  String get boundaryNoReligiousBody =>
      'İnanç temelli teselli ya da benzetmeler kullanılmasın.';

  @override
  String get boundaryNoToughLove => 'Sert/yüzleştirici bir ton olmasın';

  @override
  String get boundaryNoToughLoveBody =>
      '\"Kendine gel\" tarzı zorlayıcı bir yaklaşım istemiyorum.';

  @override
  String get boundaryNoHistoryCallbacks => 'Geçmiş kayıtlarım hatırlatılmasın';

  @override
  String get boundaryNoHistoryCallbacksBody =>
      'Eski günlüklerim ve kayıtlarım ben açmadıkça konuşmaya getirilmesin.';

  @override
  String get introGotIt => 'Anladım';

  @override
  String get introMoodTitle => 'Ruh hali kaydı nedir?';

  @override
  String get introMoodBody =>
      'Günde bir kez, o an nasıl hissettiğini birkaç kelimeyle işaretliyorsun. Altındaki iki çubuğu elinle de oynatabilirsin.\n\nBu kayıtlar, bugünün notunu ve haftalık özetini oluşturan ana veri — birkaç gün üst üste girdiğinde örüntüler görünmeye başlar.';

  @override
  String get introJournalTitle => 'Günlük nasıl işler?';

  @override
  String get introJournalBody =>
      'Günde bir giriş yazabilirsin: aklından geçenler, o gün yaşadıkların, kimseye söylemediklerin. Yazdıkların yalnızca sana ait; paylaşılmaz.\n\nYarım kalan yazın taslak olarak saklanır, istersen sonra devam edersin. Geçmiş girişlerin aşağıdaki arşivde durur.';

  @override
  String get introChatTitle => 'Sohbet hakkında';

  @override
  String get introChatBody =>
      'Buraya istediğini yazabilirsin — dertleşmek, bir şeyi anlamaya çalışmak ya da sadece günü anlatmak için.\n\nHearth ruh hali kayıtlarını, günlüklerini ve sohbet tercihlerini bilerek cevap verir. Tıbbi tavsiye vermez; acil bir durumda 112\'yi hatırlatır.';

  @override
  String get milestoneContinue => 'Devam et';

  @override
  String get milestoneFirstMoodTitle => 'İlk ruh hali kaydın alındı';

  @override
  String get milestoneFirstMoodBody =>
      'Güzel bir başlangıç. Birkaç gün daha işaretlersen, ana ekranındaki not ve grafikler senin örüntülerini göstermeye başlayacak.';

  @override
  String get milestoneFirstJournalTitle => 'İlk günlük girişin hazır';

  @override
  String get milestoneFirstJournalBody =>
      'Yazdıkların yalnızca sana ait. Yarın yeni bir giriş yazabilirsin; eskiler arşivinde seni bekliyor.';

  @override
  String get milestoneFirstChatTitle => 'İlk sohbetin başladı';

  @override
  String get milestoneFirstChatBody =>
      'Konuştuklarınız hatırlanır, yani bir dahaki sefere baştan anlatmana gerek yok. Nasıl konuşulmasını istediğini Ayarlar\'dan her zaman değiştirebilirsin.';

  @override
  String get assessmentOnboardTitle => 'Seni biraz tanıyalım';

  @override
  String assessmentOnboardIntro(int total) {
    return 'Uygulamayı tamamlaman gereken, son iki haftana dair birkaç kısa test var — toplam $total soru: ruh halin, kaygın, genel iyi oluşun ve daha fazlası. Sana nasıl yaklaşacağımızı bu belirler; istersen şimdi atlayıp sonra Ayarlar\'dan yapabilirsin.';
  }

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
  String get assessmentSectionWellbeing => 'Son iki hafta — genel iyi oluşun';

  @override
  String get assessmentSectionSomatic =>
      'Son dört hafta — bedensel belirtilerin';

  @override
  String get assessmentSectionPtsd => 'Travmatik bir olay';

  @override
  String get assessmentSectionAlcohol => 'Son bir yıl — alkol kullanımın';

  @override
  String get assessmentSectionSubstance => 'Son bir yıl — madde kullanımın';

  @override
  String get assessmentPtsd5Intro =>
      'Bazen insanlar çok stresli olaylar yaşar — ciddi bir kaza, doğal afet, fiziksel ya da cinsel saldırı, savaş, ciddi şekilde dövülme ya da birinin ölümüne tanık olma gibi. Böyle bir şey yaşadıysan, geçen ay içinde şunları yaşadın mı?';

  @override
  String get assessmentAnswer0 => 'Hiçbir zaman';

  @override
  String get assessmentAnswer1 => 'Bazı günler';

  @override
  String get assessmentAnswer2 => 'Günlerin yarıdan fazlasında';

  @override
  String get assessmentAnswer3 => 'Hemen hemen her gün';

  @override
  String get assessmentAnswerNo => 'Hayır';

  @override
  String get assessmentAnswerYes => 'Evet';

  @override
  String get who5Answer0 => 'Hiçbir zaman';

  @override
  String get who5Answer1 => 'Ara sıra';

  @override
  String get who5Answer2 => 'Yarıdan az bir sürede';

  @override
  String get who5Answer3 => 'Yarıdan fazla bir sürede';

  @override
  String get who5Answer4 => 'Çoğu zaman';

  @override
  String get who5Answer5 => 'Her zaman';

  @override
  String get phq15Answer0 => 'Hiç rahatsız etmedi';

  @override
  String get phq15Answer1 => 'Biraz rahatsız etti';

  @override
  String get phq15Answer2 => 'Çok rahatsız etti';

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
  String get assessmentResultWellbeing => 'İyi oluş taraması';

  @override
  String get assessmentResultSomatic => 'Bedensel belirti taraması';

  @override
  String get assessmentResultPtsd => 'Travma sonrası stres taraması';

  @override
  String get assessmentResultAlcohol => 'Alkol kullanım taraması';

  @override
  String get assessmentResultSubstance => 'Madde kullanım taraması';

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
  String get assessmentBandVeryLow => 'Çok düşük';

  @override
  String get assessmentBandLow => 'Düşük';

  @override
  String get assessmentBandMedium => 'Orta';

  @override
  String get assessmentBandHigh => 'Yüksek';

  @override
  String get assessmentBandGood => 'İyi';

  @override
  String get assessmentBandCaution => 'Dikkat';

  @override
  String get assessmentBandBelowThreshold => 'Eşiğin altında';

  @override
  String get assessmentBandPositiveScreen => 'Daha yakından bakmaya değer';

  @override
  String get assessmentContinueCta => 'Devam et';

  @override
  String get assessmentSubmitError => 'Gönderilemedi, tekrar dener misin?';

  @override
  String get assessmentRetakeTitle => 'Öz-değerlendirme';

  @override
  String assessmentRetakeIntro(int total) {
    return 'Uygulamayı tamamlaman gereken testler var: yedi kısa test, toplam $total soru — ruh halin, kaygın, genel iyi oluşun ve daha fazlası hakkında. Sonuçlar, sohbet ve önerilerinin arka planında kullanılır.';
  }

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
  String get who5Q1 => 'Kendimi neşeli ve keyifli hissettim.';

  @override
  String get who5Q2 => 'Kendimi sakin ve huzurlu hissettim.';

  @override
  String get who5Q3 => 'Kendimi enerjik ve aktif hissettim.';

  @override
  String get who5Q4 => 'Uyandığımda kendimi dinlenmiş ve zinde hissettim.';

  @override
  String get who5Q5 => 'Günlük hayatım ilgimi çeken şeylerle doluydu.';

  @override
  String get phq15Q1 => 'Mide ağrısı';

  @override
  String get phq15Q2 => 'Sırt ağrısı';

  @override
  String get phq15Q3 => 'Kollarda, bacaklarda veya eklemlerde ağrı';

  @override
  String get phq15Q4 =>
      'Adet dönemiyle ilgili kramplar veya diğer sorunlar (kadınsan)';

  @override
  String get phq15Q5 => 'Baş ağrısı';

  @override
  String get phq15Q6 => 'Göğüs ağrısı';

  @override
  String get phq15Q7 => 'Baş dönmesi';

  @override
  String get phq15Q8 => 'Bayılma nöbetleri';

  @override
  String get phq15Q9 => 'Kalbinin çarpması veya hızlı atması';

  @override
  String get phq15Q10 => 'Nefes darlığı';

  @override
  String get phq15Q11 => 'Cinsel ilişki sırasında ağrı veya başka sorunlar';

  @override
  String get phq15Q12 => 'Kabızlık, gevşek bağırsak veya ishal';

  @override
  String get phq15Q13 => 'Mide bulantısı, gaz veya hazımsızlık';

  @override
  String get phq15Q14 => 'Kendini yorgun hissetme veya enerjisiz olma';

  @override
  String get phq15Q15 => 'Uyku sorunları';

  @override
  String get ptsd5Q1 =>
      'O olayla ilgili kabuslar gördün ya da istemeden aklına geldi mi?';

  @override
  String get ptsd5Q2 =>
      'Olayı düşünmemek için çok çaba gösterdin ya da seni ona dair hatırlatan durumlardan kaçındın mı?';

  @override
  String get ptsd5Q3 =>
      'Sürekli tetikte, dikkatli ya da kolayca irkilir durumda mıydın?';

  @override
  String get ptsd5Q4 =>
      'Kendini uyuşmuş ya da çevrenden, uğraşlarından ya da insanlardan kopmuş hissettin mi?';

  @override
  String get ptsd5Q5 =>
      'Olayla ilgili suçluluk hissettin ya da kendini ya da başkasını suçladın mı?';

  @override
  String get auditcQ1 => 'Ne sıklıkla alkollü içecek içtin?';

  @override
  String get auditcQ1Opt0 => 'Hiç';

  @override
  String get auditcQ1Opt1 => 'Ayda bir veya daha az';

  @override
  String get auditcQ1Opt2 => 'Ayda 2-4 kez';

  @override
  String get auditcQ1Opt3 => 'Haftada 2-3 kez';

  @override
  String get auditcQ1Opt4 => 'Haftada 4 veya daha fazla';

  @override
  String get auditcQ2 => 'Alkol içtiğin tipik bir günde kaç kadeh içtin?';

  @override
  String get auditcQ2Opt0 => '1 veya 2';

  @override
  String get auditcQ2Opt1 => '3 veya 4';

  @override
  String get auditcQ2Opt2 => '5 veya 6';

  @override
  String get auditcQ2Opt3 => '7 ile 9 arası';

  @override
  String get auditcQ2Opt4 => '10 veya daha fazla';

  @override
  String get auditcQ3 =>
      'Ne sıklıkla tek seferde 6 veya daha fazla kadeh içtin?';

  @override
  String get auditcQ3Opt0 => 'Hiçbir zaman';

  @override
  String get auditcQ3Opt1 => 'Ayda birden az';

  @override
  String get auditcQ3Opt2 => 'Ayda bir kez';

  @override
  String get auditcQ3Opt3 => 'Haftada bir kez';

  @override
  String get auditcQ3Opt4 => 'Her gün ya da hemen her gün';

  @override
  String get cageaidQ1 =>
      'Alkol ya da madde kullanımını azaltman gerektiğini hiç hissettin mi?';

  @override
  String get cageaidQ2 =>
      'İnsanlar alkol ya da madde kullanımını eleştirdiğinde rahatsız oldun mu?';

  @override
  String get cageaidQ3 =>
      'Alkol ya da madde kullanımın yüzünden kendini suçlu hissettin mi?';

  @override
  String get cageaidQ4 =>
      'Sinirlerini yatıştırmak ya da kendini daha iyi hissetmek için sabah ilk iş olarak alkol ya da madde kullandığın oldu mu?';

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
  String get myProfileEdit => 'Profili Düzenle';

  @override
  String get myProfileStories => 'Hikayelerim';

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

  @override
  String get recapEntryTitle => 'Haftalık Özetin';

  @override
  String get recapEntrySubtitle => 'Bu haftanı gör ve paylaş';

  @override
  String get recapTitle => 'Haftalık Özet';

  @override
  String get recapCheckins => 'Ruh hali girişi';

  @override
  String get recapJournalEntries => 'Günlük yazısı';

  @override
  String get recapActiveDays => 'Aktif gün';

  @override
  String get recapMoodVeryPositive => 'Bu hafta oldukça keyifliydin.';

  @override
  String get recapMoodPositive => 'Bu hafta genelde iyiydin.';

  @override
  String get recapMoodNeutral => 'Bu hafta dengeliydin.';

  @override
  String get recapMoodMixed => 'Bu hafta inişli çıkışlıydı.';

  @override
  String get recapMoodHard => 'Bu hafta zorlu geçti. Kendine nazik davran.';

  @override
  String get recapMoodEmpty => 'Bu hafta henüz check-in yapmadın.';

  @override
  String get recapShare => 'Paylaş';

  @override
  String recapShareText(int checkins, int streak) {
    return 'Hearth\'te bu hafta $checkins ruh hali girişi yaptım, $streak günlük serim var.';
  }

  @override
  String get lifeMoodHistoryTitle => 'Ruh Hali Geçmişin';

  @override
  String get lifeMoodHistoryEmpty => 'Henüz check-in yok';

  @override
  String get lifeMoodHistoryLegendLow => 'Zorlu';

  @override
  String get lifeMoodHistoryLegendHigh => 'Keyifli';

  @override
  String get settingsDeleteAccount => 'Hesabı Sil';

  @override
  String get deleteAccountTitle => 'Hesabını silmek istediğine emin misin?';

  @override
  String get deleteAccountBody =>
      'Bu işlem geri alınamaz. Ruh hali kayıtların, günlüklerin, hikayelerin, mesajların ve hesabınla ilgili her şey kalıcı olarak silinir.';

  @override
  String get deleteAccountPasswordHint => 'Onaylamak için şifreni gir';

  @override
  String get deleteAccountConfirm => 'Kalıcı Olarak Sil';

  @override
  String get deleteAccountWrongPassword => 'Şifre yanlış.';

  @override
  String get deleteAccountDone => 'Hesabın silindi.';

  @override
  String get storiesReactionDestek => 'Yalnız değilsin';

  @override
  String get storiesReactionGuclusun => 'Güçlüsün';

  @override
  String get storiesReactionAnliyorum => 'Anlıyorum';

  @override
  String get storiesHighlightsTitle => 'Öne Çıkanlar';

  @override
  String get settingsPremiumRow => 'Hearth Plus';

  @override
  String get premiumTitle => 'Hearth Plus';

  @override
  String get premiumPitch =>
      'Hearth\'i daha derinlemesine kullanmak isteyenler için.';

  @override
  String get premiumFeatureChat => 'Sınırsız AI sohbet';

  @override
  String get premiumFeatureAnalysis => 'Daha sık yaşam analizi';

  @override
  String get premiumFeatureInsights => 'Gelişmiş, kişiselleştirilmiş içgörüler';

  @override
  String premiumPricePerMonth(String price) {
    return '$price / ay';
  }

  @override
  String get premiumSubscribe => 'Abone Ol';

  @override
  String get premiumRestore => 'Satın Almaları Geri Yükle';

  @override
  String premiumActiveUntil(String date) {
    return 'Aboneliğin $date tarihine kadar aktif.';
  }

  @override
  String get premiumAlreadyActive => 'Hearth Plus zaten aktif';

  @override
  String get premiumTerms =>
      'Abonelik otomatik olarak yenilenir; mevcut dönem bitmeden en az 24 saat önce iptal etmezsen ücret otomatik tahsil edilir. Aboneliği istediğin zaman App Store > Ayarlar üzerinden iptal edebilirsin.';

  @override
  String get premiumUnavailable => 'Satın alma şu anda kullanılamıyor.';

  @override
  String get premiumRestored => 'Satın almaların geri yüklendi.';

  @override
  String get premiumPrivacyPolicy => 'Gizlilik Politikası';

  @override
  String get premiumTermsOfUse => 'Kullanım Koşulları';

  @override
  String get chatQuotaExceeded =>
      'Bugünkü ücretsiz sohbet hakkın doldu. Hearth Plus ile sınırsız sohbet edebilirsin.';

  @override
  String get voiceDictate => 'Sesle yaz';

  @override
  String get voiceListening => 'Dinliyorum…';

  @override
  String get voiceUnavailable => 'Bu cihazda sesle yazma şu an kullanılamıyor.';

  @override
  String get voicePermissionDenied =>
      'Sesle yazmak için mikrofon izni gerekiyor. Telefonunun ayarlarından Hearth\'e izin verebilirsin.';

  @override
  String get voiceSpeak => 'Sesli oku';

  @override
  String get voiceStopSpeaking => 'Okumayı durdur';

  @override
  String get discoveriesTitle => 'Seni iyi hissettirenler';

  @override
  String get discoveriesSeeAll => 'Tümü';

  @override
  String get discoveriesKindLifts => 'İyi geliyor';

  @override
  String get discoveriesKindDrains => 'Yoruyor';

  @override
  String get discoveriesKindRhythm => 'Döngü';

  @override
  String get discoveriesError => 'Keşiflerin şu an yüklenemedi.';

  @override
  String get discoveriesEmptyTitle => 'Henüz belirgin bir şey yok';

  @override
  String get discoveriesEmptyBody =>
      'Kayıtlarında şimdilik tekrar eden net bir örüntü görünmüyor. Ruh haline birkaç kelime ya da kısa bir not ekledikçe burası dolacak.';

  @override
  String get discoveriesFootnote =>
      'Bu, yalnızca senin kayıtlarında görülen bir eğilim; kesin bir sonuç ya da tanı değil.';

  @override
  String get discoveriesLockedTitle => 'Keşiflerin yolda';

  @override
  String get discoveriesLockedBody =>
      'Seni neyin iyi hissettirdiğini görebilmem için birkaç gün daha ruh hali kaydı gerekiyor.';

  @override
  String discoveriesLockedProgress(int logged, int needed) {
    return '$logged/$needed gün';
  }

  @override
  String get notificationsTitle => 'Bildirimler';

  @override
  String get notificationsCheckinTitle => 'Akşam kontrolü';

  @override
  String get notificationsCheckinBody =>
      'O gün ruh halini kaydetmediysen, seçtiğin saatte tek bir nazik hatırlatma gelir. Kaydettiysen hiç rahatsız etmez.';

  @override
  String get notificationsTimeLabel => 'Saat';

  @override
  String get notificationsPreviewLabel => 'Bildirim böyle görünür';

  @override
  String get notificationsPreviewTitle => 'Bugün nasıldı?';

  @override
  String get notificationsPreviewBody =>
      'Yarım dakika yeter — bugün nasıl hissettiğin, yarınki notunu şekillendirir.';

  @override
  String get notificationsWebNote =>
      'Bildirimler şimdilik yalnızca telefon uygulamasında gelir; tercihin yine de kaydedilir.';

  @override
  String get settingsNotifications => 'Bildirimler';

  @override
  String settingsNotificationsOn(String time) {
    return 'Akşam kontrolü · $time';
  }

  @override
  String get settingsNotificationsOff => 'Akşam kontrolü kapalı';

  @override
  String get metooButton => 'Bende de oldu';

  @override
  String metooCount(int count) {
    return '$count kişi';
  }

  @override
  String metooWithYou(int count) {
    return 'Sen ve $count kişi daha';
  }

  @override
  String get metooYouSaidIt => 'Yazana iletildi';

  @override
  String get metooSheetTitle => 'Bu senin de hikayen mi?';

  @override
  String get metooSheetBody =>
      'Yazana kim olduğun asla gösterilmez. İstersen ona kısa bir not bırakabilirsin.';

  @override
  String get metooNoteNotAlone => 'Yalnız değilsin';

  @override
  String get metooNoteSameHere => 'Ben de benzerini yaşadım';

  @override
  String get metooNoteThanks => 'Paylaştığın için teşekkürler';

  @override
  String get metooNoteStrength => 'Sana güç yolluyorum';

  @override
  String get metooJustMark => 'Not bırakmadan işaretle';

  @override
  String get metooSent => 'Yazana iletildi. Kim olduğun gösterilmedi.';

  @override
  String metooOwnCount(int count) {
    return '$count kişi bu hikayede kendini buldu';
  }

  @override
  String get metooOwnPrivacy =>
      'Kim oldukları sana gösterilmez; yalnızca bıraktıkları notları görürsün.';

  @override
  String get sessionEntryTitle => 'Seans öncesi özetim';

  @override
  String get sessionEntryBody =>
      'Terapistine götürmek için son dönemini tek sayfada hazırla.';

  @override
  String get sessionTitle => 'Seans öncesi özet';

  @override
  String get sessionIntro =>
      'Terapistine ya da psikiyatristine götürebileceğin tek sayfalık bir özet: bu dönem nasıl geçti, neler tekrar etti, neler zorladı, neler iyi geldi. Yalnızca senin kendi kayıtlarından hazırlanır.';

  @override
  String get sessionPeriodLabel => 'Hangi dönemi özetleyelim?';

  @override
  String get sessionPeriodWeek => 'Son 1 hafta';

  @override
  String get sessionPeriodTwoWeeks => 'Son 2 hafta';

  @override
  String get sessionPeriodMonth => 'Son 1 ay';

  @override
  String get sessionNoteLabel =>
      'Bu seansta konuşmak istediğin bir şey var mı?';

  @override
  String get sessionNoteHint =>
      'İsteğe bağlı. Örn. uyku sorunlarım, işteki gerginlik';

  @override
  String get sessionGenerate => 'Özeti hazırla';

  @override
  String get sessionRegenerate => 'Yeniden hazırla';

  @override
  String get sessionGenerating => 'Kayıtların okunuyor…';

  @override
  String get sessionGeneratingBody =>
      'Ruh hali kayıtların, günlüklerin ve sohbetlerin bir araya getiriliyor. Bu yarım dakika kadar sürebilir.';

  @override
  String get sessionDocTitle => 'Seans öncesi özet';

  @override
  String sessionStats(int moodDays, int journals) {
    return '$moodDays gün ruh hali kaydı · $journals günlük';
  }

  @override
  String get sessionOverview => 'Genel tablo';

  @override
  String get sessionMoodCourse => 'Ruh hali seyri';

  @override
  String get sessionThemes => 'Öne çıkan konular';

  @override
  String get sessionHardMoments => 'Zorlayan anlar';

  @override
  String get sessionWhatHelped => 'İyi gelenler';

  @override
  String get sessionQuestions => 'Konuşmak istediklerim';

  @override
  String get sessionScreening => 'Son öz değerlendirme';

  @override
  String sessionScreeningAgo(int days) {
    return '$days gün önce';
  }

  @override
  String get sessionScreeningDepression => 'Depresyon (PHQ-9)';

  @override
  String get sessionScreeningAnxiety => 'Kaygı (GAD-7)';

  @override
  String get sessionScreeningWellbeing => 'İyi oluş (WHO-5)';

  @override
  String get sessionShare => 'PDF olarak paylaş';

  @override
  String get sessionNotEnough =>
      'Bu dönemde hiç ruh hali ya da günlük kaydın yok. Daha uzun bir dönem seç ya da birkaç gün kayıt girip tekrar dene.';

  @override
  String get sessionDisclaimer =>
      'Bu özet senin kendi kayıtlarından hazırlandı; tanı ya da tıbbi değerlendirme değildir.';

  @override
  String get sessionPdfFooter =>
      'Hearth · kişinin kendi kayıtlarından hazırlanmıştır, tanı değildir';
}
