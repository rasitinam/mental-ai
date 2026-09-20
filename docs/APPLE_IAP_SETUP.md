# Hearth Plus: Uygulama İçi Satın Alma Kurulumu (Apple)

Koddaki her şey hazır: paywall (`app/lib/features/premium/`), StoreKit akışı, backend makbuz doğrulaması (`backend/apps/server/src/routes/purchases.rs`) ve ücretsiz sohbet limiti dolunca paywall'a yönlendirme. Satın almanın **gerçekten çalışması** için App Store Connect tarafında aşağıdakilerin yapılması gerekir. Bunlar Apple hesabına bağlı olduğu için kodla çözülemez.

## 1. Ücretli Uygulamalar Sözleşmesi

App Store Connect → **Sözleşmeler, Vergi ve Bankacılık** (Agreements, Tax, and Banking):

- **Paid Apps** sözleşmesi *Aktif* olmalı.
- Banka hesabı ve vergi formu doldurulmuş olmalı.

Bu olmadan ürünler uygulamaya hiç yüklenmez ve paywall "Satın alma şu anda kullanılamıyor" der.

## 2. Abonelik ürünü

Hearth → **Abonelikler** (Subscriptions):

1. Bir *Abonelik Grubu* oluştur (ör. "Hearth Plus").
2. Gruba abonelik ekle:
   - **Ürün Kimliği (Product ID): `com.rasitinam.hearth.premium.monthly`** (birebir aynı olmalı, `premium_controller.dart` bunu arıyor)
   - Süre: 1 ay
   - Fiyat: istediğin fiyat
   - Yerelleştirme: Türkçe ve İngilizce görünen ad + açıklama
   - İnceleme ekran görüntüsü: uygulamadaki Hearth Plus ekranı
3. Durum **Gönderilmeye Hazır** (Ready to Submit) olmalı.

## 3. Uygulamaya özel paylaşılan sır (shared secret)

Hearth → **Uygulama Bilgileri** (App Information) → *App-Specific Shared Secret* → Oluştur.

Sunucu makbuzu Apple'a bu sırla doğrulatır. Yoksa `/purchases/verify-apple` 503 döner. Sır kalıcı kullanıcı ortam değişkeni olarak ayarlanır, koda ya da repoya **yazılmaz**:

```powershell
setx MENTAL_AI_APPLE_SHARED_SECRET "BURAYA_SIR"
```

Sonra backend'i **yeni açılan** bir terminalden yeniden başlat (`setx` sadece yeni süreçleri etkiler):

```powershell
powershell -NoProfile -File "G:\mental-ai\scripts\stop-backend-background.ps1"
powershell -NoProfile -File "G:\mental-ai\scripts\start-backend-background.ps1"
```

Açılışta sunucu log'unda "no Apple shared secret found" uyarısı çıkmıyorsa sır okunmuştur.

## 4. Test

- Bir TestFlight build'inde satın alma otomatik olarak **sandbox**'ta yapılır, gerçek para çekilmez. Sunucu Apple'ın sandbox makbuz kodunu (21007) tanır ve sandbox'a düşer.
- İstersen App Store Connect → Kullanıcılar ve Erişim → **Sandbox** altında test hesabı da açabilirsin.
- Akış: Profil → Hearth Plus → *Abone Ol*. Başarılı olunca sohbet limiti kalkar.
- Ücretsiz limit dolunca sohbet zaten paywall'a yönlendirir. Limit `backend/apps/server/src/routes/chat.rs` içindeki `FREE_DAILY_CHAT_TOKEN_BUDGET` sabitidir (şu an 10.000 token/gün).

## Durum (2026-09-20)

- Ürün `com.rasitinam.hearth.premium.monthly` (1 ay, 9,99$ taban) ve "Hearth Plus" abonelik grubu App Store Connect'te hazır.
- Sürüm 1.0 **build 9** (API adresi düzeltilmiş build) + abonelik + grup birlikte incelemeye gönderildi. Eski build 1 hatalıydı (`127.0.0.1`'e bağlanıyordu), incelemeden çekildi.
- `MENTAL_AI_APPLE_SHARED_SECRET` kullanıcı ortam değişkeni olarak ayarlı, backend onunla çalışıyor.
- Paid Apps Agreement gönderim sırasında hâlâ "Pending User Info" idi (banka işleniyor, W-8BEN vergi formu). Aktif olana kadar ürün StoreKit'e yüklenmeyebilir.
- İnceleyici giriş hesabı olarak `inamrasit@gmail.com` girili. İnceleme sürerken bu hesaba elle Plus **verme**: inceleyici "Abone Ol" yerine "zaten aktif" görüp satın almayı test edemez. Onaydan sonra geri verilebilir:
  `INSERT INTO subscriptions (user_id,platform,product_id,original_transaction_id,expires_at,updated_at) VALUES ('eea925a7-aa57-4ad5-bae1-2ea10bdd2644','manual','com.rasitinam.hearth.premium.monthly','manual-owner-grant','2099-12-31T00:00:00+00:00', datetime('now'));`

## 5. App Store incelemesi

İlk abonelik, uygulamanın bir sürümüyle birlikte incelemeye gönderilmelidir: sürüm sayfasında *Uygulama İçi Satın Almalar ve Abonelikler* bölümünden aboneliği seç. Apple incelemesi sırasında hem sunucunun (backend + ngrok) hem de paywall'daki gizlilik/koşullar bağlantılarının açık olması gerekir.

## Android

`in_app_purchase` Android'de Google Play Faturalandırma'yı kullanır. Backend şu an sadece Apple makbuzunu doğruluyor (`platform = "apple"`), Play'de ürün de yok. Bu yüzden APK sürümünde paywall "Satın alma şu anda kullanılamıyor" gösterir. Android'de satmak için Play Console'da ürün açıp backend'e bir Google doğrulaması eklemek gerekir.
