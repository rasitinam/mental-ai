# Mimari

Mental AI iki ana bileşenden oluşan bir monorepo'dur: `backend/` (Rust) ve `app/` (Flutter). İkisi de bağımsız modüller halinde tasarlandı; her modülün tek bir sorumluluğu var ve birbirine somut implementasyon değil **trait/arayüz** üzerinden bağlanıyor (hexagonal / ports-and-adapters).

## Backend (`backend/`, Cargo workspace)

```
backend/
  crates/
    common/            # config yükleme, hata tipleri, tracing kurulumu
    domain/             # framework'ten bağımsız modeller + repository trait'leri (port'lar)
    storage/            # domain trait'lerinin SQLite/SQLx implementasyonu (adapter)
    llm-connector/       # LLM sağlayıcı soyutlaması + MCP-benzeri tool-calling + güvenlik prompt'ları
    knowledge-base/      # yerel RAG: embedding + vektör arama (SQLite üzerinde, ek servis gerektirmez)
    research-ingest/     # PubMed/WHO gibi kaynaklardan periyodik veri toplama ve knowledge-base'e besleme
    analysis-engine/     # günlük rapor / yaşam analizi / kriz taraması — RAG + LLM orkestrasyonu
  apps/
    server/              # axum HTTP API + zamanlanmış görevler (composition root / DI)
  migrations/            # SQLite şema migrasyonları (sqlx)
  config/                # default.toml (commit'li) + local.toml (git-ignored, opsiyonel override)
```

**Bağımlılık yönü tek yönlü**: `apps/server` her şeyi bilir; `analysis-engine`, `research-ingest`, `knowledge-base` sadece `domain` ve `llm-connector`'ı bilir; `domain` hiçbir şeyi bilmez. Bu sayede `analysis-engine` gibi iş mantığı ağırlıklı crate'ler gerçek bir veritabanı olmadan, sahte (fake) repository implementasyonlarıyla test edilebilir.

**"Kendi kendini geliştirme" burada ne anlama geliyor**: `research-ingest` crate'i arka planda — sunucu her başladığında **hemen bir kez**, sonra da düzenli olarak (varsayılan: 6 saatte bir) — PubMed'den birden fazla konu başlığında (genel ruh sağlığı, PTSD, bipolar bozukluk, anksiyete/depresyon, ve yayınlanmış nitel araştırmalardan "recovery narrative"/lived-experience çalışmaları) ve WHO'dan yeni özet/makale metadata'sı çeker, `knowledge-base`'e embed edip ekler (`apps/server/src/scheduler.rs::spawn_research_ingest_job`). Sunucu ilk açılışta bekletmeden bir döngü çalıştırdığı için içgörü akışı bir sonraki 6 saatlik periyodu beklemeden dolmaya başlar. Her yeni makale grubu geldiğinde `analysis-engine::synthesize_insights` bunlardan bir kısmını (döngü başına en fazla 5, maliyeti sınırlamak için) kullanıcıya gösterilecek kısa "içgörü kartlarına" dönüştürür ve `/insights` üzerinden sunulur — Flutter tarafında `features/insights` bu uç noktayı okuyup listeler. Uygulamanın kendi kaynak kodunu hiçbir şey otomatik değiştirmez — büyüyen şey, sohbet ve rapor üretiminde kullanılan bilgi tabanı ve içgörü akışıdır. Bu hem güvenli hem de gerçekçi bir kapsam; kod tabanını kendi kendine yeniden yazan tam otonom bir ajan ayrı ve çok daha riskli bir konu olduğu için v1 kapsamı dışında tutuldu.

**"İnsanların hikayeleri" nasıl toplanıyor**: Gerçek kişilerin sosyal medya paylaşımlarını izinsiz kazımak (scraping) hem gizlilik hem yanlış bilgi riski taşır. Bunun yerine `pubmed_recovery` kaynağı, PTSD/bipolar gibi durumlarla ilgili **yayınlanmış, hakemli nitel araştırmaları** (lived experience / recovery narrative çalışmaları) sorguluyor — yani insanların iyileşme yollarını anlatan, zaten bilim insanları tarafından toplanıp anonimleştirilmiş, atıf verilebilir kaynaklar. Detay için `docs/DATA_SOURCES.md`.

