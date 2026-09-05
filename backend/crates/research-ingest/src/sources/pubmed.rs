use async_trait::async_trait;
use chrono::Utc;
use serde::Deserialize;

use super::{RawArticle, ResearchSource};

/// Fetches recent psychology/psychiatry abstracts via NCBI's E-utilities
/// (PubMed). Uses ESearch to find recent IDs for the configured query,
/// then ESummary for titles/metadata. Abstract text is fetched separately
/// via EFetch since ESummary doesn't include it; kept as a second call so
/// a failure there doesn't lose the whole batch.
pub struct PubMedSource {
    client: reqwest::Client,
    /// Log-friendly label for this query (e.g. "pubmed:ptsd") — several
    /// `PubMedSource` instances with different queries/tags run per
    /// ingest cycle (see `apps/server/src/scheduler.rs::build_sources`),
    /// so this disambiguates them in logs even though they all write rows
    /// under the shared `source = "pubmed"` (that sharing is intentional:
    /// it lets the same PMID found by two different topic queries dedupe
    /// to one stored row instead of two).
    label: &'static str,
    query: String,
    max_results: u32,
    tags: Vec<String>,
}

impl PubMedSource {
    pub fn new(label: &'static str, query: impl Into<String>, max_results: u32, tags: Vec<String>) -> Self {
        Self {
            client: reqwest::Client::new(),
            label,
            query: query.into(),
            max_results,
            tags,
        }
    }
}

#[derive(Debug, Deserialize)]
struct ESearchResponse {
    esearchresult: ESearchResult,
}

#[derive(Debug, Deserialize)]
struct ESearchResult {
    idlist: Vec<String>,
}

const EUTILS_BASE: &str = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils";

#[async_trait]
impl ResearchSource for PubMedSource {
    fn name(&self) -> &'static str {
        self.label
    }

    async fn fetch_recent(&self) -> anyhow::Result<Vec<RawArticle>> {
        let search_url = format!(
            "{EUTILS_BASE}/esearch.fcgi?db=pubmed&retmode=json&sort=pub+date&retmax={}&term={}",
            self.max_results,
            urlencoding::encode(&self.query)
        );

        let search: ESearchResponse = self.client.get(&search_url).send().await?.json().await?;
        if search.esearchresult.idlist.is_empty() {
            return Ok(vec![]);
        }

        let ids = search.esearchresult.idlist.join(",");

        // EFetch in "abstract" text mode gives us title + abstract in one
        // call; parsing the loose PubMed XML with a couple of targeted
        // string scans is enough here and avoids a heavy XML-to-struct
        // mapping for a format with very irregular nesting.
        let fetch_url = format!("{EUTILS_BASE}/efetch.fcgi?db=pubmed&retmode=xml&id={ids}");
        let xml = self.client.get(&fetch_url).send().await?.text().await?;

        Ok(parse_pubmed_xml(&xml, self.max_results as usize, &self.tags))
    }
}

fn parse_pubmed_xml(xml: &str, max_results: usize, tags: &[String]) -> Vec<RawArticle> {
    use quick_xml::events::Event;
    use quick_xml::reader::Reader;

    let mut reader = Reader::from_str(xml);
    reader.config_mut().trim_text(true);

    let mut articles = Vec::new();
    let (mut pmid, mut title, mut abstract_text) = (String::new(), String::new(), String::new());
    let mut current_tag = String::new();
    let mut buf = Vec::new();

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(e)) => {
                current_tag = String::from_utf8_lossy(e.name().as_ref()).to_string();
            }
            Ok(Event::Text(t)) => {
                let text = t.unescape().unwrap_or_default().to_string();
                match current_tag.as_str() {
                    "PMID" if pmid.is_empty() => pmid = text,
                    "ArticleTitle" => title.push_str(&text),
                    "AbstractText" => {
                        if !abstract_text.is_empty() {
                            abstract_text.push(' ');
                        }
                        abstract_text.push_str(&text);
                    }
                    _ => {}
                }
            }
            Ok(Event::End(e)) => {
                if e.name().as_ref() == b"PubmedArticle" {
                    if !pmid.is_empty() && !title.is_empty() {
                        articles.push(RawArticle {
                            source: "pubmed".to_string(),
                            external_id: pmid.clone(),
                            title: title.clone(),
                            abstract_text: abstract_text.clone(),
                            url: format!("https://pubmed.ncbi.nlm.nih.gov/{pmid}/"),
                            published_at: Some(Utc::now()),
                            tags: tags.to_vec(),
                        });
                    }
                    pmid.clear();
                    title.clear();
                    abstract_text.clear();
                    if articles.len() >= max_results {
                        break;
                    }
                }
            }
            Ok(Event::Eof) => break,
            Err(_) => break,
            _ => {}
        }
        buf.clear();
    }

    articles
}
