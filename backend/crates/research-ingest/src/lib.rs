//! Background research collection. This is the "self-improving" half of
//! the product: on a schedule (see `apps/server`'s scheduler wiring), it
//! pulls new abstracts/metadata from a small set of reputable sources,
//! deduplicates against what's already stored, and hands new articles to
//! `mental-knowledge-base` for embedding. It never modifies the
//! application's own source code — "self-improving" here means "the
//! knowledge base the analysis engine draws on keeps growing," which is
//! both safer and the thing that actually matters for report quality.
//!
//! Only open-access abstracts and bibliographic metadata are stored,
//! never full copyrighted article text — see `docs/DATA_SOURCES.md`.

pub mod pipeline;
pub mod sources;

pub use pipeline::{run_ingest_cycle, IngestSummary};
pub use sources::{RawArticle, ResearchSource};