**Sohbetin kişiselleştirilmesi**: `/chat`, mesajı işlemeden önce kullanıcının son 3 günlük ruh hali/günlük verisini çeker ve mesajın embedding'iyle bilgi tabanında en alakalı 3 makaleyi arar (`analysis-engine::generate_chat_reply`). Bu bağlam, sistemin ikinci bir system-message'ı olarak modele geçiliyor — aynı cümleyi yazan iki farklı kullanıcı, geçmişleri farklıysa farklı bir yanıt alır.

**Gerçek bir konuşma gibi hissettirmek**: İki ayrı mekanizma birlikte çalışıyor:
1. *Hafıza*: Backend'de LLM'e giden istek için sunucu tarafı oturum/session yok — Flutter istemcisi görünen mesaj geçmişini (`ChatController`) her istekte `history` alanında geri gönderiyor (son 16 mesajla sınırlı), böylece model "bahsettiğin şeyi biraz anlat" gibi bir takip sorusuna gerçekten neyin bahsedildiğini bilerek cevap verebiliyor. Bu geçmiş Flutter tarafında da kalıcı: `ChatController` ekrana her girdiğinde önce `GET /chat/history` ile o hesabın **tüm** kayıtlı sohbetini yükler, yani konuşma tek, sürekli bir akış olarak kalır — uygulama kapansa, cihaz değişse ya da çıkış yapıp aynı hesapla tekrar girilse bile hiçbir mesaj kaybolmaz.
2. *Ton*: `llm-connector::prompts::chat_instruction`, motivasyonel görüşmenin OARS tekniği (açık uçlu soru, onaylama, yansıtma, özetleme) ve gerçek bir ilk terapi seansının akışından (önce tanışma/rapport, tavsiye sonra) esinlenerek yazıldı — kısa mesaja kısa cevap, tek seferde tek açık soru, cevap vermeden önce duyduğunu yansıtma. Kaynaklar: motivational interviewing OARS ve terapi intake-session pratikleri üzerine yapılan web araştırması (bkz. positivepsychology.com/motivational-interviewing-exercises, growtherapy.com/blog/how-to-improve-intake-sessions).

**Ton ve güvenlik dengesi**: `llm-connector::prompts::SAFETY_SYSTEM_PROMPT`, modelin varsayılan tavrını "hemen 'ben yardımcı olamam, bir uzmana git' de" değil, "gerçekten yardımcı ol, PTSD/bipolar gibi konularda araştırmaya dayalı bilgi ve başa çıkma stratejileri sun, kullanıcıyı uygulamada tut" olarak kuruyor. Tek sabit sınır: resmi bir tanı koymamak/ilaç önermemek ve gerçek kriz sinyallerinde (kendine zarar, intihar düşüncesi, acil durum) sohbeti sürdürmek yerine doğrudan acil yardım/kriz kaynaklarına yönlendirmek. Bu sınır App Store politikaları ve hukuki sorumluluk için gerekli; geri kalan her şeyde amaç kullanıcıyı başka bir yere yönlendirip bırakmak değil, sorununa gerçekten çözüm ortağı olmak.

**Süre kısıtları (ruh hali / günlük / yaşam analizi)**: Üçü de aynı desende, sunucu tarafında: son kayıttan bu yana yeterli süre geçmediyse `429 Too Many Requests` + `retry_after`. Ruh hali ve günlük **24 saat** (`routes/mood.rs`, `routes/journal.rs`), yaşam analizi **7 gün** (`routes/life_analysis.rs`). Flutter tarafı bunları geri sayımla gösterip formu kilitler; asıl kısıtlama sunucuda olduğu için istemci atlatamaz. Yaşam analizinin haftalık olmasının sebebi maliyet: tüm geçmişi okuyan en pahalı çağrı o, ve cevabı günden güne en az değişen de o.

**Zaman aralıkları neden farklı**: Günlük rapor **bugünü** anlatır ama izole bir veri noktası gibi değil — kullanıcının tüm ruh hali geçmişinden hesaplanan bir taban çizgi (bugünün ortalaması vs. önceki tüm kayıtların ortalaması, farkıyla birlikte) ve son 7 raporun özeti bağlam olarak modele gider; prompt tam olarak **bir cümlelik** geriye bakış ister ("her zamankinden iyi/kötü/benzer bir gün"), fazlası raporu geçmiş denemesine çevirirdi. Karşılaştırma sayıları koda hesaplatılır, modele tahmin ettirilmez. Yaşam analizi ise tersine **her şeyi** okur: ruh hali, günlük, sohbet ve geçmiş raporlar, en baştan bugüne (`analysis-engine/src/life_analysis.rs`, kaynak başına üst sınırlarla — hesap yıllandıkça prompt sınırsız büyümesin diye).

