-- Widens the self-assessment from PHQ-9 + GAD-7 alone to a small battery
-- of public-domain screening instruments, so "Öz-değerlendirme" covers
-- more than mood and anxiety. Each instrument keeps the same
-- answers/score column pair the original two use — same shape, just more
-- of them — rather than a generic key/value table, so scoring stays
-- ordinary Rust struct fields instead of runtime-interpreted data.
--
-- WHO-5 (well-being, 5 items, 0-5 per item), PHQ-15 (somatic symptom
-- severity, 15 items, 0-2 per item), PC-PTSD-5 (post-traumatic stress
-- screen, 5 yes/no items), AUDIT-C (alcohol use, 3 items, 0-4 per item)
-- and CAGE-AID (substance use, 4 yes/no items) are all public-domain
-- instruments, same licensing basis as PHQ-9/GAD-7 themselves.
ALTER TABLE wellbeing_assessments ADD COLUMN who5_answers TEXT NOT NULL DEFAULT '[]';
ALTER TABLE wellbeing_assessments ADD COLUMN who5_score INTEGER NOT NULL DEFAULT 0;
ALTER TABLE wellbeing_assessments ADD COLUMN phq15_answers TEXT NOT NULL DEFAULT '[]';
ALTER TABLE wellbeing_assessments ADD COLUMN phq15_score INTEGER NOT NULL DEFAULT 0;
ALTER TABLE wellbeing_assessments ADD COLUMN ptsd5_answers TEXT NOT NULL DEFAULT '[]';
ALTER TABLE wellbeing_assessments ADD COLUMN ptsd5_score INTEGER NOT NULL DEFAULT 0;
ALTER TABLE wellbeing_assessments ADD COLUMN auditc_answers TEXT NOT NULL DEFAULT '[]';
ALTER TABLE wellbeing_assessments ADD COLUMN auditc_score INTEGER NOT NULL DEFAULT 0;
ALTER TABLE wellbeing_assessments ADD COLUMN cageaid_answers TEXT NOT NULL DEFAULT '[]';
ALTER TABLE wellbeing_assessments ADD COLUMN cageaid_score INTEGER NOT NULL DEFAULT 0;
