//! Email verification for sign-up: a 6-digit code is emailed to the address
//! being registered, and `/auth/register` only creates the account once the
//! right code comes back. That proves the person controls the address, and
//! stops someone registering an address that is not theirs.
//!
//! The rules (when a code may be sent, whether a guess is right) are plain
//! functions over an [`EmailCodeRecord`] so they can be tested without a
//! database or a mail server; the routes in `routes::auth` do the storage and
//! sending around them.

use std::sync::Mutex;
use std::time::Duration as StdDuration;

use chrono::{DateTime, Duration, NaiveDate, Utc};
use lettre::message::{header::ContentType, Mailbox};
use lettre::transport::smtp::authentication::Credentials as SmtpCredentials;
use lettre::{AsyncSmtpTransport, AsyncTransport, Message, Tokio1Executor};
use mental_domain::EmailCodeRecord;
use rand::Rng;

use crate::apple_signin::sha256_hex;

/// How long an emailed code stays valid.
pub const CODE_TTL_MINUTES: i64 = 10;
/// The wait before another code can be sent to the same address.
pub const RESEND_COOLDOWN_SECS: i64 = 60;
/// How many codes one address can be sent per hour.
pub const MAX_SENDS_PER_HOUR: u32 = 5;
/// Wrong guesses allowed against one code; after that a new code is needed.
pub const MAX_WRONG_GUESSES: u32 = 5;
/// Codes the whole server will send per day. Gmail's own SMTP limit is 500 a
/// day, and this also caps how much the endpoint can be abused as a mail relay.
pub const MAX_CODES_PER_DAY: u32 = 400;

/// Whether `email` is an address mail can actually be sent to, checked before
/// a code is issued so a typo costs nothing from the sending allowance.
pub fn is_deliverable(email: &str) -> bool {
    email.parse::<lettre::Address>().is_ok()
}

/// A fresh 6-digit code, zero-padded.
pub fn generate_code() -> String {
    format!("{:06}", rand::thread_rng().gen_range(0..1_000_000u32))
}

/// What is stored for a code. Bound to the address so a hash for one email
/// can never be replayed against another.
pub fn hash_code(email: &str, code: &str) -> String {
    sha256_hex(&format!("hearth-email-code:{email}:{code}"))
}

/// Compares in time that does not depend on where the strings first differ.
fn constant_time_eq(a: &str, b: &str) -> bool {
    a.len() == b.len() && a.bytes().zip(b.bytes()).fold(0u8, |acc, (x, y)| acc | (x ^ y)) == 0
}

#[derive(Debug, PartialEq, Eq)]
pub enum SendDenied {
    /// Another code was sent moments ago.
    Cooldown { retry_after_secs: i64 },
    /// This address has already been sent the hourly maximum.
    HourlyLimit,
}

/// Decides whether a new code may be sent to `email` and builds the row to
/// store for it (with `code` already hashed in).
pub fn plan_send(
    existing: Option<&EmailCodeRecord>,
    email: &str,
    code: &str,
    now: DateTime<Utc>,
) -> Result<EmailCodeRecord, SendDenied> {
    let (window_started_at, sends_in_window) = match existing {
        Some(prev) => {
            let since_last = (now - prev.last_sent_at).num_seconds();
            if since_last < RESEND_COOLDOWN_SECS {
                return Err(SendDenied::Cooldown {
                    retry_after_secs: (RESEND_COOLDOWN_SECS - since_last).max(1),
                });
            }
            if now - prev.window_started_at < Duration::hours(1) {
                if prev.sends_in_window >= MAX_SENDS_PER_HOUR {
                    return Err(SendDenied::HourlyLimit);
                }
                (prev.window_started_at, prev.sends_in_window + 1)
            } else {
                (now, 1)
            }
        }
        None => (now, 1),
    };

    Ok(EmailCodeRecord {
        email: email.to_string(),
        code_hash: hash_code(email, code),
        expires_at: now + Duration::minutes(CODE_TTL_MINUTES),
        attempts: 0,
        last_sent_at: now,
        window_started_at,
        sends_in_window,
    })
}