**Günlük arşivi**: `GET /journal` tüm kayıtları yeniden eskiye döndürür; Flutter tarafında `JournalScreen` bunları tarihleriyle listeler. Geri okunamayan bir günlük sadece bir formdur.

**Sohbetin kalıcılığı**: Her sohbet turu (hem kullanıcı mesajı hem model yanıtı) `chat_messages` tablosuna kalıcı olarak yazılıyor (`apps/server/src/routes/chat.rs::persist_turn`) ve `GET /chat/history` ile geri okunabiliyor (`ChatRepository::history_for_user`). Flutter tarafı bunu ekran her açıldığında (uygulama başlangıcı, hesap girişi, sekmeler arası geçiş) çekip transkripti dolduruyor — sohbet artık uygulamanın bellek-içi durumunda değil, hesabın kendisinde yaşıyor; her hesap girişinde `sessionTokenProvider` değiştiği için `ChatController` de sıfırlanıp o hesabın kendi geçmişini yeniden yüklüyor.

**LLM bağlantısı ("MCP benzeri")**: `llm-connector::LlmProvider` trait'i tek soyutlama noktası. Bugün `OpenAiCompatibleProvider` bunu OpenAI Chat Completions şemasıyla konuşan herhangi bir uç nokta için implemente ediyor (OpenAI, Azure OpenAI, uyumlu bir self-host). Model adı (`chat_model`) `config/default.toml`'da düz metin — yeni bir model çıktığında kod değil config değişir. `tools.rs` içindeki `Tool`/`ToolCall` tipleri, backend fonksiyonlarını (örn. ruh hali geçmişini getir) modele çağrılabilir "araç" olarak sunmak için MCP'nin function-calling fikrini taşıyor.

