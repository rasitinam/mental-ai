#!/usr/bin/env bash
# Whole-backend smoke test: every route, the auth/permission edge cases, the
# free-chat budget + subscription gate, and per-request latency. Uses two
# throwaway accounts that are deleted at the end.
# Needs the server running locally. Usage:
#   SQLITE3=/path/to/sqlite3 bash scripts/e2e_smoke.sh
# (SQLITE3 defaults to `sqlite3` on PATH; DB defaults to backend/data/mental_ai.db.)
set -u
B=${B:-http://127.0.0.1:8787}
SQ=${SQLITE3:-sqlite3}
DB=${DB:-$(cd "$(dirname "$0")/.." && pwd)/backend/data/mental_ai.db}
W=$(cygpath -m "$(mktemp -d)" 2>/dev/null || mktemp -d)
mkdir -p "$W"
PASS=0; FAIL=0; FAILS=""
SUFFIX=$RANDOM
EA="qa.a$SUFFIX@example.com"; EB="qa.b$SUFFIX@example.com"; PW="testpass123"

body() { printf '%s' "$2" > "$W/$1.json"; echo "$W/$1.json"; }

# t LABEL EXPECTED(regex) METHOD PATH TOKEN [BODYFILE]
t() {
  local label="$1" exp="$2" m="$3" p="$4" tok="$5" f="${6:-}"
  local args=(-s -o "$W/last.json" -w '%{http_code} %{time_total}' -X "$m" "$B$p" -H 'content-type: application/json; charset=utf-8')
  [ -n "$tok" ] && args+=(-H "authorization: Bearer $tok")
  [ -n "$f" ] && args+=(--data-binary "@$f")
  local out code secs
  out=$(MSYS_NO_PATHCONV=1 curl "${args[@]}")
  code=${out% *}; secs=${out#* }
  local ms=$(awk "BEGIN{printf \"%d\", $secs*1000}")
  if [[ "$code" =~ ^($exp)$ ]]; then PASS=$((PASS+1)); printf 'PASS %-52s %s %5sms\n' "$label" "$code" "$ms"
  else FAIL=$((FAIL+1)); FAILS="$FAILS\n  - $label (got $code, want $exp): $(head -c 160 "$W/last.json" | tr '\n' ' ')"; printf 'FAIL %-52s %s (want %s) %5sms  %s\n' "$label" "$code" "$exp" "$ms" "$(head -c 120 "$W/last.json" | tr '\n' ' ')"; fi
}
jget() { sed -n -E "s/.*\"$1\":\"([^\"]+)\".*/\1/p" "$W/last.json" | head -1; }

echo "##### AUTH"
t "health" 200 GET /health ""
t "register A" 200 POST /auth/register "" "$(body regA "{\"email\":\"$EA\",\"password\":\"$PW\",\"display_name\":\"QA Bir\",\"language\":\"tr\"}")"
TA=$(jget token); UA=$(jget user_id)
t "register B" 200 POST /auth/register "" "$(body regB "{\"email\":\"$EB\",\"password\":\"$PW\",\"display_name\":\"QA Iki\",\"language\":\"en\"}")"
TB=$(jget token); UB=$(jget user_id)
t "register duplicate email" 409 POST /auth/register "" "$(body regA2 "{\"email\":\"$EA\",\"password\":\"$PW\"}")"
t "register short password" 400 POST /auth/register "" "$(body regS "{\"email\":\"x$SUFFIX@example.com\",\"password\":\"123\"}")"
t "register bad email" 400 POST /auth/register "" "$(body regE '{"email":"nope","password":"testpass123"}')"
t "login ok" 200 POST /auth/login "" "$(body logA "{\"email\":\"$EA\",\"password\":\"$PW\"}")"
t "login wrong password" 401 POST /auth/login "" "$(body logW "{\"email\":\"$EA\",\"password\":\"wrongpass1\"}")"
t "login unknown email" 401 POST /auth/login "" "$(body logU '{"email":"nobody@example.com","password":"testpass123"}')"
t "apple: garbage token rejected" 401 POST /auth/apple "" "$(body apG '{"identity_token":"a.b.c","nonce":"n"}')"
t "no token -> 401" 401 GET /profile ""
t "bad token -> 401" 401 GET /profile "not-a-real-token"

echo "##### PROFILE"
t "profile" 200 GET /profile "$TA"; grep -q '"signs_in_with_apple":false' "$W/last.json" && echo "     signs_in_with_apple present" || echo "     WARN signs_in_with_apple missing"
t "preferences" 200 PUT /profile/preferences "$TA" "$(body pref '{"display_name":"QA Bir","language":"tr","birth_year":1995,"dm_policy":"everyone","utc_offset_minutes":180}')"
t "preferences bad offset" 400 PUT /profile/preferences "$TA" "$(body prefB '{"utc_offset_minutes":9999}')"
t "catalog" 200 GET /catalog "$TA"; SLUG=$(jget slug)
t "catalog disorder explainer" 200 GET "/catalog/disorders/${SLUG:-major-depresif}" "$TA"
t "diagnoses" 200 PUT /profile/diagnoses "$TA" "$(body diag "{\"diagnoses\":[\"${SLUG:-major-depresif}\"]}")"
t "chat boundaries" 200 PUT /profile/chat-boundaries "$TA" "$(body cb '{"boundaries":[],"note":"test"}')"
t "checkin reminder" 200 PUT /profile/checkin-reminder "$TA" "$(body cr '{"enabled":true,"hour":21}')"
t "checkin reminder bad hour" 400 PUT /profile/checkin-reminder "$TA" "$(body crb '{"enabled":true,"hour":9}')"
t "push token register" 200\|204 PUT /profile/push-token "$TA" "$(body pt '{"token":"fake-token-123","platform":"android"}')"
t "push token remove" 200\|204 DELETE /profile/push-token "$TA" "$(body ptd '{"token":"fake-token-123"}')"
t "avatar get (none)" 404 GET /profile/avatar "$TA"
printf '\x89PNG\r\n\x1a\n' > "$W/a.png"
AVC=$(MSYS_NO_PATHCONV=1 curl -s -o "$W/last.json" -w "%{http_code}" -X PUT "$B/profile/avatar" -H "authorization: Bearer $TA" -F "file=@$W/a.png;type=image/png")
if [[ "$AVC" =~ ^(200|204)$ ]]; then PASS=$((PASS+1)); echo "PASS avatar upload                                  $AVC"; else FAIL=$((FAIL+1)); FAILS="$FAILS\n  - avatar upload (got $AVC): $(head -c 160 "$W/last.json")"; echo "FAIL avatar upload $AVC $(head -c 120 "$W/last.json")"; fi
t "avatar get (after upload)" 200 GET /profile/avatar "$TA"

echo "##### MOOD / JOURNAL / STATE / STREAK / ASSESSMENT"
t "mood add" 200 POST /mood "$TA" "$(body mood '{"valence":-0.4,"arousal":-0.3,"tags":["yorgun","gergin"],"note":"Uzun bir gün oldu."}')"
t "mood cooldown (2nd within 24h)" '4[0-9][0-9]' POST /mood "$TA" "$W/mood.json"
t "mood history" 200 GET /mood/history "$TA"
t "mood latest" 200 GET /mood/latest "$TA"
t "journal add" 200 POST /journal "$TA" "$(body jr '{"body":"Bugün toplantılar üst üste bindi, akşam yürüyüşe çıkınca rahatladım ama gece uyuyamadım."}')"
t "journal list" 200 GET /journal "$TA"
t "journal latest" 200 GET /journal/latest "$TA"
t "state" 200 GET /state "$TA"
t "state refresh" 200\|204 POST /state/refresh "$TA"
t "streak" 200 GET /streak "$TA"
t "assessment latest (none)" '200|404' GET /assessment "$TA"
t "assessment submit" '200|204' POST /assessment "$TA" "$(body asmt '{"phq9_answers":[1,1,1,1,1,1,1,1,0],"gad7_answers":[1,1,1,1,1,1,1],"who5_answers":[3,3,3,3,3],"phq15_answers":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"ptsd5_answers":[0,0,0,0,0],"auditc_answers":[0,0,0],"cageaid_answers":[0,0,0,0]}')"
t "discoveries" 200 GET /discoveries "$TA"
t "onboarding intro" 200 POST /onboarding/intro "$TA" "$(body ob '{"answer":"Uykum bozuk ve kendimi yorgun hissediyorum."}')"

echo "##### CHAT (LLM) + FREE BUDGET + SUBSCRIPTION GATE"
t "chat message (LLM)" 200 POST /chat "$TA" "$(body chat '{"message":"Merhaba, bugün biraz yorgunum.","history":[]}')"
t "chat history" 200 GET /chat/history "$TA"
t "chat speech (TTS)" 200 POST /chat/speech "$TA" "$(body tts '{"text":"Merhaba, nasılsın?"}')"
TODAY=$(date -u +%Y-%m-%d)
$SQ $DB "INSERT INTO chat_token_usage (user_id,usage_date,tokens_used) VALUES ('$UA','$TODAY',10000) ON CONFLICT(user_id,usage_date) DO UPDATE SET tokens_used=10000;"
t "chat over 10k budget -> 402 paywall" 402 POST /chat "$TA" "$W/chat.json"
$SQ $DB "INSERT INTO subscriptions (user_id,platform,product_id,original_transaction_id,expires_at,updated_at) VALUES ('$UA','manual','com.rasitinam.hearth.premium.monthly','qa-test','2099-12-31T00:00:00+00:00','2026-01-01T00:00:00+00:00');"
t "subscription endpoint shows premium" 200 GET /purchases/subscription "$TA"; grep -q '"is_premium":true' "$W/last.json" && echo "     is_premium=true OK" || echo "     WARN premium not reflected"
t "chat over budget but premium -> 200" 200 POST /chat "$TA" "$W/chat.json"
$SQ $DB "DELETE FROM subscriptions WHERE user_id='$UA';"
t "subscription (free) " 200 GET /purchases/subscription "$TB"; grep -q '"is_premium":false' "$W/last.json" && echo "     is_premium=false OK"
t "verify-apple garbage receipt" '400|502' POST /purchases/verify-apple "$TB" "$(body vr '{"receipt_data":"garbage"}')"

echo "##### REPORTS / ANALYSIS / INSIGHTS / SUMMARY (LLM)"
t "reports generate" '200|429' POST /reports/generate "$TA"
t "reports list" 200 GET /reports "$TA"
t "reports latest" '200|404' GET /reports/latest "$TA"
t "life-analysis generate" '200|422|429' POST /life-analysis/generate "$TA"
t "life-analysis latest" '200|404' GET /life-analysis/latest "$TA"
t "insights (public)" 200 GET /insights ""
t "insights synthesize-now (non-admin)" '401|403|200|202' POST /insights/synthesize-now "$TA"
t "session summary" '200|422' POST /session-summary "$TA" "$(body ss '{"days":14,"note":"Uyku düzenimi konuşmak istiyorum."}')"

echo "##### STORIES / SOCIAL / DM"
t "story submit (B)" 200 POST /stories "$TB" "$(body st "{\"body\":\"Uzun süre kimseye anlatamadım ama sonunda yardım istedim ve yavaş yavaş toparlandım.\",\"diagnosis_slug\":\"${SLUG:-major-depresif}\",\"consent\":true,\"anonymous\":true}")"
SID=$(jget id)
t "story submit without consent" 400 POST /stories "$TB" "$(body st2 "{\"body\":\"x\",\"diagnosis_slug\":\"${SLUG:-major-depresif}\",\"consent\":false,\"anonymous\":true}")"
t "stories mine (B)" 200 GET /stories/mine "$TB"
t "stories pending (non-admin)" '401|403|200' GET /stories/pending "$TA"
t "stories reports (non-admin)" '401|403|200' GET /stories/reports "$TA"
$SQ $DB "UPDATE life_stories SET status='approved', reviewed_at='2026-09-20T00:00:00+00:00' WHERE id='$SID';"
t "stories feed" 200 GET /stories "$TA"
t "story react (A)" 200\|204 POST "/stories/$SID/react" "$TA" "$(body rc '{"reaction":"destek"}')"
t "story react bad value" 400 POST "/stories/$SID/react" "$TA" "$(body rcb '{"reaction":"nope"}')"
t "story unreact" 200\|204 DELETE "/stories/$SID/react" "$TA"
t "story metoo" 200\|204 POST "/stories/$SID/metoo" "$TA" "$(body me '{"note":"yalniz_degilsin"}')"
t "story metoo remove" 200\|204 DELETE "/stories/$SID/metoo" "$TA"
t "story report" 200\|204 POST "/stories/$SID/report" "$TA" "$(body rp '{"note":"test"}')"
t "story translate" '200|404|502' GET "/stories/$SID/translate" "$TA"
t "story update (owner)" 200 PUT "/stories/$SID" "$TB" "$(body us "{\"body\":\"Güncellenmiş hikaye: yardım istemek zor ama iyi geldi.\",\"diagnosis_slug\":\"${SLUG:-major-depresif}\",\"anonymous\":true}")"
t "story update (not owner)" '403|404' PUT "/stories/$SID" "$TA" "$W/us.json"
t "public profile of B" 200 GET "/users/$UB" "$TA"
t "follow B" 200\|204 POST "/users/$UB/follow" "$TA"
t "followers of B" 200 GET "/users/$UB/followers" "$TA"
t "following of A" 200 GET "/users/$UA/following" "$TA"
t "avatar of B (none)" '200|404' GET "/users/$UB/avatar" "$TA"
t "DM open A->B" '200|201' POST "/dm/with/$UB" "$TA" "$(body dmo '{"body":"Selam, hikayen çok iyi geldi."}')"; TID=$(jget thread_id)
t "DM requests (B)" 200 GET /dm/requests "$TB"
t "DM accept (B)" 200\|204 POST "/dm/threads/$TID/accept" "$TB"
t "DM send (A)" '200|201' POST "/dm/threads/$TID/messages" "$TA" "$(body dm '{"body":"Selam, hikayen çok iyi geldi."}')"
t "DM messages" 200 GET "/dm/threads/$TID/messages" "$TB"
t "DM threads" 200 GET /dm/threads "$TA"
t "unfollow B" 200\|204 DELETE "/users/$UB/follow" "$TA"
t "story withdraw (B)" 200\|204 DELETE "/stories/$SID" "$TB"
t "DM decline/delete thread" 200\|204 DELETE "/dm/threads/$TID" "$TB"

echo "##### LOGOUT / DELETE ACCOUNT"
t "logout A" 200\|204 POST /auth/logout "$TA"
t "old token rejected after logout" 401 GET /profile "$TA"
TA2=$(curl -s -X POST "$B/auth/login" -H 'content-type: application/json' --data-binary "@$W/logA.json" | sed -n -E 's/.*"token":"([^"]+)".*/\1/p')
t "delete account wrong password" 401 DELETE /account "$TA2" "$(body dw '{"password":"wrongpass1"}')"
t "delete account without password" 401 DELETE /account "$TA2" "$(body dn '{}')"
t "delete account A" 200\|204 DELETE /account "$TA2" "$(body dA "{\"password\":\"$PW\"}")"
t "delete account B" 200\|204 DELETE /account "$TB" "$(body dB "{\"password\":\"$PW\"}")"
t "login after delete -> 401" 401 POST /auth/login "" "$W/logA.json"
LEFT=$($SQ $DB "select (select count(*) from users where id in ('$UA','$UB'))+(select count(*) from credentials where user_id in ('$UA','$UB'))+(select count(*) from subscriptions where user_id in ('$UA','$UB'))+(select count(*) from chat_token_usage where user_id in ('$UA','$UB'));")
echo "rows left behind by deleted test accounts: $LEFT (want 0)"

echo; echo "=========== $PASS passed, $FAIL failed"; [ $FAIL -gt 0 ] && printf "$FAILS\n"
exit 0
