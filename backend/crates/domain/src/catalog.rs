//! The condition catalog the app browses by: DSM-5-TR-shaped categories and
//! the conditions under each. This is static reference data, not user data —
//! it lives in the binary rather than the database so it can't drift per
//! install, and so `slug`s are stable identifiers that other tables
//! (`insights.category`, `users.diagnoses`, `disorder_explainers.slug`) can
//! reference safely.
//!
//! Slugs are ASCII-only kebab-case; display names are Turkish, because that's
//! what the UI shows. Nothing here is a diagnostic instrument: it's a table of
//! contents for educational material and a way for someone to tell the app
//! what they already know about themselves.

use serde::Serialize;

// Serialize only: this table is sent to clients but never read back in —
// it's compiled-in constants, so there is nothing to deserialize it from.
#[derive(Debug, Clone, Serialize)]
pub struct DisorderCategory {
    pub slug: &'static str,
    pub name: &'static str,
    pub emoji: &'static str,
    /// Shown above the condition list when the category needs a caveat that
    /// the list alone would misrepresent.
    pub note: Option<&'static str>,
    pub disorders: &'static [Disorder],
}

#[derive(Debug, Clone, Serialize)]
pub struct Disorder {
    pub slug: &'static str,
    pub name: &'static str,
}

const fn d(slug: &'static str, name: &'static str) -> Disorder {
    Disorder { slug, name }
}

