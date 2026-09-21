# E-posta doğrulama kodu (kayıt)

Kayıt olurken girilen e-posta adresine 6 haneli bir kod gider; hesap ancak doğru kod girilince oluşur. Böylece kimse başkasının adresiyle hesap açamaz. Giriş (login) ve Apple ile giriş kod istemez; demo hesabın girişi de kodsuzdur.

## Akış

1. Uygulama `POST /auth/register/code` çağırır (`email`, `language`). Sunucu 6 haneli kodu üretir, **hash'ini** `email_verifications` tablosuna yazar ve e-postayı gönderir.
2. Kullanıcı kodu girer. Uygulama `POST /auth/register` çağırır (`email`, `password`, `code`, ...). Kod doğruysa hesap açılır ve kod silinir (tek kullanımlık).

Sınırlar (`backend/apps/server/src/email_verify.rs`):

| Kural | Değer |
|---|---|
| Kod geçerlilik süresi | 10 dakika |
| Aynı adrese yeniden gönderme | en az 60 sn arayla (429) |
| Aynı adrese saatlik en çok | 5 kod (429) |
| Bir koda karşı yanlış deneme | 5 (sonra yeni kod gerekir, 429) |
| Sunucunun günlük toplam gönderimi | 400 (Gmail SMTP sınırı günde 500) |

Yanlış ya da süresi dolmuş kod `422`, adres zaten kayıtlıysa `409`, e-posta gönderilemezse `503` döner.

## Gmail ile kurulum (bir kerelik)

Kodlar, kendi Gmail hesabından SMTP ile gider. Gmail normal şifreni kabul etmez, **Uygulama Şifresi** ister:

1. Google hesabında 2 Adımlı Doğrulama açık olmalı: <https://myaccount.google.com/security>
2. <https://myaccount.google.com/apppasswords> adresinde "Hearth" adıyla bir uygulama şifresi oluştur. 16 haneli şifre bir kez gösterilir.
3. PowerShell'de (şifreyi kendi değerinle değiştir; boşlukları silmene gerek yok):

```powershell
setx MENTAL_AI_SMTP_USER "inamrasit@gmail.com"
setx MENTAL_AI_SMTP_PASSWORD "abcd efgh ijkl mnop"
```

4. Backend'i yeniden başlat (ortam değişkenleri yalnızca yeni açılan süreçlere geçer): `MentalAI Backend` görevini durdurup başlat ya da bilgisayarı yeniden başlat.

İsteğe bağlı: `MENTAL_AI_SMTP_HOST` (varsayılan `smtp.gmail.com`, 465 numaralı portta TLS) ve `MENTAL_AI_SMTP_FROM` (gönderen adres, varsayılan kullanıcı adı). Başka bir sağlayıcıya (Resend, Brevo, SES vb.) geçmek için host, kullanıcı ve şifreyi değiştirmek yeter.

SMTP ayarlı değilse sunucu kodu e-posta olarak **göndermez, günlüğe (log) yazar** ve başlangıçta bunu uyarı olarak belirtir. Yerel geliştirme ve `scripts/e2e_smoke.sh` böyle çalışır. Canlıda bu durumda kullanıcı kodu göremez, yani kayıt olamaz.

## Test

- Birim testleri: `cargo test -p mental-ai-server email_verify`
- Uçtan uca: `scripts/e2e_smoke.sh` kodun kendisini okuyamaz (yalnızca hash saklanır); bu yüzden adres için bilinen bir kodun hash'ini `email_verifications` tablosuna yazar (`plant_code`).

## Eski sürümler

Kod zorunlu olduğundan, kod adımı olmayan eski uygulama sürümleri (TestFlight build 14 ve öncesi, eski APK'lar) artık **kayıt olamaz**; giriş yapmaya devam ederler. Yeni backend'i, yeni iOS build'i ve yeni APK ile birlikte devreye almak gerekir.
