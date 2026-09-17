# CI/CD

Üç workflow var, hepsi `.github/workflows/`:

| Dosya | Ne zaman çalışır | Secret gerektirir mi |
|---|---|---|
| `ci.yml` | Her push/PR | Hayır — backend `cargo check/test`, Flutter `analyze/test`, ve Android/iOS için **imzasız** build doğrulaması |
| `release-android.yml` | Elle tetikleme (`workflow_dispatch`) veya `v*.*.*` tag push'u | Evet |
| `release-ios.yml` | Elle tetikleme veya `v*.*.*` tag push'u | Evet |

`ci.yml` hiçbir secret istemiyor ve şu an tam çalışır durumda — Android/iOS derlemesinin en azından **bozulmadığını** her push'ta doğruluyor, imzalama/yayınlama olmadan. Release workflow'ları ise iskelet/şablon: doğru sözdizimine sahipler ve secret'lar eklenince çalışacak şekilde yazıldılar, ama gerçek Apple/Google kimlik bilgileri olmadan test edilemediler — ilk denemede küçük ayar gerektirebilirler, bu normal.

## Secret'ları nereye eklerim

GitHub reposunda: **Settings → Secrets and variables → Actions → New repository secret**.

## Android için gerekenler (`release-android.yml`)

1. **Bir upload keystore oluştur** (bilgisayarında, bir kere):
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Bu dosyayı ve şifreleri güvenli bir yerde (parola yöneticisi) sakla — kaybedersen Play Store'da aynı uygulamayı güncelleyemezsin.

2. **Secret'lar:**

   | Secret adı | Değer |
   |---|---|
   | `ANDROID_KEYSTORE_BASE64` | `base64 -i upload-keystore.jks \| pbcopy` (macOS) veya `[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) \| Set-Clipboard` (Windows PowerShell) çıktısı |
   | `ANDROID_KEYSTORE_PASSWORD` | keytool'a girdiğin keystore şifresi |
   | `ANDROID_KEY_ALIAS` | `upload` (yukarıdaki `-alias` ile aynı) |
   | `ANDROID_KEY_PASSWORD` | keytool'a girdiğin key şifresi |

3. **Play Store'a otomatik yükleme** (opsiyonel, `release-android.yml` içinde yorum satırı): Google Play Console'da bir servis hesabı oluşturup JSON key'ini `PLAY_STORE_SERVICE_ACCOUNT_JSON` secret'ı olarak ekle, sonra workflow'daki ilgili adımın yorumunu kaldır. Bunun için önce Play Console'da uygulamanın en az bir kez elle oluşturulmuş olması gerekiyor.

## iOS için gerekenler (`release-ios.yml`)

Bir Apple Developer Program üyeliği (yıllık ücretli) gerekiyor.

1. **Distribution sertifikası** (Apple Developer portal → Certificates → "Apple Distribution"): oluştur, indir, Keychain Access'te sağ tık → Export → `.p12` olarak dışa aktar, bir şifre belirle.
2. **Provisioning profile** (Apple Developer portal → Profiles → "App Store" tipinde): App ID'n (`com.mentalai.mental_ai`) için oluştur, `.mobileprovision` olarak indir.
3. **App Store Connect API key** (App Store Connect → Users and Access → Keys → "Integrations"): oluştur, `.p8` dosyasını indir (sadece bir kez indirilebilir), Key ID ve Issuer ID'yi not al.

4. **Secret'lar:**

   | Secret adı | Değer |
   |---|---|
   | `IOS_DISTRIBUTION_CERT_P12` | `.p12` dosyasının base64'ü |
   | `IOS_CERTIFICATE_PASSWORD` | `.p12`'yi dışa aktarırken belirlediğin şifre |
   | `IOS_PROVISIONING_PROFILE` | `.mobileprovision` dosyasının base64'ü |
   | `APP_STORE_CONNECT_API_KEY_ID` | API key'in Key ID'si |
   | `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect hesabının Issuer ID'si |
   | `APP_STORE_CONNECT_API_KEY` | `.p8` dosyasının base64'ü |
   | `APPLE_TEAM_ID` | Apple Developer portal → Membership'teki Team ID |

5. `APPLE_TEAM_ID` secret'ı, `app/ios/ExportOptions.plist` içindeki `REPLACE_WITH_YOUR_APPLE_TEAM_ID` yer tutucusunun yerine workflow çalışırken otomatik yazılıyor (bkz. `release-ios.yml`'deki "Set the Apple Team ID" adımı) — dosyayı elle düzenlemene gerek yok.

## LLM API anahtarı — CI'da gerekli mi?

Hayır. `ci.yml`'deki hiçbir job gerçek bir LLM çağrısı yapmıyor (`cargo test` şu an ağ çağrısı yapan test içermiyor). Backend'i sadece kendi bilgisayarında, `MENTAL_AI_LLM_API_KEY` ortam değişkeniyle çalıştırıyorsun — bkz. ana `README.md`.
