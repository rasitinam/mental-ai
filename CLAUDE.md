# Hearth (mental-ai)

Hearth is an AI-supported mood, journal and community app for iOS and Android: a Flutter app in `app/` and a Rust backend in `backend/`. The owner is a solo developer who writes in Turkish. Answer in Turkish, plainly, with no jargon. Commit and push only when asked, and end commit messages with the Co-Authored-By line.

## Layout

- `app/`: Flutter app (Riverpod, go_router, Dio). Features live in `lib/features/<name>/{data,domain,presentation}`. The theme and shared widgets live in `lib/app/theme/` (`AppPalette`, `AppTypography`, `GlassSurface`, `AppPrimaryButton`, `ListRow`).
- `backend/`: Rust workspace.
  - `apps/server` holds the axum routes (`src/routes/*.rs`) and `AppState`.
  - `crates/` holds `domain`, `storage` (SQLite repositories), `analysis-engine` (prompts and generators), `llm-connector`, `knowledge-base`, `push` and `research-ingest`.
  - Migrations are in `backend/migrations/` (numbered, applied at startup).
  - The database is `backend/data/mental_ai.db`. It is the production database, so back it up before any manual edit.
- `docs/`: run, CI and App Store notes. `docs/RUNNING_BACKGROUND.md` is the source of truth for running the server.
- Legal pages (privacy policy §6 on OpenAI, terms, support) live in a separate repo, `rasitinam/hearth-privacy`, served by GitHub Pages at `https://rasitinam.github.io/hearth-privacy/`.

## Everyday commands

```bash
cd app && flutter analyze && flutter test   # CI runs analyze over test/ too, so infos fail it
cd app && flutter gen-l10n                  # after editing lib/l10n/app_tr.arb / app_en.arb
cd backend && cargo check -p mental-ai-server && cargo test -p mental-storage -p mental-ai-server
```

- Localization: `app_tr.arb` is the template. Add every string to both `app_tr.arb` and `app_en.arb`, and put `@key` placeholder metadata in the TR file.
- Don't run `dart format` over whole files. The code base isn't formatted with it, and it produces huge diffs.
- In PowerShell, `Set-Content -Encoding utf8` writes a BOM, and that breaks `default.toml`. Use Python or the Edit tool for config files.

## The server runs on this PC (owner's decision, keep it that way)

- `target\release\mental-ai-server.exe` listens on port 8787.
- An ngrok tunnel gives it a fixed public domain: `https://status-enticing-easeful.ngrok-free.dev`. That domain is baked into the iOS build.
- Scheduled tasks:
  - `MentalAI Backend` and `MentalAI ngrok` start at logon.
  - `MentalAI Watchdog` (`scripts/watchdog.ps1`) restarts whichever is down every 5 minutes and logs to `backend/data/watchdog.log`.
- Redeploy without minutes of downtime: build in `target-staging`, stop, copy the exe, start. The exact commands are in `docs/RUNNING_BACKGROUND.md`. Health check: `curl http://127.0.0.1:8787/health`.
- The LLM model is set in `backend/config/default.toml` (`chat_model`, currently `gpt-6-luna`). Change it there and restart. No rebuild is needed.
- Secrets are Windows user environment variables, never in files:
  - `MENTAL_AI_LLM_API_KEY`
  - `MENTAL_AI_APPLE_SHARED_SECRET`
  - `MENTAL_AI_SMTP_*`
  - `MENTAL_AI_APPLE_TEAM_ID` / `_SIWA_KEY_ID` / `_SIWA_KEY_PATH`: not set yet. Sign in with Apple token revocation stays off until they are.

## Releasing

- **TestFlight**: pushing to main uploads nothing. Run `gh workflow run release-ios.yml --ref main`. The build number equals `github.run_number`. The run takes about 9 minutes, then Apple needs another 10–30 minutes to process the build. `codemagic.yaml` is unused.
- **CI** (`ci.yml`, on every push): Rust, Flutter analyze/test, and unsigned Android/iOS builds. It is green as of 2026-10-03. Android CI writes a placeholder `google-services.json`; the real one is gitignored.
- **Android device test**: emulator `Hearth_Pixel_API36` (`adb -s emulator-5554`). Build with `flutter build apk --release --dart-define=API_BASE_URL=http://10.0.2.2:8787`.

## App Store rules this app must keep

Apple has rejected 1.0 three times. Before changing anything listed here, read the memory notes on App Store review first.

- **No "therapy" / "terapi"** in the name, keywords or copy (guidelines 1.4.1, 2.3.7 and 5.1.1(ix); this is an individual developer account). Hearth is a support and self-reflection tool, not a clinician.
- **OpenAI consent (5.1.2(i))**: the `/ai-consent` screen comes after sign-in. Every backend handler that sends a person's data to the LLM must call `routes::require_ai_consent`, or `has_ai_consent` for background and translation paths. New AI features must do the same.
- **Hearth Plus claims must be real**: unlimited chat, daily life analysis, and deeper analysis (`LifeAnalysisInputs::deep`). Don't add paywall claims without backend support.
- **App Privacy labels** in App Store Connect, `ios/Runner/PrivacyInfo.xcprivacy` and policy §6 must stay in sync. They currently declare 8 data types: app functionality only, linked to the user, no tracking.
- **User-generated content (1.2)**: stories are pre-moderated. Users can report stories, profiles and DMs (the `user_reports` table, shown in the admin moderation screen) and can block people.
- **App Review notes** are close to the 4000-character limit. Trim before adding.
- **Swapping a build that is in review**: Cancel Submission, swap the build, then Add for Review. Then re-add the subscription *and* the subscription group through "Add for Review ▾ → Draft iOS Submission"; the cancellation flips them to Developer Rejected. Then Submit.

## Working style the owner expects

- UI redesigns: show a mockup first. Don't implement or push until the owner approves it.
- Verify before saying something is done: run the backend endpoint, take an emulator screenshot, or read the App Store Connect page. Report what was actually checked.
- Things the owner must do personally: tax and banking forms, government IDs, creating Apple keys, and anything that needs Windows admin rights.
