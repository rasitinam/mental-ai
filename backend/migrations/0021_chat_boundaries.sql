-- What a person does NOT want from their conversations with the app —
-- asked once during onboarding (before the screening battery) and
-- editable from the profile afterwards. Stored on the account rather
-- than with the assessment because it isn't a measurement: it's a
-- standing instruction that shapes every reply from then on, the same
-- way `diagnoses` shapes framing.
--
-- `chat_boundaries` holds slugs from `mental_domain::chat_boundary`, each
-- of which maps to a precise prompt directive; `chat_boundary_note` is
-- their own words for anything the fixed list doesn't cover.
ALTER TABLE users ADD COLUMN chat_boundaries TEXT NOT NULL DEFAULT '[]';
ALTER TABLE users ADD COLUMN chat_boundary_note TEXT;
