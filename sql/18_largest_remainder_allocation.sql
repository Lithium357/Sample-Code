-- Largest remainder allocation.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE weight (recipient TEXT PRIMARY KEY, units INTEGER NOT NULL CHECK(units > 0));
CREATE TABLE budget (cents INTEGER NOT NULL CHECK(cents >= 0));
INSERT INTO weight VALUES ('Ari', 1), ('Blair', 1), ('Casey', 1);
INSERT INTO budget VALUES (100);
-- Allocate integer cents proportionally, then give leftover cents to the
-- largest fractional remainders. Recipient name breaks exact ties.
CREATE VIEW payout AS
WITH totals AS (
    SELECT SUM(units) AS total_units FROM weight
), raw AS (
    SELECT recipient, b.cents * w.units / t.total_units AS floor_cents,
           b.cents * w.units % t.total_units AS remainder
    FROM weight AS w CROSS JOIN budget AS b CROSS JOIN totals AS t
), ranked AS (
    SELECT *, ROW_NUMBER() OVER (ORDER BY remainder DESC, recipient) AS position,
           SUM(floor_cents) OVER () AS allocated_floor FROM raw
)
SELECT recipient, floor_cents + CASE WHEN position <= b.cents - allocated_floor
    THEN 1 ELSE 0 END AS cents FROM ranked CROSS JOIN budget AS b;
SELECT * FROM payout ORDER BY recipient;
INSERT INTO checks VALUES ((SELECT SUM(cents) FROM payout) = 100);
INSERT INTO checks VALUES ((SELECT cents FROM payout WHERE recipient = 'Ari') = 34);
INSERT INTO checks VALUES ((SELECT cents FROM payout WHERE recipient = 'Blair') = 33);
UPDATE weight SET units = 2 WHERE recipient = 'Casey';
INSERT INTO checks VALUES ((SELECT cents FROM payout WHERE recipient = 'Casey') = 50);
INSERT INTO checks VALUES ((SELECT SUM(cents) FROM payout) = 100);
-- Keep cents*units below signed 64-bit overflow; no floating arithmetic is needed.
COMMIT;
