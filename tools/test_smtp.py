#!/usr/bin/env python3
"""Send one real SMTP verification message using Mental.AI's existing env vars.

Credentials are read from the process environment and are never printed.
The test message is sent to MENTAL_AI_SMTP_TEST_TO, or to SMTP_USER by default.
"""

from __future__ import annotations

import os
import re
import smtplib
import ssl
import sys
from email.message import EmailMessage
from email.utils import formataddr
from datetime import datetime, timezone


def required(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise RuntimeError(f"{name} is missing from this process environment")
    return value


def main() -> int:
    try:
        username = required("MENTAL_AI_SMTP_USER")
        password = re.sub(r"\s+", "", required("MENTAL_AI_SMTP_PASSWORD"))
        host = os.environ.get("MENTAL_AI_SMTP_HOST", "smtp.gmail.com").strip() or "smtp.gmail.com"
        sender = os.environ.get("MENTAL_AI_SMTP_FROM", username).strip() or username
        recipient = os.environ.get("MENTAL_AI_SMTP_TEST_TO", username).strip() or username

        message = EmailMessage()
        message["Subject"] = "Mental.AI SMTP connection test"
        message["From"] = formataddr(("Hearth", sender))
        message["To"] = recipient
        message.set_content(
            "This is a one-time SMTP delivery test from the Mental.AI backend.\n"
            f"UTC time: {datetime.now(timezone.utc).isoformat()}\n"
            "No account or application data is included."
        )

        print(f"SMTP host: {host}:465")
        print("Credentials: present (values hidden)")
        print("Connecting with implicit TLS...")

        context = ssl.create_default_context()
        with smtplib.SMTP_SSL(host, 465, timeout=25, context=context) as server:
            server.ehlo()
            server.login(username, password)
            print("SMTP authentication: SUCCESS")
            refused = server.send_message(message)
            if refused:
                print(f"SMTP server refused recipient(s): {', '.join(refused.keys())}")
                return 2

        print("SMTP server accepted the test message.")
        print("Check the destination inbox and spam folder for final delivery.")
        return 0

    except Exception as exc:
        print(f"SMTP TEST FAILED: {type(exc).__name__}: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