pub static CATEGORIES: &[DisorderCategory] = &[
    DisorderCategory {
        slug: "psikotik",
        name: "Psikotik bozukluklar",
        emoji: "🧠",
        note: None,
        disorders: &[
            d("sizofreni", "Şizofreni"),
            d("sizoaffektif", "Şizoaffektif bozukluk"),
            d("sizofreniform", "Şizofreniform bozukluk"),
            d("kisa-psikotik", "Kısa psikotik bozukluk"),
            d("sanrisal", "Sanrısal bozukluk"),
            d("sizotipal", "Şizotipal bozukluk"),
            d("diger-psikotik", "Diğer/belirtilmemiş psikotik bozukluklar"),
        ],
    },
    DisorderCategory {
        slug: "bipolar",
        name: "Bipolar ve ilişkili bozukluklar",
        emoji: "🔵",
        note: None,
        disorders: &[
            d("bipolar-1", "Bipolar I"),
            d("bipolar-2", "Bipolar II"),
            d("siklotimik", "Siklotimik bozukluk"),
            d("mani-hipomani", "Mani ve hipomani tabloları"),
            d("diger-bipolar", "Diğer/belirtilmemiş bipolar bozukluklar"),
        ],
    },
    DisorderCategory {
        slug: "depresif",
        name: "Depresif bozukluklar",
        emoji: "🟣",
        note: None,
        disorders: &[
            d("major-depresif", "Majör depresif bozukluk"),
            d("distimi", "Kalıcı depresif bozukluk (distimi)"),
            d("yikici-duygudurum", "Yıkıcı duygudurum düzenleyememe bozukluğu"),
            d("premenstruel-disforik", "Premenstrüel disforik bozukluk"),
            d("peripartum-depresyon", "Doğum sonrası/peripartum depresyon"),
            d("diger-depresif", "Diğer/belirtilmemiş depresif bozukluklar"),
        ],
    },
    DisorderCategory {
        slug: "anksiyete",
        name: "Anksiyete bozuklukları",
        emoji: "😰",
        note: None,
        disorders: &[
            d("yaygin-anksiyete", "Yaygın anksiyete bozukluğu (GAD)"),
            d("panik", "Panik bozukluğu"),
            d("agorafobi", "Agorafobi"),
            d("sosyal-anksiyete", "Sosyal anksiyete bozukluğu"),
            d("ozgul-fobi", "Özgül fobiler"),
            d("ayrilma-anksiyetesi", "Ayrılma anksiyetesi bozukluğu"),
            d("selektif-mutizm", "Seçici konuşmazlık (selektif mutizm)"),
            d("diger-anksiyete", "Diğer/belirtilmemiş anksiyete bozuklukları"),
        ],
    },
    DisorderCategory {
        slug: "travma-stres",
        name: "Travma ve stresle ilişkili bozukluklar",
        emoji: "🧨",
        note: None,
        disorders: &[
            d("tssb", "TSSB / PTSD"),
            d("karmasik-tssb", "Kompleks TSSB / CPTSD"),
            d("akut-stres", "Akut stres bozukluğu"),
            d("uyum-bozuklugu", "Uyum bozuklukları"),
            d("reaktif-baglanma", "Reaktif bağlanma bozukluğu"),
            d("disinhibe-sosyal-iliski", "Disinhibe sosyal ilişki bozukluğu"),
        ],
    },
    DisorderCategory {
        slug: "okb",
        name: "Obsesif-kompulsif ve ilişkili bozukluklar",
        emoji: "🧩",
        note: None,
        disorders: &[
            d("okb-ocd", "OKB / OCD"),
            d("beden-dismorfik", "Beden dismorfik bozukluğu"),
            d("biriktirme", "Biriktirme bozukluğu"),
            d("trikotillomani", "Trikotillomani"),
            d("deri-yolma", "Deri yolma bozukluğu"),
            d("diger-okb", "Diğer OKB ile ilişkili bozukluklar"),
        ],
    },
    DisorderCategory {
        slug: "dissosiyatif",
        name: "Dissosiyatif bozukluklar",
        emoji: "🪞",
        note: None,
        disorders: &[
            d("dissosiyatif-kimlik", "Dissosiyatif kimlik bozukluğu"),
            d("dissosiyatif-amnezi", "Dissosiyatif amnezi"),
            d("depersonalizasyon", "Depersonalizasyon/derealizasyon bozukluğu"),
            d("diger-dissosiyatif", "Diğer dissosiyatif bozukluklar"),
        ],
    },
    DisorderCategory {
        slug: "kisilik",
        name: "Kişilik bozuklukları",
        emoji: "🧍",
        note: None,
        disorders: &[
            d("borderline", "Borderline (sınırda) kişilik bozukluğu"),
            d("antisosyal", "Antisosyal kişilik bozukluğu"),
            d("narsistik", "Narsistik kişilik bozukluğu"),
            d("kacingan", "Kaçıngan kişilik bozukluğu"),
            d("bagimli-kisilik", "Bağımlı kişilik bozukluğu"),
            d("okb-kisilik", "Obsesif-kompulsif kişilik bozukluğu"),
            d("paranoid", "Paranoid kişilik bozukluğu"),
            d("sizoid", "Şizoid kişilik bozukluğu"),
            d("sizotipal-kisilik", "Şizotipal kişilik bozukluğu"),
            d("diger-kisilik", "Diğer/belirtilmemiş kişilik bozuklukları"),
        ],
    },
    DisorderCategory {
        slug: "yeme",
        name: "Beslenme ve yeme bozuklukları",
        emoji: "🍽️",
        note: None,
        disorders: &[
            d("anoreksiya", "Anoreksiya nervoza"),
            d("bulimiya", "Bulimiya nervoza"),
            d("tikinircasina-yeme", "Tıkınırcasına yeme bozukluğu"),
            d("arfid", "ARFID"),
            d("pika", "Pika"),
            d("ruminasyon", "Ruminasyon bozukluğu"),
            d("diger-yeme", "Diğer beslenme/yeme bozuklukları"),
        ],
    },
    DisorderCategory {
        slug: "madde-bagimlilik",
        name: "Madde kullanım ve bağımlılık bozuklukları",
        emoji: "🍺",
        note: None,
        disorders: &[
            d("alkol", "Alkol kullanım bozukluğu"),
            d("opioid", "Opioid kullanım bozukluğu"),
            d("kokain", "Kokain kullanım bozukluğu"),
            d("amfetamin", "Amfetamin/metamfetamin kullanım bozukluğu"),
            d("kannabis", "Kannabis kullanım bozukluğu"),
            d("sedatif", "Sedatif/hipnotik kullanım bozukluğu"),
            d("halusinojen", "Halüsinojen kullanım bozukluğu"),
            d("tutun", "Tütün kullanım bozukluğu"),
            d("coklu-madde", "Çoklu madde kullanımı"),
            d("kumar", "Kumar oynama bozukluğu"),
        ],
    },
    DisorderCategory {
        slug: "uyku",
        name: "Uyku-uyanıklık bozuklukları",
        emoji: "😴",
        note: None,
        disorders: &[
            d("insomni", "İnsomni"),
            d("hipersomnolans", "Hipersomnolans"),
            d("narkolepsi", "Narkolepsi"),
            d("uyku-apnesi", "Obstrüktif uyku apnesi"),
            d("sirkadiyen-ritim", "Sirkadiyen ritim uyku-uyanıklık bozuklukları"),
            d("parasomni", "Parasomniler"),
            d("kabus", "Kabus bozukluğu"),
            d("huzursuz-bacak", "Huzursuz bacak sendromu"),
        ],
    },
    DisorderCategory {
        slug: "norogelisimsel",
        name: "Nörogelişimsel bozukluklar",
        emoji: "🧠",
        note: None,
        disorders: &[
            d("otizm", "Otizm spektrum bozukluğu"),
            d("dehb", "DEHB"),
            d("entelektuel-gelisimsel", "Entelektüel gelişimsel bozukluk"),
            d("ogrenme-bozuklugu", "Özgül öğrenme bozukluğu"),
            d("iletisim-bozuklugu", "İletişim bozuklukları"),
            d("motor-bozukluk", "Motor bozukluklar"),
            d("tourette", "Tourette bozukluğu"),
            d("diger-tik", "Diğer tik bozuklukları"),
        ],
    },
    DisorderCategory {
        slug: "norobilissel",
        name: "Nörobilişsel bozukluklar",
        emoji: "🧠",
        note: None,
        disorders: &[
            d("deliryum", "Deliryum"),
            d("alzheimer", "Alzheimer hastalığına bağlı majör nörobilişsel bozukluk"),
            d("vaskuler-norobilissel", "Vasküler nörobilişsel bozukluk"),
            d("lewy-demans", "Lewy cisimcikli demans"),
            d("frontotemporal", "Frontotemporal nörobilişsel bozukluk"),
            d("parkinson-norobilissel", "Parkinson hastalığına bağlı nörobilişsel bozukluk"),
            d("tbi-norobilissel", "Travmatik beyin hasarına bağlı nörobilişsel bozukluklar"),
        ],
    },
    DisorderCategory {
        slug: "somatik",
        name: "Somatik belirti ve ilişkili bozukluklar",
        emoji: "🧍",
        note: None,
        disorders: &[
            d("somatik-belirti", "Somatik belirti bozukluğu"),
            d("hastalik-kaygisi", "Hastalık kaygısı bozukluğu"),
            d("konversiyon", "Konversiyon bozukluğu / fonksiyonel nörolojik belirti bozukluğu"),
            d("yapay-bozukluk", "Yapay bozukluk"),
            d("diger-somatik", "Diğer ilişkili bozukluklar"),
        ],
    },
    DisorderCategory {
        slug: "cinsel-islev",
        name: "Cinsel işlev bozuklukları",
        emoji: "🫂",
        note: None,
        disorders: &[
            d("erektil", "Erektil bozukluk"),
            d("erken-bosalma", "Erken boşalma"),
            d("gecikmis-bosalma", "Gecikmiş boşalma"),
            d("kadin-orgazm", "Kadında orgazm bozukluğu"),
            d("cinsel-ilgi-uyarilma", "Cinsel ilgi/uyarılma bozuklukları"),
            d("genito-pelvik-agri", "Genito-pelvik ağrı/penetrasyon bozukluğu"),
            d("madde-kaynakli-cinsel", "Madde/ilaç kaynaklı cinsel işlev bozuklukları"),
        ],
    },
    DisorderCategory {
        slug: "parafilik",
        name: "Parafilik bozukluklar",
        emoji: "⚠️",
        note: Some(
            "Alışılmadık bir cinsel ilgi ya da fantezi tek başına psikiyatrik bir bozukluk değildir. \
             Klinik tanı için belirli ölçütlerin karşılanması gerekir; bu başlıklar yalnızca \
             bilgilendirme amaçlıdır.",
        ),
        disorders: &[
            d("voyeuristik", "Voyeuristik bozukluk"),
            d("teshircilik", "Teşhircilik bozukluğu"),
            d("frotteuristik", "Frotteuristik bozukluk"),
            d("cinsel-mazosizm", "Cinsel mazoşizm bozukluğu"),
            d("cinsel-sadizm", "Cinsel sadizm bozukluğu"),
            d("pedofilik", "Pedofilik bozukluk"),
            d("fetisistik", "Fetişistik bozukluk"),
            d("transvestik", "Transvestik bozukluk"),
        ],
    },
    DisorderCategory {
        slug: "eliminasyon",
        name: "Eliminasyon bozuklukları",
        emoji: "🚽",
        note: None,
        disorders: &[
            d("enurezis", "Enürezis"),
            d("enkoprezis", "Enkoprezis"),
            d("diger-eliminasyon", "Diğer eliminasyon bozuklukları"),
        ],
    },
    DisorderCategory {
        slug: "durtu-kontrol",
        name: "Yıkıcı davranış ve dürtü kontrolü bozuklukları",
        emoji: "😡",
        note: None,
        disorders: &[
            d("karsit-olma", "Karşıt olma-karşı gelme bozukluğu"),
            d("davranim-bozuklugu", "Davranım bozukluğu"),
            d("aralikli-patlayici", "Aralıklı patlayıcı bozukluk"),
            d("kleptomani", "Kleptomani"),
            d("piromani", "Piromani"),
        ],
    },
    DisorderCategory {
        slug: "bedensel-diger",
        name: "Bedensel belirtilerle ilişkili diğer durumlar",
        emoji: "🤕",
        note: None,
        disorders: &[
            d("psikolojik-faktor-tibbi", "Psikolojik faktörlerin tıbbi durumu etkilediği tablolar"),
            d("fonksiyonel-norolojik", "Fonksiyonel nörolojik belirtiler"),
            d("kronik-agri-psikolojik", "Kronik ağrı ile ilişkili psikolojik tablolar"),
        ],
    },
    DisorderCategory {
        slug: "madde-kaynakli",
        name: "Madde/ilaç kaynaklı ruhsal bozukluklar",
        emoji: "🧪",
        note: None,
        disorders: &[
            d("madde-depresif", "Madde kaynaklı depresif bozukluk"),
            d("madde-anksiyete", "Madde kaynaklı anksiyete"),
            d("madde-psikotik", "Madde kaynaklı psikotik bozukluk"),
            d("madde-bipolar", "Madde kaynaklı bipolar belirtiler"),
            d("madde-okb", "Madde kaynaklı obsesif-kompulsif belirtiler"),
            d("yoksunluk-intoksikasyon", "Yoksunluk ve intoksikasyonla ilişkili ruhsal tablolar"),
        ],
    },
];

pub fn category(slug: &str) -> Option<&'static DisorderCategory> {
    CATEGORIES.iter().find(|c| c.slug == slug)
}

/// Resolves a condition slug to its category and entry. Used to validate
/// anything user- or model-supplied before it's written to the database.
pub fn disorder(slug: &str) -> Option<(&'static DisorderCategory, &'static Disorder)> {
    CATEGORIES.iter().find_map(|c| {
        c.disorders
            .iter()
            .find(|entry| entry.slug == slug)
            .map(|entry| (c, entry))
    })
}

pub fn is_category(slug: &str) -> bool {
    category(slug).is_some()
}

/// Comma-separated `slug (Name)` list, for prompting a model to pick one.
pub fn category_menu() -> String {
    CATEGORIES
        .iter()
        .map(|c| format!("{} ({})", c.slug, c.name))
        .collect::<Vec<_>>()
        .join(", ")
}
