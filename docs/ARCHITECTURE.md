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

**"Kendi kendini geliştirme" burada ne anlama geliyor**: `research-ingest` crate'i arka planda (varsayılan: 6 saatte bir) PubMed ve WHO gibi kaynaklardan yeni özet/makale metadata'sı çeker, `knowledge-base`'e embed edip ekler. Uygulamanın kendi kaynak kodunu hiçbir şey otomatik değiştirmez — büyüyen şey, günlük rapor üretirken kullanılan bilgi tabanıdır. Bu hem güvenli hem de gerçekçi bir kapsam; kod tabanını kendi kendine yeniden yazan tam otonom bir ajan ayrı ve çok daha riskli bir konu olduğu için v1 kapsamı dışında tutuldu.

**LLM bağlantısı ("MCP benzeri")**: `llm-connector::LlmProvider` trait'i tek soyutlama noktası. Bugün `OpenAiCompatibleProvider` bunu OpenAI Chat Completions şemasıyla konuşan herhangi bir uç nokta için implemente ediyor (OpenAI, Azure OpenAI, uyumlu bir self-host). Model adı (`chat_model`) `config/default.toml`'da düz metin — yeni bir model çıktığında kod değil config değişir. `tools.rs` içindeki `Tool`/`ToolCall` tipleri, backend fonksiyonlarını (örn. ruh hali geçmişini getir) modele çağrılabilir "araç" olarak sunmak için MCP'nin function-calling fikrini taşıyor.

## Uygulama (`app/`, Flutter)

Feature-first + katmanlı (data/domain/presentation) yapı, Riverpod ile state management, go_router ile deklaratif yönlendirme:

```
app/lib/
  app/            # MaterialApp kurulumu, tema, router
  core/           # paylaşılan network client, local storage, sabitler, Result tipi
  features/
    onboarding/
    daily_report/   # data + domain + presentation
    mood_tracking/
    journal/
    chat/
    insights/       # iskelet (backend endpoint'i henüz yok)
    life_analysis/  # iskelet (backend endpoint'i henüz yok)
    settings/
    home/           # bottom-nav shell
```

Her feature kendi `data/` (API client), `domain/` (model) ve `presentation/` (widget + Riverpod controller) klasörüne sahip; feature'lar birbirinin `data`/`presentation` katmanına değil sadece paylaşılan `core/`'a bağımlı.

## iOS / App Store notu

Bu proje Windows üzerinde geliştiriliyor. Flutter kodu tamamen platform-bağımsız yazıldı ve `flutter create` ile ios/ klasörü oluşturuldu, ancak **iOS derlemesi ve App Store'a gönderim mutlaka Xcode + macOS gerektirir**. Seçenekler: gerçek bir Mac, ya da GitHub Actions'ın `macos-latest` runner'ı gibi bulut CI. `.github/workflows/ci.yml` içinde bu iş için yorum satırı halinde bir başlangıç noktası bırakıldı.
