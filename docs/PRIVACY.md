# Gizlilik ve Güvenlik Notları

## Veri nerede duruyor?

Backend local-first tasarlandı: tüm kullanıcı verisi (ruh hali kayıtları, günlük, raporlar) kullanıcının kendi cihazında/bilgisayarında çalışan SQLite veritabanında tutulur (`backend/config/default.toml` → `database.url`). Sunucuya veri göndermenin tek yolu, kullanıcının kendi seçtiği LLM sağlayıcısına (OpenAI vb.) analiz için yapılan API çağrılarıdır — bkz. `docs/ARCHITECTURE.md`.

## Hesaplar ve şifreler

Şifreler asla düz metin saklanmaz — `argon2` (bellek-zorlu, kaba kuvvet saldırılarına karşı endüstri standardı bir hash algoritması) ile hash'lenip `credentials.password_hash` sütununda tutulur. Oturum token'ları (`sessions` tablosu) rastgele 256-bit değerlerdir, JWT gibi imzalı/kendinden-doğrulanan bir yapı değildir — bilinçli bir tercih: bir oturumu iptal etmek için sadece ilgili satırı silmek yeterli, ayrı bir "denylist" mekanizması gerekmiyor. Detaylar için `backend/apps/server/src/auth.rs`.

## Kriz taraması (`analysis-engine::safety`)

Her günlük girişi ve sohbet mesajı, LLM'e gitmeden önce basit bir anahtar kelime taramasından geçer (`screen_for_crisis_language`). Bu **klinik bir değerlendirme değildir** — yüksek recall hedefleyen kaba bir güvenlik ağıdır. Yanlış pozitif (gereksiz yere kriz bandı gösterme) kabul edilebilir bir maliyettir; asıl önemli olan yanlış negatifleri (gerçek bir krizi kaçırmayı) minimize etmek.

**Üretime çıkmadan önce yapılması gerekenler**:
- Anahtar kelime listesini bir klinik danışmanla/psikologla gözden geçirin.
- Türkçe (ve hedeflenen diğer diller) için ayrı bir liste ekleyin — şu an sadece İngilizce terimler var.
- Ülkeye göre değişen gerçek kriz hattı numaralarını (`+90 182`, 112 vb.) uygulama içinde göstermeyi değerlendirin.

## LLM sağlayıcısına giden veri

`llm-connector::SAFETY_SYSTEM_PROMPT`, modele her çağrıda "tanı koyma", "lisanslı uzmanın yerine geçme" ve kriz durumunda kaynaklara yönlendirme kurallarını hatırlatır. Ancak bu bir garanti değil, bir yönlendirmedir — model çıktısı App Store'a göndermeden önce gerçek kullanıcı senaryolarıyla test edilmelidir.

## App Store / hukuki konumlandırma

Uygulama "mental wellness / öz-farkındalık asistanı" olarak konumlandırıldı, klinik tanı/tedavi iddiası taşımıyor. Bu, Apple'ın sağlık uygulamaları incelemesi ve çoğu ülkedeki tıbbi cihaz mevzuatı açısından daha güvenli bir kategori. Metinlerde ("tanı", "tedavi", "psikoterapi" gibi klinik terimler yerine "öz-farkındalık", "yansıma", "öneri") bu çizgiyi korumaya dikkat edin.
