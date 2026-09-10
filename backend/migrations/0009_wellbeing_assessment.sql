-- PHQ-9 + GAD-7 self-report screening, offered (never forced) during
-- onboarding and retakeable later from Settings. `crisis_flag` mirrors
-- the one already on journal entries and chat messages — PHQ-9's own
-- item 9 (self-harm thoughts) triggers it regardless of the total score.
CREATE TABLE IF NOT EXISTS wellbeing_assessments (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id),
    phq9_answers TEXT NOT NULL,
    phq9_score INTEGER NOT NULL,
    gad7_answers TEXT NOT NULL,
    gad7_score INTEGER NOT NULL,
    crisis_flag INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_wellbeing_assessments_user ON wellbeing_assessments(user_id, created_at);
