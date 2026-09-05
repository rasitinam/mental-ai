# Araştırma Kaynakları

`backend/crates/research-ingest`, `backend/config/default.toml`'daki `research_ingest.sources` listesiyle kontrol edilen şu kaynak/konu kombinasyonlarını destekliyor:

| Kaynak adı (config) | Yöntem | Sorgu odak noktası | Etiketler |
|---|---|---|---|
| `pubmed_general` | NCBI E-utilities (ESearch + EFetch) | Genel psikoloji/psikiyatri/ruh sağlığı | `mental-health` |
| `pubmed_ptsd` | NCBI E-utilities | PTSD, travma sonrası stres — tedavi/terapi/iyileşme | `ptsd`, `trauma` |
| `pubmed_bipolar` | NCBI E-utilities | Bipolar bozukluk — tedavi/yönetim/iyileşme | `bipolar` |
| `pubmed_anxiety_depression` | NCBI E-utilities | Anksiyete/depresyon — başa çıkma, BDT | `anxiety`, `depression` |
| `pubmed_recovery` | NCBI E-utilities | Yayınlanmış nitel araştırma: "lived experience" / "recovery narrative" | `recovery-story`, `lived-experience` |
| `who` | Ruh sağlığı haberleri RSS akışı | Genel duyurular | — |

Her biri `backend/apps/server/src/scheduler.rs::build_sources` içinde ayrı bir `PubMedSource` örneği; saklanan alanlar hepsinde aynı: başlık, özet (abstract) metni, PMID, yayın tarihi, `url`, etiketler.

## "İnsanların hikayeleri" neden sosyal medyadan toplanmıyor

Gerçek, isimli kişilerin blog/sosyal medya paylaşımlarını rızaları olmadan kazımak hem gizlilik ihlali hem de doğrulanamamış/yanıltıcı bilgi riski taşır — özellikle PTSD, bipolar gibi hassas konularda. Bunun yerine `pubmed_recovery` sorgusu, bu deneyimleri **zaten toplayıp anonimleştirmiş, hakem denetiminden geçmiş nitel araştırmaları** hedefler (örn. "kaç kişiyle görüşüldü, ortak temalar neydi" formatında yayınlanan çalışmalar). Bu, hem etik hem de daha güvenilir bir kaynak — ve zaten var olan PubMed altyapısını kullanır, ayrı bir scraping bileşeni gerektirmez.

## Kurallar

- **Sadece açık erişimli özet/metadata** saklanır. Telif hakkı taşıyan tam makale metni asla indirilmez veya saklanmaz.
- Her kayıt kaynağına geri bağlanan bir `url` taşır; uygulama içinde bir içgörü gösterilirken "kaynak: ..." şeklinde atıf yapılmalı.
- Yeni bir konu/kaynak eklerken: `research-ingest`'te `ResearchSource` trait'ini implemente edin ya da mevcut `PubMedSource`'a yeni bir sorgu ekleyin, `apps/server/src/scheduler.rs::build_sources`'a kaydedin, `config/default.toml`'daki `sources` listesine adını ekleyin.
- Kaynak seçerken API kullanım şartlarına (rate limit, atıf zorunluluğu) uyulmalı; PubMed E-utilities için NCBI'nin kullanım politikasına bakın.

## İçgörü kartları nasıl üretiliyor

Her ingest döngüsünden sonra (`apps/server/src/scheduler.rs`), o döngüde eklenen makalelerin ilk birkaçı (varsayılan: 5, maliyeti sınırlamak için) `analysis-engine::synthesize_insights` ile LLM'e gönderilir; model her biri için kısa, sade bir başlık + açıklama üretir (`llm-connector::prompts::insight_synthesis_instruction`). Sonuç `insights` tablosuna yazılır ve `/insights` üzerinden sunulur — kaynak makaleye `source_article_ids` ile geri bağlı kalır.

## Neden bir vektör veritabanı değil de SQLite?

`knowledge-base` crate'i embedding'leri SQLite'ta BLOB olarak saklayıp brute-force cosine similarity ile arıyor. Tek kullanıcının kişisel araştırma akışı ölçeğinde (binlerce, milyonlarca değil makale) bu yeterince hızlı ve tüm ürünü tamamen yerel/bağımlılıksız tutuyor. Kütüphane büyürse `VectorStore` trait'inin arkasına gerçek bir vektör DB eklemek yeterli.