#[derive(Debug, PartialEq, Eq)]
pub enum CodeCheck {
    Accepted,
    /// The code is wrong; the caller records the failed attempt.
    Wrong,
    /// No code was requested for this address, or it has expired.
    NoValidCode,
    /// Too many wrong guesses against this code.
    TooManyAttempts,
}

/// Whether `submitted` is the code emailed to `email`. Spaces around or inside
/// the code are ignored, since people paste it from the message.
pub fn check_code(
    record: Option<&EmailCodeRecord>,
    email: &str,
    submitted: &str,
    now: DateTime<Utc>,
) -> CodeCheck {
    let Some(record) = record else {
        return CodeCheck::NoValidCode;
    };
    if now > record.expires_at {
        return CodeCheck::NoValidCode;
    }
    if record.attempts >= MAX_WRONG_GUESSES {
        return CodeCheck::TooManyAttempts;
    }

    let digits: String = submitted.chars().filter(|c| !c.is_whitespace()).collect();
    if digits.len() == 6
        && digits.chars().all(|c| c.is_ascii_digit())
        && constant_time_eq(&record.code_hash, &hash_code(email, &digits))
    {
        CodeCheck::Accepted
    } else {
        CodeCheck::Wrong
    }
}

/// Counts codes sent today across every address. In memory: it resets when
/// the server restarts, which is fine for a backstop.
pub struct SendBudget {
    state: Mutex<(NaiveDate, u32)>,
}

impl SendBudget {
    pub fn new() -> Self {
        Self { state: Mutex::new((NaiveDate::MIN, 0)) }
    }

    /// Takes one send from today's allowance, or returns false when it is used up.
    pub fn try_take(&self, today: NaiveDate) -> bool {
        let mut state = self.state.lock().unwrap_or_else(|e| e.into_inner());
        if state.0 != today {
            *state = (today, 0);
        }
        if state.1 >= MAX_CODES_PER_DAY {
            return false;
        }
        state.1 += 1;
        true
    }
}

impl Default for SendBudget {
    fn default() -> Self {
        Self::new()
    }
}

/// Subject and plain-text body of the verification email.
pub fn message_for(code: &str, language: &str) -> (String, String) {
    if language == "en" {
        (
            format!("Your Hearth verification code: {code}"),
            format!(
                "Hi,\n\nYour code to finish creating your Hearth account:\n\n    {code}\n\n\
                 It is valid for {CODE_TTL_MINUTES} minutes. If you did not ask for it, you can \
                 ignore this email and no account will be created.\n\nHearth\n"
            ),
        )
    } else {
        (
            format!("Hearth doğrulama kodun: {code}"),
            format!(
                "Merhaba,\n\nHearth hesabını oluşturmak için doğrulama kodun:\n\n    {code}\n\n\
                 Kod {CODE_TTL_MINUTES} dakika geçerli. Bu isteği sen yapmadıysan bu e-postayı \
                 görmezden gelebilirsin, hesap açılmaz.\n\nHearth (Açık Ocak)\n"
            ),
        )
    }
}

/// Where verification emails go out. Configured from the environment:
/// `MENTAL_AI_SMTP_USER` and `MENTAL_AI_SMTP_PASSWORD` (for Gmail, an App
/// Password), optionally `MENTAL_AI_SMTP_HOST` (default `smtp.gmail.com`) and
/// `MENTAL_AI_SMTP_FROM` (default: the user).
pub enum Mailer {
    Smtp { transport: AsyncSmtpTransport<Tokio1Executor>, from: Mailbox },
    /// No SMTP account configured: the message is written to the server log
    /// instead, which is what local development and the smoke test rely on.
    Log,
}

