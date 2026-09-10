//! The condition catalog the app browses by: DSM-5-TR-shaped categories and
//! the conditions under each. This is static reference data, not user data —
//! it lives in the binary rather than the database so it can't drift per
//! install, and so `slug`s are stable identifiers that other tables
//! (`insights.category`, `users.diagnoses`, `disorder_explainers.slug`) can
//! reference safely.
//!
//! Every entry carries both a Turkish and an English display name. Slugs stay
//! Turkish-derived ASCII kebab-case regardless of display language — they are
//! identifiers already written into user rows, so they must never move. The
//! route layer picks a language and serves [`LocalizedCategory`]; nothing
//! downstream of that needs to know a second language exists.

use serde::Serialize;

#[derive(Debug, Clone)]
pub struct DisorderCategory {
    pub slug: &'static str,
    pub name: &'static str,
    pub name_en: &'static str,
    pub emoji: &'static str,
    /// Shown above the condition list when the category needs a caveat that
    /// the list alone would misrepresent.
    pub note: Option<&'static str>,
    pub note_en: Option<&'static str>,
    pub disorders: &'static [Disorder],
}

#[derive(Debug, Clone)]
pub struct Disorder {
    pub slug: &'static str,
    pub name: &'static str,
    pub name_en: &'static str,
}

impl Disorder {
    /// The display name in `language`, falling back to Turkish for any code
    /// the catalog doesn't carry a translation for — a missing translation
    /// should degrade to "shown in the other language", never to blank.
    pub fn name_in(&self, language: &str) -> &'static str {
        match language {
            "en" => self.name_en,
            _ => self.name,
        }
    }
}

impl DisorderCategory {
    pub fn name_in(&self, language: &str) -> &'static str {
        match language {
            "en" => self.name_en,
            _ => self.name,
        }
    }

    pub fn note_in(&self, language: &str) -> Option<&'static str> {
        match language {
            "en" => self.note_en,
            _ => self.note,
        }
    }
}

/// What the API actually sends: one language's worth of the tree, in the
/// same shape the client has always received.
#[derive(Debug, Clone, Serialize)]
pub struct LocalizedCategory {
    pub slug: &'static str,
    pub name: &'static str,
    pub emoji: &'static str,
    pub note: Option<&'static str>,
    pub disorders: Vec<LocalizedDisorder>,
}

#[derive(Debug, Clone, Serialize)]
pub struct LocalizedDisorder {
    pub slug: &'static str,
    pub name: &'static str,
}

/// The whole tree in one language.
pub fn localized(language: &str) -> Vec<LocalizedCategory> {
    CATEGORIES
        .iter()
        .map(|c| LocalizedCategory {
            slug: c.slug,
            name: c.name_in(language),
            emoji: c.emoji,
            note: c.note_in(language),
            disorders: c
                .disorders
                .iter()
                .map(|entry| LocalizedDisorder { slug: entry.slug, name: entry.name_in(language) })
                .collect(),
        })
        .collect()
}

const fn d(slug: &'static str, name: &'static str, name_en: &'static str) -> Disorder {
    Disorder { slug, name, name_en }
}

