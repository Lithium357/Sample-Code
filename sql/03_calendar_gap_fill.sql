-- Calendar gap fill.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE daily_sale (
    day TEXT PRIMARY KEY CHECK (day = DATE(day)),
    cents INTEGER NOT NULL CHECK (cents >= 0)
);
INSERT INTO daily_sale VALUES ('2026-01-01', 100), ('2026-01-03', 300), ('2026-01-05', 500);
-- Generate an inclusive date spine; limit both the range and recursion.
CREATE VIEW calendar_report AS
WITH RECURSIVE calendar(day, ordinal) AS (
    SELECT DATE('2026-01-01'), 1
    UNION ALL
    SELECT DATE(day, '+1 day'), ordinal + 1 FROM calendar
    WHERE day < DATE('2026-01-07') AND ordinal < 366
), filled AS (
    SELECT c.day, COALESCE(s.cents, 0) AS cents
    FROM calendar AS c LEFT JOIN daily_sale AS s USING (day)
)
SELECT day, cents,
       SUM(cents) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_cents,
       ROUND(AVG(cents) OVER (ORDER BY day ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS trailing_three_day_mean
FROM filled;
SELECT * FROM calendar_report ORDER BY day;
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM calendar_report) = 7);
INSERT INTO checks VALUES ((SELECT cents FROM calendar_report WHERE day = '2026-01-02') = 0);
INSERT INTO checks VALUES ((SELECT running_cents FROM calendar_report WHERE day = '2026-01-07') = 900);
INSERT INTO checks VALUES ((SELECT trailing_three_day_mean FROM calendar_report WHERE day = '2026-01-03') = 133.33);
-- ROWS is appropriate after the spine gives every day exactly one row.
COMMIT;
