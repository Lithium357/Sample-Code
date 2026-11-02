-- Ledger reconciliation.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE internal_posting (reference TEXT PRIMARY KEY, cents INTEGER NOT NULL);
CREATE TABLE bank_posting (reference TEXT PRIMARY KEY, cents INTEGER NOT NULL);
INSERT INTO internal_posting VALUES ('A', 100), ('B', 200), ('C', 300);
INSERT INTO bank_posting VALUES ('A', 100), ('B', 250), ('D', 400);
CREATE VIEW reconciliation AS
WITH all_references AS (
    SELECT reference FROM internal_posting UNION SELECT reference FROM bank_posting
)
SELECT r.reference, i.cents AS internal_cents, b.cents AS bank_cents,
    CASE WHEN i.reference IS NULL THEN 'bank only'
         WHEN b.reference IS NULL THEN 'internal only'
         WHEN i.cents <> b.cents THEN 'amount mismatch'
         ELSE 'matched' END AS status,
    COALESCE(b.cents, 0) - COALESCE(i.cents, 0) AS difference_cents
FROM all_references AS r
LEFT JOIN internal_posting AS i USING(reference)
LEFT JOIN bank_posting AS b USING(reference);
SELECT * FROM reconciliation ORDER BY reference;
INSERT INTO checks VALUES ((SELECT status FROM reconciliation WHERE reference = 'A') = 'matched');
INSERT INTO checks VALUES ((SELECT status FROM reconciliation WHERE reference = 'B') = 'amount mismatch');
INSERT INTO checks VALUES ((SELECT status FROM reconciliation WHERE reference = 'C') = 'internal only');
INSERT INTO checks VALUES ((SELECT status FROM reconciliation WHERE reference = 'D') = 'bank only');
INSERT INTO checks VALUES ((SELECT SUM(difference_cents) FROM reconciliation) = 150);
-- UNION of keys works as a portable full-join strategy and preserves missing sides.
COMMIT;