impl Mailer {
    pub fn from_env() -> Self {
        let user = std::env::var("MENTAL_AI_SMTP_USER").unwrap_or_default();
        // Google shows an App Password in four groups separated by spaces.
        let password: String = std::env::var("MENTAL_AI_SMTP_PASSWORD")
            .unwrap_or_default()
            .chars()
            .filter(|c| !c.is_whitespace())
            .collect();
        if user.trim().is_empty() || password.is_empty() {
            tracing::warn!(
                "MENTAL_AI_SMTP_USER / MENTAL_AI_SMTP_PASSWORD not set; verification codes will only be written to the server log"
            );
            return Mailer::Log;
        }

        let host = std::env::var("MENTAL_AI_SMTP_HOST")
            .ok()
            .filter(|h| !h.trim().is_empty())
            .unwrap_or_else(|| "smtp.gmail.com".to_string());
        let from_address = std::env::var("MENTAL_AI_SMTP_FROM")
            .ok()
            .filter(|f| !f.trim().is_empty())
            .unwrap_or_else(|| user.clone());

        let from = match format!("Hearth <{}>", from_address.trim()).parse::<Mailbox>() {
            Ok(from) => from,
            Err(e) => {
                tracing::error!("MENTAL_AI_SMTP_FROM is not a valid address ({e}); verification codes will only be logged");
                return Mailer::Log;
            }
        };
        let builder = match AsyncSmtpTransport::<Tokio1Executor>::relay(&host) {
            Ok(builder) => builder,
            Err(e) => {
                tracing::error!("cannot set up SMTP for {host} ({e}); verification codes will only be logged");
                return Mailer::Log;
            }
        };
        let transport = builder
            .credentials(SmtpCredentials::new(user.trim().to_string(), password))
            .timeout(Some(StdDuration::from_secs(15)))
            .build();

        tracing::info!("verification emails go out through {host}");
        Mailer::Smtp { transport, from }
    }

