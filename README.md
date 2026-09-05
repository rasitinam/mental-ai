# Mental AI

Yerel-öncelikli (local-first) bir mental sağlık öz-farkındalık asistanı: ruh hali takibi, günlük, güncel psikoloji/psikiyatri araştırmalarına dayanan günlük mental rapor ve yaşam analizi, sohbet.

> Mental AI lisanslı bir psikolog, psikiyatrist ya da tıbbi cihaz değildir ve tanı koymaz. Bkz. [docs/PRIVACY.md](docs/PRIVACY.md).

## Yapı

```
backend/   Rust workspace (axum API, arka plan araştırma toplama servisi, LLM orkestrasyonu)
app/       Flutter uygulaması (iOS / Android / Web)
docs/      Mimari, veri kaynakları ve gizlilik notları
scripts/   Geliştirme sırasında kullanılan yardımcı script'ler
```

Detaylı mimari için [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Gereksinimler

- Rust (stable, GNU toolchain önerilir — Windows'ta Visual Studio gerektirmez): https://rustup.rs
- Flutter SDK (stable channel): https://flutter.dev
- Bir LLM API anahtarı (OpenAI veya OpenAI-uyumlu bir sağlayıcı)

## Backend'i çalıştırma

```bash
cd backend
# API anahtarını ortam değişkeni olarak ver (config dosyasına asla yazma)
export MENTAL_AI_LLM_API_KEY=sk-...
cargo run -p mental-ai-server
```

Varsayılan olarak `http://127.0.0.1:8787` üzerinde dinler ve `backend/data/mental_ai.db` SQLite dosyasını (migration'ları otomatik uygulayarak) oluşturur. Ayarlar için `backend/config/default.toml` ve `backend/config/README.md`'ye bakın.

## Uygulamayı çalıştırma

```bash
cd app
flutter pub get
flutter run -d chrome   # hızlı yerel test için; gerçek cihaz/emulator da kullanılabilir
```

Backend farklı bir adreste çalışıyorsa: `flutter run --dart-define=API_BASE_URL=http://<host>:8787`.

## iOS / App Store

iOS derlemesi ve App Store'a gönderim **Xcode + macOS** gerektirir (bu proje Windows'ta geliştiriliyor). `flutter create` ile oluşturulan `app/ios/` klasörü bir Mac'e (veya macOS CI runner'ına) taşınıp doğrudan derlenebilir. Detaylar için [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#ios--app-store-notu).

## CI/CD

`.github/workflows/` altında üç workflow var: her push'ta çalışan, secret gerektirmeyen `ci.yml` (build+test, Android/iOS derleme doğrulaması dahil), ve elle tetiklenen `release-android.yml` / `release-ios.yml` şablonları — imzalama secret'larını eklediğinde gerçek yayın build'i üretirler. Hangi secret'ı nereden alacağını gösteren tam kontrol listesi: [docs/CI_CD.md](docs/CI_CD.md).

## Test

```bash
cd backend && cargo test --workspace
cd app && flutter test
```
