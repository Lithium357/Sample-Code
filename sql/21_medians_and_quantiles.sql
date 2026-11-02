-- Medians and quantiles.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE observation (id INTEGER PRIMARY KEY, segment TEXT NOT NULL, value INTEGER NOT NULL);
INSERT INTO observation VALUES
    (1, 'odd', 1), (2, 'odd', 5), (3, 'odd', 9),
    (4, 'even', 2), (5, 'even', 4), (6, 'even', 8), (7, 'even', 10);
CREATE VIEW median_value AS
WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY segment ORDER BY value, id) AS position,
        COUNT(*) OVER (PARTITION BY segment) AS size FROM observation
)
SELECT segment, AVG(value * 1.0) AS median FROM ranked
WHERE position IN ((size + 1) / 2, (size + 2) / 2) GROUP BY segment;
SELECT * FROM median_value ORDER BY segment;
INSERT INTO checks VALUES ((SELECT median FROM median_value WHERE segment = 'odd') = 5.0);
INSERT INTO checks VALUES ((SELECT median FROM median_value WHERE segment = 'even') = 6.0);
-- Nearest-rank 75th percentile uses ceil(3*N/4), expressed in integers.
WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY segment ORDER BY value, id) AS position,
        COUNT(*) OVER (PARTITION BY segment) AS size FROM observation
)
SELECT segment, value AS percentile_75 FROM ranked WHERE position = (3 * size + 3) / 4
ORDER BY segment;
-- Different percentile definitions may interpolate; this one deliberately does not.
COMMIT;
