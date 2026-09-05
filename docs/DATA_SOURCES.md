# Araştırma Kaynakları

`backend/crates/research-ingest` şu an iki kaynağı destekliyor:

| Kaynak | Yöntem | Ne saklanır |
|---|---|---|
| PubMed | NCBI E-utilities (ESearch + EFetch), `psychology OR psychiatry OR mental health` sorgusu | Başlık, özet (abstract) metni, PMID, yayın tarihi |
| WHO | Ruh sağlığı haberleri RSS akışı | Başlık, açıklama, link |

## Kurallar

- **Sadece açık erişimli özet/metadata** saklanır. Telif hakkı taşıyan tam makale metni asla indirilmez veya saklanmaz.
- Her kayıt kaynağına geri bağlanan bir `url` taşır; uygulama içinde bir içgörü gösterilirken "kaynak: ..." şeklinde atıf yapılmalı.
- Yeni bir kaynak eklerken `ResearchSource` trait'ini implemente edin (`backend/crates/research-ingest/src/sources/`) ve `apps/server/src/scheduler.rs::build_sources`'a kaydedin.
- Kaynak seçerken API kullanım şartlarına (rate limit, atıf zorunluluğu) uyulmalı; PubMed E-utilities için NCBI'nin kullanım politikasına bakın.

## Neden bir vektör veritabanı değil de SQLite?

`knowledge-base` crate'i embedding'leri SQLite'ta BLOB olarak saklayıp brute-force cosine similarity ile arıyor. Tek kullanıcının kişisel araştırma akışı ölçeğinde (binlerce, milyonlarca değil makale) bu yeterince hızlı ve tüm ürünü tamamen yerel/bağımlılıksız tutuyor. Kütüphane büyürse `VectorStore` trait'inin arkasına gerçek bir vektör DB eklemek yeterli.
