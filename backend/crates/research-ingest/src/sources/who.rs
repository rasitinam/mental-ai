use async_trait::async_trait;

use super::{RawArticle, ResearchSource};

/// Fetches WHO mental-health news/publications RSS. WHO's feed doesn't
/// carry a stable numeric ID, so the item link is used as the dedup key.
pub struct WhoRssSource {
    client: reqwest::Client,
    feed_url: String,
}

impl WhoRssSource {
    pub fn new(feed_url: impl Into<String>) -> Self {
        Self {
            client: reqwest::Client::new(),
            feed_url: feed_url.into(),
        }
    }
}

#[async_trait]
impl ResearchSource for WhoRssSource {
    fn name(&self) -> &'static str {
        "who"
    }

    async fn fetch_recent(&self) -> anyhow::Result<Vec<RawArticle>> {
        let body = self.client.get(&self.feed_url).send().await?.text().await?;
        Ok(parse_rss(&body))
    }
}

fn parse_rss(xml: &str) -> Vec<RawArticle> {
    use quick_xml::events::Event;
    use quick_xml::reader::Reader;

    let mut reader = Reader::from_str(xml);
    reader.config_mut().trim_text(true);

    let mut items = Vec::new();
    let (mut title, mut link, mut description) = (String::new(), String::new(), String::new());
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
                    "title" => title.push_str(&text),
                    "link" => link.push_str(&text),
                    "description" => description.push_str(&text),
                    _ => {}
                }
            }
            Ok(Event::End(e)) => {
                if e.name().as_ref() == b"item" {
                    if !link.is_empty() {
                        items.push(RawArticle {
                            source: "who".to_string(),
                            external_id: link.clone(),
                            title: title.clone(),
                            abstract_text: description.clone(),
                            url: link.clone(),
                            published_at: None,
                            tags: vec!["mental-health".to_string(), "who".to_string()],
                        });
                    }
                    title.clear();
                    link.clear();
                    description.clear();
                }
            }
            Ok(Event::Eof) => break,
            Err(_) => break,
            _ => {}
        }
        buf.clear();
    }

    items
}