pub static CATEGORIES: &[DisorderCategory] = &[
    DisorderCategory {
        slug: "psikotik",
        name: "Psikotik bozukluklar",
        name_en: "Psychotic disorders",
        emoji: "🧠",
        note: None,
        note_en: None,
        disorders: &[
            d("sizofreni", "Şizofreni", "Schizophrenia"),
            d("sizoaffektif", "Şizoaffektif bozukluk", "Schizoaffective disorder"),
            d("sizofreniform", "Şizofreniform bozukluk", "Schizophreniform disorder"),
            d("kisa-psikotik", "Kısa psikotik bozukluk", "Brief psychotic disorder"),
            d("sanrisal", "Sanrısal bozukluk", "Delusional disorder"),
            d("sizotipal", "Şizotipal bozukluk", "Schizotypal disorder"),
            d(
                "diger-psikotik",
                "Diğer/belirtilmemiş psikotik bozukluklar",
                "Other/unspecified psychotic disorders",
            ),
        ],
    },
    DisorderCategory {
        slug: "bipolar",
        name: "Bipolar ve ilişkili bozukluklar",
        name_en: "Bipolar and related disorders",
        emoji: "🔵",
        note: None,
        note_en: None,
        disorders: &[
            d("bipolar-1", "Bipolar I", "Bipolar I"),
            d("bipolar-2", "Bipolar II", "Bipolar II"),
            d("siklotimik", "Siklotimik bozukluk", "Cyclothymic disorder"),
            d("mani-hipomani", "Mani ve hipomani tabloları", "Mania and hypomania"),
            d(
                "diger-bipolar",
                "Diğer/belirtilmemiş bipolar bozukluklar",
                "Other/unspecified bipolar disorders",
            ),
        ],
    },
    DisorderCategory {
        slug: "depresif",
        name: "Depresif bozukluklar",
        name_en: "Depressive disorders",
        emoji: "🟣",
        note: None,
        note_en: None,
        disorders: &[
            d("major-depresif", "Majör depresif bozukluk", "Major depressive disorder"),
            d(
                "distimi",
                "Kalıcı depresif bozukluk (distimi)",
                "Persistent depressive disorder (dysthymia)",
            ),
            d(
                "yikici-duygudurum",
                "Yıkıcı duygudurum düzenleyememe bozukluğu",
                "Disruptive mood dysregulation disorder",
            ),
            d(
                "premenstruel-disforik",
                "Premenstrüel disforik bozukluk",
                "Premenstrual dysphoric disorder",
            ),
            d(
                "peripartum-depresyon",
                "Doğum sonrası/peripartum depresyon",
                "Postpartum/peripartum depression",
            ),
            d(
                "diger-depresif",
                "Diğer/belirtilmemiş depresif bozukluklar",
                "Other/unspecified depressive disorders",
            ),
        ],
    },
    DisorderCategory {
        slug: "anksiyete",
        name: "Anksiyete bozuklukları",
        name_en: "Anxiety disorders",
        emoji: "😰",
        note: None,
        note_en: None,
        disorders: &[
            d(
                "yaygin-anksiyete",
                "Yaygın anksiyete bozukluğu (GAD)",
                "Generalized anxiety disorder (GAD)",
            ),
            d("panik", "Panik bozukluğu", "Panic disorder"),
            d("agorafobi", "Agorafobi", "Agoraphobia"),
            d("sosyal-anksiyete", "Sosyal anksiyete bozukluğu", "Social anxiety disorder"),
            d("ozgul-fobi", "Özgül fobiler", "Specific phobias"),
            d("ayrilma-anksiyetesi", "Ayrılma anksiyetesi bozukluğu", "Separation anxiety disorder"),
            d("selektif-mutizm", "Seçici konuşmazlık (selektif mutizm)", "Selective mutism"),
            d(
                "diger-anksiyete",
                "Diğer/belirtilmemiş anksiyete bozuklukları",
                "Other/unspecified anxiety disorders",
            ),
        ],
    },
    DisorderCategory {
        slug: "travma-stres",
        name: "Travma ve stresle ilişkili bozukluklar",
        name_en: "Trauma- and stressor-related disorders",
        emoji: "🧨",
        note: None,
        note_en: None,
        disorders: &[
            d("tssb", "TSSB / PTSD", "PTSD"),
            d("karmasik-tssb", "Kompleks TSSB / CPTSD", "Complex PTSD (CPTSD)"),
            d("akut-stres", "Akut stres bozukluğu", "Acute stress disorder"),
            d("uyum-bozuklugu", "Uyum bozuklukları", "Adjustment disorders"),
            d("reaktif-baglanma", "Reaktif bağlanma bozukluğu", "Reactive attachment disorder"),
            d(
                "disinhibe-sosyal-iliski",
                "Disinhibe sosyal ilişki bozukluğu",
                "Disinhibited social engagement disorder",
            ),
        ],
    },
    DisorderCategory {
        slug: "okb",
        name: "Obsesif-kompulsif ve ilişkili bozukluklar",
        name_en: "Obsessive-compulsive and related disorders",
        emoji: "🧩",
        note: None,
        note_en: None,
        disorders: &[
            d("okb-ocd", "OKB / OCD", "OCD"),
            d("beden-dismorfik", "Beden dismorfik bozukluğu", "Body dysmorphic disorder"),
            d("biriktirme", "Biriktirme bozukluğu", "Hoarding disorder"),
            d("trikotillomani", "Trikotillomani", "Trichotillomania (hair-pulling disorder)"),
            d("deri-yolma", "Deri yolma bozukluğu", "Excoriation (skin-picking) disorder"),
            d(
                "diger-okb",
                "Diğer OKB ile ilişkili bozukluklar",
                "Other obsessive-compulsive related disorders",
            ),
        ],
    },
    DisorderCategory {
        slug: "dissosiyatif",
        name: "Dissosiyatif bozukluklar",
        name_en: "Dissociative disorders",
        emoji: "🪞",
        note: None,
        note_en: None,
        disorders: &[
            d("dissosiyatif-kimlik", "Dissosiyatif kimlik bozukluğu", "Dissociative identity disorder"),
            d("dissosiyatif-amnezi", "Dissosiyatif amnezi", "Dissociative amnesia"),
            d(
                "depersonalizasyon",
                "Depersonalizasyon/derealizasyon bozukluğu",
                "Depersonalization/derealization disorder",
            ),
            d("diger-dissosiyatif", "Diğer dissosiyatif bozukluklar", "Other dissociative disorders"),
        ],
    },
    DisorderCategory {
        slug: "kisilik",
        name: "Kişilik bozuklukları",
        name_en: "Personality disorders",
        emoji: "🧍",
        note: None,
        note_en: None,
        disorders: &[
            d(
                "borderline",
                "Borderline (sınırda) kişilik bozukluğu",
                "Borderline personality disorder",
            ),
            d("antisosyal", "Antisosyal kişilik bozukluğu", "Antisocial personality disorder"),
            d("narsistik", "Narsistik kişilik bozukluğu", "Narcissistic personality disorder"),
            d("kacingan", "Kaçıngan kişilik bozukluğu", "Avoidant personality disorder"),
            d("bagimli-kisilik", "Bağımlı kişilik bozukluğu", "Dependent personality disorder"),
            d(
                "okb-kisilik",
                "Obsesif-kompulsif kişilik bozukluğu",
                "Obsessive-compulsive personality disorder",
            ),
            d("paranoid", "Paranoid kişilik bozukluğu", "Paranoid personality disorder"),
            d("sizoid", "Şizoid kişilik bozukluğu", "Schizoid personality disorder"),
            d("sizotipal-kisilik", "Şizotipal kişilik bozukluğu", "Schizotypal personality disorder"),
            d(
                "diger-kisilik",
                "Diğer/belirtilmemiş kişilik bozuklukları",
                "Other/unspecified personality disorders",
            ),
        ],
    },
    DisorderCategory {
        slug: "yeme",
        name: "Beslenme ve yeme bozuklukları",
        name_en: "Feeding and eating disorders",
        emoji: "🍽️",
        note: None,
        note_en: None,
        disorders: &[
            d("anoreksiya", "Anoreksiya nervoza", "Anorexia nervosa"),
            d("bulimiya", "Bulimiya nervoza", "Bulimia nervosa"),
            d("tikinircasina-yeme", "Tıkınırcasına yeme bozukluğu", "Binge-eating disorder"),
            d("arfid", "ARFID", "ARFID (avoidant/restrictive food intake disorder)"),
            d("pika", "Pika", "Pica"),
            d("ruminasyon", "Ruminasyon bozukluğu", "Rumination disorder"),
            d("diger-yeme", "Diğer beslenme/yeme bozuklukları", "Other feeding/eating disorders"),
        ],
    },
    DisorderCategory {
        slug: "madde-bagimlilik",
        name: "Madde kullanım ve bağımlılık bozuklukları",
        name_en: "Substance use and addictive disorders",
        emoji: "🍺",
        note: None,
        note_en: None,
        disorders: &[
            d("alkol", "Alkol kullanım bozukluğu", "Alcohol use disorder"),
            d("opioid", "Opioid kullanım bozukluğu", "Opioid use disorder"),
            d("kokain", "Kokain kullanım bozukluğu", "Cocaine use disorder"),
            d(
                "amfetamin",
                "Amfetamin/metamfetamin kullanım bozukluğu",
                "Amphetamine/methamphetamine use disorder",
            ),
            d("kannabis", "Kannabis kullanım bozukluğu", "Cannabis use disorder"),
            d("sedatif", "Sedatif/hipnotik kullanım bozukluğu", "Sedative/hypnotic use disorder"),
            d("halusinojen", "Halüsinojen kullanım bozukluğu", "Hallucinogen use disorder"),
            d("tutun", "Tütün kullanım bozukluğu", "Tobacco use disorder"),
            d("coklu-madde", "Çoklu madde kullanımı", "Polysubstance use"),
            d("kumar", "Kumar oynama bozukluğu", "Gambling disorder"),
        ],
    },
    DisorderCategory {
        slug: "uyku",
        name: "Uyku-uyanıklık bozuklukları",
        name_en: "Sleep-wake disorders",
        emoji: "😴",
        note: None,
        note_en: None,
        disorders: &[
            d("insomni", "İnsomni", "Insomnia"),
            d("hipersomnolans", "Hipersomnolans", "Hypersomnolence"),
            d("narkolepsi", "Narkolepsi", "Narcolepsy"),
            d("uyku-apnesi", "Obstrüktif uyku apnesi", "Obstructive sleep apnea"),
            d(
                "sirkadiyen-ritim",
                "Sirkadiyen ritim uyku-uyanıklık bozuklukları",
                "Circadian rhythm sleep-wake disorders",
            ),
            d("parasomni", "Parasomniler", "Parasomnias"),
            d("kabus", "Kabus bozukluğu", "Nightmare disorder"),
            d("huzursuz-bacak", "Huzursuz bacak sendromu", "Restless legs syndrome"),
        ],
    },
    DisorderCategory {
        slug: "norogelisimsel",
        name: "Nörogelişimsel bozukluklar",
        name_en: "Neurodevelopmental disorders",
        emoji: "🧠",
        note: None,
        note_en: None,
        disorders: &[
            d("otizm", "Otizm spektrum bozukluğu", "Autism spectrum disorder"),
            d("dehb", "DEHB", "ADHD"),
            d(
                "entelektuel-gelisimsel",
                "Entelektüel gelişimsel bozukluk",
                "Intellectual developmental disorder",
            ),
            d("ogrenme-bozuklugu", "Özgül öğrenme bozukluğu", "Specific learning disorder"),
            d("iletisim-bozuklugu", "İletişim bozuklukları", "Communication disorders"),
            d("motor-bozukluk", "Motor bozukluklar", "Motor disorders"),
            d("tourette", "Tourette bozukluğu", "Tourette's disorder"),
            d("diger-tik", "Diğer tik bozuklukları", "Other tic disorders"),
        ],
    },
    DisorderCategory {
        slug: "norobilissel",
        name: "Nörobilişsel bozukluklar",
        name_en: "Neurocognitive disorders",
        emoji: "🧠",
        note: None,
        note_en: None,
        disorders: &[
            d("deliryum", "Deliryum", "Delirium"),
            d(
                "alzheimer",
                "Alzheimer hastalığına bağlı majör nörobilişsel bozukluk",
                "Major neurocognitive disorder due to Alzheimer's disease",
            ),
            d(
                "vaskuler-norobilissel",
                "Vasküler nörobilişsel bozukluk",
                "Vascular neurocognitive disorder",
            ),
            d("lewy-demans", "Lewy cisimcikli demans", "Dementia with Lewy bodies"),
            d(
                "frontotemporal",
                "Frontotemporal nörobilişsel bozukluk",
                "Frontotemporal neurocognitive disorder",
            ),
            d(
                "parkinson-norobilissel",
                "Parkinson hastalığına bağlı nörobilişsel bozukluk",
                "Neurocognitive disorder due to Parkinson's disease",
            ),
            d(
                "tbi-norobilissel",
                "Travmatik beyin hasarına bağlı nörobilişsel bozukluklar",
                "Neurocognitive disorders due to traumatic brain injury",
            ),
        ],
    },
    DisorderCategory {
        slug: "somatik",
        name: "Somatik belirti ve ilişkili bozukluklar",
        name_en: "Somatic symptom and related disorders",
        emoji: "🧍",
        note: None,
        note_en: None,
        disorders: &[
            d("somatik-belirti", "Somatik belirti bozukluğu", "Somatic symptom disorder"),
            d("hastalik-kaygisi", "Hastalık kaygısı bozukluğu", "Illness anxiety disorder"),
            d(
                "konversiyon",
                "Konversiyon bozukluğu / fonksiyonel nörolojik belirti bozukluğu",
                "Conversion disorder (functional neurological symptom disorder)",
            ),
            d("yapay-bozukluk", "Yapay bozukluk", "Factitious disorder"),
            d("diger-somatik", "Diğer ilişkili bozukluklar", "Other related disorders"),
        ],
    },
    DisorderCategory {
        slug: "cinsel-islev",
        name: "Cinsel işlev bozuklukları",
        name_en: "Sexual dysfunctions",
        emoji: "🫂",
        note: None,
        note_en: None,
        disorders: &[
            d("erektil", "Erektil bozukluk", "Erectile disorder"),
            d("erken-bosalma", "Erken boşalma", "Premature ejaculation"),
            d("gecikmis-bosalma", "Gecikmiş boşalma", "Delayed ejaculation"),
            d("kadin-orgazm", "Kadında orgazm bozukluğu", "Female orgasmic disorder"),
            d(
                "cinsel-ilgi-uyarilma",
                "Cinsel ilgi/uyarılma bozuklukları",
                "Sexual interest/arousal disorders",
            ),
            d(
                "genito-pelvik-agri",
                "Genito-pelvik ağrı/penetrasyon bozukluğu",
                "Genito-pelvic pain/penetration disorder",
            ),
            d(
                "madde-kaynakli-cinsel",
                "Madde/ilaç kaynaklı cinsel işlev bozuklukları",
                "Substance/medication-induced sexual dysfunction",
            ),
        ],
    },
    DisorderCategory {
        slug: "parafilik",
        name: "Parafilik bozukluklar",
        name_en: "Paraphilic disorders",
        emoji: "⚠️",
        note: Some(
            "Alışılmadık bir cinsel ilgi ya da fantezi tek başına psikiyatrik bir bozukluk değildir. \
             Klinik tanı için belirli ölçütlerin karşılanması gerekir; bu başlıklar yalnızca \
             bilgilendirme amaçlıdır.",
        ),
        note_en: Some(
            "An unusual sexual interest or fantasy is not a psychiatric disorder on its own. A \
             clinical diagnosis requires specific criteria to be met; these entries are for \
             information only.",
        ),
        disorders: &[
            d("voyeuristik", "Voyeuristik bozukluk", "Voyeuristic disorder"),
            d("teshircilik", "Teşhircilik bozukluğu", "Exhibitionistic disorder"),
            d("frotteuristik", "Frotteuristik bozukluk", "Frotteuristic disorder"),
            d("cinsel-mazosizm", "Cinsel mazoşizm bozukluğu", "Sexual masochism disorder"),
            d("cinsel-sadizm", "Cinsel sadizm bozukluğu", "Sexual sadism disorder"),
            d("pedofilik", "Pedofilik bozukluk", "Pedophilic disorder"),
            d("fetisistik", "Fetişistik bozukluk", "Fetishistic disorder"),
            d("transvestik", "Transvestik bozukluk", "Transvestic disorder"),
        ],
    },
    DisorderCategory {
        slug: "eliminasyon",
        name: "Eliminasyon bozuklukları",
        name_en: "Elimination disorders",
        emoji: "🚽",
        note: None,
        note_en: None,
        disorders: &[
            d("enurezis", "Enürezis", "Enuresis"),
            d("enkoprezis", "Enkoprezis", "Encopresis"),
            d("diger-eliminasyon", "Diğer eliminasyon bozuklukları", "Other elimination disorders"),
        ],
    },
    DisorderCategory {
        slug: "durtu-kontrol",
        name: "Yıkıcı davranış ve dürtü kontrolü bozuklukları",
        name_en: "Disruptive, impulse-control and conduct disorders",
        emoji: "😡",
        note: None,
        note_en: None,
        disorders: &[
            d("karsit-olma", "Karşıt olma-karşı gelme bozukluğu", "Oppositional defiant disorder"),
            d("davranim-bozuklugu", "Davranım bozukluğu", "Conduct disorder"),
            d("aralikli-patlayici", "Aralıklı patlayıcı bozukluk", "Intermittent explosive disorder"),
            d("kleptomani", "Kleptomani", "Kleptomania"),
            d("piromani", "Piromani", "Pyromania"),
        ],
    },
    DisorderCategory {
        slug: "bedensel-diger",
        name: "Bedensel belirtilerle ilişkili diğer durumlar",
        name_en: "Other conditions involving physical symptoms",
        emoji: "🤕",
        note: None,
        note_en: None,
        disorders: &[
            d(
                "psikolojik-faktor-tibbi",
                "Psikolojik faktörlerin tıbbi durumu etkilediği tablolar",
                "Psychological factors affecting other medical conditions",
            ),
            d(
                "fonksiyonel-norolojik",
                "Fonksiyonel nörolojik belirtiler",
                "Functional neurological symptoms",
            ),
            d(
                "kronik-agri-psikolojik",
                "Kronik ağrı ile ilişkili psikolojik tablolar",
                "Psychological presentations related to chronic pain",
            ),
        ],
    },
    DisorderCategory {
        slug: "madde-kaynakli",
        name: "Madde/ilaç kaynaklı ruhsal bozukluklar",
        name_en: "Substance/medication-induced mental disorders",
        emoji: "🧪",
        note: None,
        note_en: None,
        disorders: &[
            d(
                "madde-depresif",
                "Madde kaynaklı depresif bozukluk",
                "Substance-induced depressive disorder",
            ),
            d("madde-anksiyete", "Madde kaynaklı anksiyete", "Substance-induced anxiety"),
            d(
                "madde-psikotik",
                "Madde kaynaklı psikotik bozukluk",
                "Substance-induced psychotic disorder",
            ),
            d(
                "madde-bipolar",
                "Madde kaynaklı bipolar belirtiler",
                "Substance-induced bipolar symptoms",
            ),
            d(
                "madde-okb",
                "Madde kaynaklı obsesif-kompulsif belirtiler",
                "Substance-induced obsessive-compulsive symptoms",
            ),
            d(
                "yoksunluk-intoksikasyon",
                "Yoksunluk ve intoksikasyonla ilişkili ruhsal tablolar",
                "Mental presentations related to withdrawal and intoxication",
            ),
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
/// Turkish regardless of the reader's language: this goes into a prompt, not
/// onto a screen, and the slug is what comes back either way.
pub fn category_menu() -> String {
    CATEGORIES
        .iter()
        .map(|c| format!("{} ({})", c.slug, c.name))
        .collect::<Vec<_>>()
        .join(", ")
}