**Hesaplar ve kimlik doğrulama**: `/auth/register` (email + şifre, argon2 ile hash'lenir) ve `/auth/login` bir oturum token'ı (`sessions` tablosunda, 30 gün geçerli, opak rastgele token — imzalı bir JWT değil, çünkü bir satırı silerek sunucu tarafında iptal edilebilmesi gerekiyordu) döndürür. `mood`/`journal`/`chat`/`reports`/`life-analysis` altındaki **hiçbir** endpoint artık `user_id`'yi istekten almıyor — hepsi `apps/server/src/auth.rs::AuthUser` extractor'ı ile `Authorization: Bearer <token>` header'ından doğrulanmış kimliği okuyor. Bu, önceki tasarımdaki gerçek bir güvenlik açığını kapatıyor: eskiden herhangi biri rastgele bir UUID'yi `user_id` olarak göndererek başka birinin verisine yazabilir/okuyabilirdi.

Flutter tarafında artık gerçek, görünür bir giriş/kayıt ekranı var (`features/auth/presentation/auth_screen.dart`) — uygulama ilk açıldığında `app/router.dart`'ın `redirect` mantığı, geçerli (süresi dolmamış) bir oturum yoksa doğrudan `/login`'e yönlendirir; klasik oturum davranışı: `core/session/session_bootstrap.dart::loadStoredSession` her açılışta yerel olarak (ağ çağrısı yapmadan) saklı token'ı okur, süresi geçmemişse oturum otomatik açılır. Giriş/kayıt başarılı olduğunda `sessionTokenProvider` değişir, bu da `GoRouter`'ın `refreshListenable`'ını tetikleyip kullanıcıyı uygulamanın içine yönlendirir — ayrı bir "navigate on success" kodu yazmaya gerek kalmadan. `Ayarlar > Çıkış yap` oturumu hem sunucuda (`/auth/logout`) hem yerelde temizler. Ayrıca `apiClientProvider`'ın response interceptor'ı herhangi bir istekte 401 alırsa oturumu otomatik temizleyip kullanıcıyı `/login`'e geri düşürür (sunucu tarafında bir oturum iptal edilmişse diye).

**Tanı kataloğu ve kategoriler**: `domain/src/catalog.rs`, DSM-5-TR şeklinde 20 kategori ve altındaki ~129 durumu **derlenmiş statik veri** olarak tutar (veritabanında değil): kurulumdan kuruluma kaymasın ve `insights.category`, `users.diagnoses`, `disorder_explainers.slug` gibi alanların referans verdiği slug'lar sabit kalsın diye. `GET /catalog` bu ağacı olduğu gibi sunar (kimlik doğrulama gerektirmez — herkes için aynı referans verisi).

**Durum bilgi kartları**: `GET /catalog/disorders/:slug`, bir durumun "nedir / nasıl gelişir / günlük hayatta ne yardımcı olur / profesyonel destek neleri içerir" kartını döndürür. İlk istekte araştırma korpusundan RAG ile üretilir, sonra `disorder_explainers` tablosunda önbelleğe alınır — katalogda ~129 başlık var, her dokunuşta LLM çağrısı yapmak hem yavaş hem pahalı olurdu. Prompt (`prompts::disorder_explainer_instruction`) bilinçli olarak daha katı: üçüncü tekil şahısla ("bu durumda genellikle..."), okuyana hitap etmeden ("sende...") yazılır — bu bir referans girdisi, okuyan hakkında bir değerlendirme değil.

**Kendi bildirdiği tanılar**: `users.diagnoses` (katalog slug'ları), `GET /profile` + `PUT /profile/diagnoses`. Uygulama bunu asla kendisi doldurmaz; kişi kendi bildiğini söyler, bu da sohbet ve raporlarda bağlam olarak kullanılır ("tanı olarak kabul etme, neye dikkat edeceğini bilmek için kullan" talimatıyla). Gönderilen slug'lar kataloğa karşı doğrulanır.

**RAG gerçekten metin taşıyor**: `VectorStore::search` yalnızca ID ve skor döndürüyor, dolayısıyla eskiden prompt'a giden "ilgili araştırma" kısmı modelin okuyamayacağı çıplak UUID'lerdi — yani retrieval var, retrieved içerik yoktu. `analysis-engine::retrieval::retrieve_context` bu adımı tamamlıyor: embed → ara → `ResearchRepository::get_many` ile makale metinlerini çek. Sohbet, günlük rapor ve bilgi kartları bu yoldan geçiyor.

## Uygulama (`app/`, Flutter)

Feature-first + katmanlı (data/domain/presentation) yapı, Riverpod ile state management, go_router ile deklaratif yönlendirme:

```
app/lib/
  app/            # MaterialApp kurulumu, tema, router
  core/           # paylaşılan network client (auth interceptor'lı), oturum bootstrap, local storage, sabitler
  features/
    auth/           # gerçek giriş/kayıt ekranı + controller + API client (bkz. yukarı)
    daily_report/   # bugünün raporu + geçmişe göre konum
    mood_tracking/  # 2B pad + 24 saat bekleme
    journal/        # günde 1 giriş + tarih tarihine arşiv
    chat/
    catalog/        # kategori/durum ağacı + durum bilgi kartı ekranı
    insights/       # kategori seçici + araştırma akışı + durum listesi
    life_analysis/  # tüm geçmiş: anlatı, örüntüler, yapılacak/yapılmayacaklar
    profile/        # kendi bildirdiği tanıların seçimi
    settings/
    home/           # bottom-nav shell
```

Her feature kendi `data/` (API client), `domain/` (model) ve `presentation/` (widget + Riverpod controller) klasörüne sahip; feature'lar birbirinin `data`/`presentation` katmanına değil sadece paylaşılan `core/`'a bağımlı.

## iOS / App Store notu

Bu proje Windows üzerinde geliştiriliyor. Flutter kodu tamamen platform-bağımsız yazıldı ve `flutter create` ile ios/ klasörü oluşturuldu, ancak **iOS derlemesi ve App Store'a gönderim mutlaka Xcode + macOS gerektirir**. Seçenekler: gerçek bir Mac, ya da GitHub Actions'ın `macos-latest` runner'ı gibi bulut CI. `.github/workflows/ci.yml` içinde bu iş için yorum satırı halinde bir başlangıç noktası bırakıldı.
