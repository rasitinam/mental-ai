import sqlite3
import json
from pathlib import Path
from google.oauth2 import service_account
from google.auth.transport.requests import AuthorizedSession

BASE = Path(r"C:\Apps\MentalAI")
DB = BASE / "backend" / "data" / "mental_ai.db"
SA = BASE / "backend" / "firebase-service-account.json"

if not SA.exists():
    raise SystemExit("Firebase service account bulunamadi.")

with DB.open("rb"):
    pass

conn = sqlite3.connect(DB.as_uri() + "?mode=ro", uri=True)

row = conn.execute("""
    SELECT token, updated_at
    FROM device_push_tokens
    ORDER BY updated_at DESC
    LIMIT 1
""").fetchone()

conn.close()

if not row:
    raise SystemExit("Kayitli FCM token bulunamadi.")

device_token, updated_at = row

with SA.open(encoding="utf-8") as f:
    service = json.load(f)

credentials = service_account.Credentials.from_service_account_file(
    str(SA),
    scopes=["https://www.googleapis.com/auth/firebase.messaging"]
)

project_id = service["project_id"]

url = (
    f"https://fcm.googleapis.com/v1/projects/"
    f"{project_id}/messages:send"
)

payload = {
    "message": {
        "token": device_token,
        "notification": {
            "title": "Mental AI",
            "body": "Bildirim sistemi basariyla calisiyor!"
        },
        "data": {
            "type": "test"
        },
        "android": {
            "priority": "HIGH",
            "notification": {
                "channel_id": "mental_ai_messages"
            }
        }
    }
}

session = AuthorizedSession(credentials)

try:
    response = session.post(url, json=payload, timeout=30)

    print("Firebase Project:", project_id)
    print("HTTP Status:", response.status_code)

    if response.ok:
        print("FCM DELIVERY ACCEPTED")
        print("Message:", response.json().get("name"))
        print("Device token updated at:", updated_at)
    else:
        print("FCM SEND FAILED")
        print("Firebase response:", response.text)

finally:
    session.close()
    device_token = None
