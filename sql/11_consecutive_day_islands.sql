-- Consecutive day islands.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE attendance (
    user_id INTEGER NOT NULL,
    day TEXT NOT NULL,
    PRIMARY KEY(user_id, day)
);
INSERT INTO attendance VALUES
    (1, '2026-01-01'), (1, '2026-01-02'), (1, '2026-01-03'),
    (1, '2026-01-05'), (1, '2026-01-06'), (2, '2026-01-02');
CREATE VIEW streaks AS
WITH numbered AS (
    SELECT user_id, day,
        CAST(JULIANDAY(day) AS INTEGER)
        - ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY day) AS island
    FROM attendance
)
SELECT user_id, MIN(day) AS first_day, MAX(day) AS last_day, COUNT(*) AS days
FROM numbered GROUP BY user_id, island;
SELECT * FROM streaks ORDER BY user_id, first_day;
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM streaks WHERE user_id = 1) = 2);
INSERT INTO checks VALUES ((SELECT MAX(days) FROM streaks WHERE user_id = 1) = 3);
-- A second window selects the longest streak, with earliest date as tie-break.
WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY days DESC, first_day) AS position
    FROM streaks
)
SELECT user_id, first_day, last_day, days FROM ranked WHERE position = 1 ORDER BY user_id;
-- The primary key prevents duplicates from distorting the row-number trick.
COMMIT;