    pub async fn send(&self, to: &str, subject: &str, body: &str) -> anyhow::Result<()> {
        match self {
            Mailer::Smtp { transport, from } => {
                let message = Message::builder()
                    .from(from.clone())
                    .to(to.parse::<Mailbox>()?)
                    .subject(subject)
                    .header(ContentType::TEXT_PLAIN)
                    .body(body.to_string())?;
                transport.send(message).await?;
                Ok(())
            }
            Mailer::Log => {
                tracing::warn!("email to {to} (no SMTP configured): {subject}\n{body}");
                Ok(())
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn now() -> DateTime<Utc> {
        "2026-09-21T12:00:00Z".parse().unwrap()
    }


    #[test]
    fn only_real_looking_addresses_are_deliverable() {
        assert!(is_deliverable("person@gmail.com"));
        assert!(is_deliverable("first.last+tag@example.co.uk"));
        assert!(!is_deliverable("no-at-sign"));
        assert!(!is_deliverable("two words@gmail.com"));
        assert!(!is_deliverable(""));
    }

    #[test]
    fn generated_codes_are_six_digits() {
        for _ in 0..200 {
            let code = generate_code();
            assert_eq!(code.len(), 6);
            assert!(code.chars().all(|c| c.is_ascii_digit()));
        }
    }

    #[test]
    fn hash_is_bound_to_the_address() {
        assert_eq!(hash_code("a@x.com", "123456"), hash_code("a@x.com", "123456"));
        assert_ne!(hash_code("a@x.com", "123456"), hash_code("b@x.com", "123456"));
        assert_ne!(hash_code("a@x.com", "123456"), hash_code("a@x.com", "123457"));
    }

    #[test]
    fn first_send_is_allowed_and_expires_in_ten_minutes() {
        let record = plan_send(None, "a@x.com", "123456", now()).unwrap();
        assert_eq!(record.sends_in_window, 1);
        assert_eq!(record.attempts, 0);
        assert_eq!(record.expires_at, now() + Duration::minutes(10));
        assert_eq!(record.code_hash, hash_code("a@x.com", "123456"));
    }

    #[test]
    fn resend_inside_the_cooldown_is_refused() {
        let first = plan_send(None, "a@x.com", "111111", now()).unwrap();
        let denied = plan_send(Some(&first), "a@x.com", "222222", now() + Duration::seconds(20));
        assert_eq!(denied, Err(SendDenied::Cooldown { retry_after_secs: 40 }));

        let again = plan_send(Some(&first), "a@x.com", "222222", now() + Duration::seconds(61)).unwrap();
        assert_eq!(again.sends_in_window, 2);
        assert_eq!(again.window_started_at, first.window_started_at);
        // A new code starts with a clean slate of guesses.
        assert_eq!(again.attempts, 0);
    }

    #[test]
    fn hourly_limit_holds_until_the_window_rolls_over() {
        let mut record = plan_send(None, "a@x.com", "000000", now()).unwrap();
        let mut t = now();
        for _ in 1..MAX_SENDS_PER_HOUR {
            t += Duration::seconds(61);
            record = plan_send(Some(&record), "a@x.com", "000000", t).unwrap();
        }
        assert_eq!(record.sends_in_window, MAX_SENDS_PER_HOUR);
        assert_eq!(
            plan_send(Some(&record), "a@x.com", "000000", t + Duration::seconds(61)),
            Err(SendDenied::HourlyLimit)
        );

        let later = now() + Duration::hours(1) + Duration::seconds(5);
        let fresh = plan_send(Some(&record), "a@x.com", "000000", later).unwrap();
        assert_eq!(fresh.sends_in_window, 1);
        assert_eq!(fresh.window_started_at, later);
    }

    #[test]
    fn correct_code_is_accepted_even_with_spaces() {
        let record = plan_send(None, "a@x.com", "048291", now()).unwrap();
        assert_eq!(check_code(Some(&record), "a@x.com", "048291", now()), CodeCheck::Accepted);
        assert_eq!(check_code(Some(&record), "a@x.com", " 048 291 ", now()), CodeCheck::Accepted);
    }

    #[test]
    fn wrong_malformed_or_foreign_codes_are_rejected() {
        let record = plan_send(None, "a@x.com", "048291", now()).unwrap();
        assert_eq!(check_code(Some(&record), "a@x.com", "048292", now()), CodeCheck::Wrong);
        assert_eq!(check_code(Some(&record), "a@x.com", "48291", now()), CodeCheck::Wrong);
        assert_eq!(check_code(Some(&record), "a@x.com", "04829a", now()), CodeCheck::Wrong);
        assert_eq!(check_code(Some(&record), "a@x.com", "", now()), CodeCheck::Wrong);
        // The same digits against another address do not match.
        assert_eq!(check_code(Some(&record), "b@x.com", "048291", now()), CodeCheck::Wrong);
    }

    #[test]
    fn missing_or_expired_codes_do_not_count_as_wrong() {
        assert_eq!(check_code(None, "a@x.com", "048291", now()), CodeCheck::NoValidCode);
        let record = plan_send(None, "a@x.com", "048291", now()).unwrap();
        let late = now() + Duration::minutes(CODE_TTL_MINUTES) + Duration::seconds(1);
        assert_eq!(check_code(Some(&record), "a@x.com", "048291", late), CodeCheck::NoValidCode);
    }

    #[test]
    fn guessing_is_capped_even_for_the_right_code() {
        let mut record = plan_send(None, "a@x.com", "048291", now()).unwrap();
        record.attempts = MAX_WRONG_GUESSES;
        assert_eq!(check_code(Some(&record), "a@x.com", "048291", now()), CodeCheck::TooManyAttempts);
    }

    #[test]
    fn daily_budget_runs_out_and_resets_the_next_day() {
        let budget = SendBudget::new();
        let today = now().date_naive();
        for _ in 0..MAX_CODES_PER_DAY {
            assert!(budget.try_take(today));
        }
        assert!(!budget.try_take(today));
        assert!(budget.try_take(today.succ_opt().unwrap()));
    }

    #[test]
    fn message_carries_the_code_in_both_languages() {
        let (subject, body) = message_for("123456", "en");
        assert!(subject.contains("123456") && body.contains("123456"));
        assert!(subject.starts_with("Your Hearth"));
        let (subject, body) = message_for("123456", "tr");
        assert!(subject.contains("123456") && body.contains("123456"));
        assert!(subject.starts_with("Hearth doğrulama"));
    }
}
