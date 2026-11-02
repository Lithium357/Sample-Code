-- Cohort retention.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE signup (user_id INTEGER PRIMARY KEY, cohort_month TEXT NOT NULL);
CREATE TABLE activity (user_id INTEGER REFERENCES signup(user_id), month TEXT NOT NULL,
                       PRIMARY KEY (user_id, month));
INSERT INTO signup VALUES (1, '2026-01-01'), (2, '2026-01-01'), (3, '2026-02-01');
INSERT INTO activity VALUES
    (1, '2026-01-01'), (1, '2026-02-01'), (1, '2026-03-01'),
    (2, '2026-01-01'), (3, '2026-02-01');
CREATE VIEW retention AS
WITH sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size FROM signup GROUP BY cohort_month
), observed AS (
    SELECT s.cohort_month,
           (CAST(STRFTIME('%Y', a.month) AS INTEGER) - CAST(STRFTIME('%Y', s.cohort_month) AS INTEGER)) * 12
           + CAST(STRFTIME('%m', a.month) AS INTEGER) - CAST(STRFTIME('%m', s.cohort_month) AS INTEGER) AS age_months,
           COUNT(DISTINCT a.user_id) AS active_users
    FROM signup AS s JOIN activity AS a USING (user_id)
    WHERE a.month >= s.cohort_month GROUP BY s.cohort_month, age_months
)
SELECT o.*, z.cohort_size, 1.0 * active_users / cohort_size AS retained_fraction
FROM observed AS o JOIN sizes AS z USING (cohort_month);
SELECT * FROM retention ORDER BY cohort_month, age_months;
INSERT INTO checks VALUES ((SELECT retained_fraction FROM retention WHERE cohort_month = '2026-01-01' AND age_months = 0) = 1.0);
INSERT INTO checks VALUES ((SELECT retained_fraction FROM retention WHERE cohort_month = '2026-01-01' AND age_months = 1) = 0.5);
-- Missing age cells are absent; a complete dashboard would join an age spine.
COMMIT;
