# Sign in with Apple

Giriş/kayıt ekranında (sadece iOS) "Apple ile devam et" butonu var. E-posta/şifre girişi aynen duruyor.

## Nasıl çalışıyor

1. Uygulama Apple'ın sistem sayfasını açar (`sign_in_with_apple`), her denemeye özel rastgele bir **nonce** üretir ve Apple'a SHA-256'sını verir.
2. Apple imzalı bir kimlik jetonu (JWT) döner. Uygulama bunu ham nonce ile birlikte `POST /auth/apple` ile backend'e gönderir.
3. Backend (`apps/server/src/apple_signin.rs`) jetonu doğrular: RS256 imzası (Apple'ın `appleid.apple.com/auth/keys` anahtarlarıyla), `iss = https://appleid.apple.com`, `aud` = bundle id (`com.rasitinam.hearth`), süre, ve nonce'un SHA-256'sı. Sahte, süresi dolmuş, başka uygulamaya ait ya da başka nonce'lu jeton 401 alır.
4. Hesap, Apple'ın kalıcı `sub` değerine bağlanır (`apple_identities` tablosu). İlk girişte hesap açılır ve uygulama onboarding'e yönlenir; sonrakilerde doğrudan oturum açılır.

## Bilinçli kararlar

- **E-posta ile otomatik birleştirme yok.** Kayıtta e-posta doğrulanmadığı için, aynı adresle Apple'la girene başkasının önceden açtığı şifreli hesabı vermek güvenlik açığı olurdu. Aynı e-posta zaten kayıtlıysa `409` döner ("Bu e-posta ile zaten bir hesap var"), kişi şifresiyle girer.
- Apple hesaplarının `password_hash` değeri geçersiz bir sabittir (`!apple`), yani `/auth/login` ile o hesaba hiçbir şifreyle girilemez.
- **Hesap silme** şifre yerine Apple ile yeniden doğrulama ister: uygulama taze bir Apple jetonu alır, backend aynı `sub`'a ait olduğunu doğrular.
- Apple'ın "e-postamı gizle" seçeneği kullanılırsa e-posta bir relay adresidir; e-posta yoksa uydurma bir `.invalid` adres üretilir ve profilde gösterilmez.
- Android'de buton gösterilmez: orada Apple girişi ayrıca bir "Services ID" ve yönlendirme sayfası ister.

## Apple tarafı kurulumu (yapıldı)

- App ID `com.rasitinam.hearth` üzerinde **Sign In with Apple** yeteneği açık.
- Bu değişiklik mevcut provisioning profile'ı geçersiz kılar; "Hearth AppStore Profile" yeniden üretilip GitHub secret'ı `IOS_PROVISIONING_PROFILE` (base64) güncellendi. Yeni bir yetenek eklenirse aynısı tekrarlanmalı.
- `ios/Runner/Runner.entitlements` → `com.apple.developer.applesignin = Default`, Xcode projesine `CODE_SIGN_ENTITLEMENTS` olarak bağlı.

## Eksik: Apple jetonunu iptal etme

Apple, Apple ile açılmış bir hesap silindiğinde jetonun REST API ile iptal edilmesini (`/auth/revoke`) bekler. Bu **henüz yok**. Bunun için Apple Developer → Keys'ten "Sign in with Apple" anahtarı (.p8), Key ID ve Team ID gerekir; backend bunlarla `client_secret` JWT'si (ES256) üretip yetkilendirme kodunu refresh token'a çevirmeli ve silme sırasında iptal etmeli. Anahtar bir kimlik bilgisi olduğu için ortam değişkeni olarak verilmelidir.

## Test

- Backend: `apple_signin.rs` içindeki birim testler + `scripts/e2e_smoke.sh` (`/auth/apple` sahte jetonu 401'ler, profilde `signs_in_with_apple` alanı vardır).
- Jeton doğrulaması gerçek bir RSA anahtarıyla uçtan uca denendi: geçerli jeton kabul; yanlış audience, issuer, nonce, süresi dolmuş, bilinmeyen anahtar ve bozulmuş imza reddedildi.
- Gerçek Apple penceresi yalnızca fiziksel iPhone/TestFlight'ta denenebilir.
