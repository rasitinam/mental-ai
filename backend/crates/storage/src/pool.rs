use sqlx::sqlite::{SqlitePool, SqlitePoolOptions};

/// Opens the SQLite pool and runs pending migrations from `../migrations`
/// (embedded at compile time). Call once at startup before constructing
/// any repository.
pub async fn init_pool(database_url: &str) -> anyhow::Result<SqlitePool> {
    if let Some(path) = database_url.strip_prefix("sqlite://") {
        if let Some(parent) = std::path::Path::new(path).parent() {
            std::fs::create_dir_all(parent)?;
        }
    }

    let pool = SqlitePoolOptions::new()
        .max_connections(5)
        .connect(database_url)
        .await?;

    sqlx::migrate!("../../migrations").run(&pool).await?;

    Ok(pool)
}
