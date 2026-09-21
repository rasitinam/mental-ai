# App Review: notlar ve Apple'a cevap

Apple 2.1 "Information Needed" istedi (2026-09-20). Aşağıdaki **Notes** metni App Store Connect'te *App Review Information → Notes* alanına (4.000 karakter sınırı) girilir, **Reply** metni de Resolution Center'daki mesaja cevap olarak gönderilir. Demo hesabın e-posta/şifresi metne yazılmaz, *Sign-In Information* alanlarında durur.

## Notes (App Review Information → Notes)

```
WHAT HEARTH IS
Hearth (Turkish name: Acik Ocak) is a mood-tracking and self-reflection companion for people 13+ who deal with everyday mental-health struggles. It helps people notice patterns in how they feel, put words to it, and feel less alone. Available in Turkish and English (follows the device language, switchable in Settings). It is not a medical device and does not diagnose or treat anything.

HOW TO ACCESS
Demo account credentials are in Sign-In Information above (pre-filled with sample data). You can also tap "Create account" (it emails a 6-digit code to the address you enter). Tabs: Today (one-tap mood check-in, journal typed or dictated, "your state"), Chat (AI companion), Stories (moderated community), My path (weekly recap, pre-session summary for a therapist), Me (profile, Settings, Hearth Plus, Blocked people, delete account).

USER-GENERATED CONTENT (Guideline 1.2)
- Stories are pre-moderated: an admin approves every story before anyone else can see it. Authors may stay anonymous.
- Report: flag icon on any story > Report (goes to an admin queue).
- Block: flag icon > "Block author" (works on anonymous stories without revealing the author); also "Block" on profiles and in DM threads. Manage under Me > Settings > Blocked people. Blocked people cannot see each other's stories or profile and cannot message or follow each other.
- Direct messages are request-gated: the recipient must accept first and can decline or leave at any time, or limit requests to people they follow (Settings > Privacy).
- Contact: inamrasit@gmail.com

ACCOUNT
Sign in with email/password or Sign in with Apple. Delete account: Me tab > scroll to the very bottom > Delete Account (asks for the password, or Apple re-verification for Sign in with Apple accounts). It permanently deletes all of the person's data.

IN-APP PURCHASE
One auto-renewable subscription: Hearth Plus, 1 month (com.rasitinam.hearth.premium.monthly). Unlocks unlimited AI chat (the free plan has a small daily chat allowance) and more frequent analyses. To reach it: Me tab > scroll to the "Hearth Plus" card (Settings section). The paywall shows the title, length (1 month), price from the App Store, Subscribe, Restore Purchases, and links to the Terms of Use and Privacy Policy. It also opens automatically when the free daily chat allowance is used up (about 5 messages in the Chat tab). Receipts are verified on our server with Apple; sandbox receipts are supported.

EXTERNAL SERVICES
- OpenAI API: writes chat replies, daily/weekly reports and analyses, translations, embeddings and the read-aloud voice. The text a person writes is sent to OpenAI; it is not used for advertising or sold. This is disclosed on the first-launch privacy screen, which asks for explicit consent.
- Apple: StoreKit and App Store receipt verification, Sign in with Apple, speech recognition for voice dictation.
- Firebase Cloud Messaging: push notifications (evening reminder, new message).
- PubMed / NCBI E-utilities: public research abstracts used to ground insights (no user data sent).
- Our own backend (Rust, SQLite) reached over HTTPS through an ngrok domain.
- GitHub Pages: hosts the Privacy Policy and Terms of Use.
No analytics or advertising SDKs.

REGIONS
The app behaves the same in every region. The only regional element is the emergency shortcut (Support / "Call 112"), which dials 112: Turkey's and the EU's emergency number, forwarded to the local emergency service by most mobile networks elsewhere. The number is not localized per country.

REGULATED CONTENT
Wellbeing and self-reflection only; no diagnosis, no medical advice, no protected third-party material. The questionnaires (PHQ-9, GAD-7, WHO-5, PHQ-15, PC-PTSD-5, AUDIT-C, CAGE-AID) are publicly available screening instruments, used for self-reflection and explained as "not a diagnosis". Crisis wording in chat or journal shows a support banner with the emergency number.
```

## Reply to App Review (Resolution Center)

```
Hello, and thank you for the review.

Everything you asked for is in the App Review Notes field, and the demo account (with sample data) is in Sign-In Information:
1. Screen recording on a physical iPhone: attached (launch, registration, login, account deletion, stories with reporting and blocking, and the Hearth Plus purchase flow showing title, length, price, Terms of Use and Privacy Policy).
2. Purpose and audience, 3. how to access the features, 4. external services, 5. regional differences, 6. regulated content and 7. the in-app purchase and how to reach it are all in the Notes.

Since the first submission we also added Sign in with Apple and the ability to block other users (Me > Settings > Blocked people; also on stories, profiles and DM threads). The build we are resubmitting includes both.

Please let us know if you need anything else.
```

## Ekran kaydı (fiziksel iPhone, TestFlight'taki son build)

Apple bunu **fiziksel iPhone**'dan istiyor. Kayıt: Denetim Merkezi > Ekran Kaydı, *uygulama açılırken başlar*. Sırayla:

1. Uygulamayı aç. Gizlilik ekranını kaydırarak kabul et.
2. **Kayıt**: "Hesap oluştur" > yeni e-posta ve şifre > e-postana gelen **6 haneli kodu gir** > onboarding'i geç. (Gmail'de `inamrasit+apple1.com` gibi bir takma adres kullanırsan kod yine kendi kutuna gelir.) Sonra **Çıkış yap**.
3. **Giriş**: aynı hesapla giriş yap (ve isteğe bağlı Apple ile devam et).
4. Bugün'de ruh hali kaydı, günlük yaz. Sohbet'te birkaç mesaj yaz.
5. **Hikayeler**: bir hikayeye bak, bayrak > **Bildir** (metin yazıp gönder), sonra bayrak > **Yazarı engelle** (onayla). Ben > Ayarlar > **Engellenenler**'de göründüğünü ve **Engeli kaldır**'ı göster.
6. **Abonelik**: Ben sekmesi > kaydır > **Hearth Plus** kartı. Ekranda ad, süre, fiyat, "Abone Ol", "Satın Almaları Geri Yükle" ve Kullanım Koşulları / Gizlilik Politikası bağlantıları görünsün. Sandbox ile satın almayı tamamla (TestFlight'ta ücret alınmaz).
7. **Hesap silme**: Ben sekmesi > en alta > **Hesabı sil** > onayla.

İpucu: ekranın **İngilizce** dilde olması inceleyici için daha iyi; kaydı 2-3 dakikada tut.
