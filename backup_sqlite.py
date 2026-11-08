import sqlite3
from pathlib import Path
from datetime import datetime, timedelta
import sys

source = Path(r"C:\Apps\MentalAI\backend\data\mental_ai.db")
backup_dir = Path(r"C:\Apps\MentalAI\backups")
log_file = backup_dir / "backup.log"

backup_dir.mkdir(parents=True, exist_ok=True)

def log(message):
    line = f"{datetime.now().isoformat(timespec='seconds')} | {message}"
    print(line)
    with log_file.open("a", encoding="utf-8") as f:
        f.write(line + "\n")

if not source.is_file():
    log(f"ERROR: Database not found: {source}")
    sys.exit(1)

stamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
destination = backup_dir / f"mental_ai_{stamp}.db"

src = None
dst = None

try:
    src = sqlite3.connect(source.as_uri() + "?mode=ro", uri=True, timeout=30)
    dst = sqlite3.connect(str(destination), timeout=30)

    src.backup(dst, pages=256, sleep=0.1)
    dst.commit()

    integrity = dst.execute("PRAGMA integrity_check").fetchone()[0]

    if integrity != "ok":
        raise RuntimeError(f"Backup integrity failed: {integrity}")

    tables = dst.execute(
        "SELECT COUNT(*) FROM sqlite_master WHERE type='table'"
    ).fetchone()[0]

    size_mb = destination.stat().st_size / (1024 * 1024)

    log(f"SUCCESS: {destination.name}")
    log(f"Integrity: {integrity} | Tables: {tables} | Size: {size_mb:.2f} MB")

except Exception as exc:
    if destination.exists():
        destination.unlink()
    log(f"ERROR: {type(exc).__name__}: {exc}")
    sys.exit(1)

finally:
    if dst:
        dst.close()
    if src:
        src.close()

# Retain the latest 14 days of successful backups.
cutoff = datetime.now() - timedelta(days=14)

for old in backup_dir.glob("mental_ai_*.db"):
    if old == destination:
        continue
    if datetime.fromtimestamp(old.stat().st_mtime) < cutoff:
        old.unlink()
        log(f"Removed expired backup: {old.name}")

log("Backup process completed.")
