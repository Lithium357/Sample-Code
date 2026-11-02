-- Cleaning staged records.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE staging (id INTEGER PRIMARY KEY, email TEXT, age_text TEXT);
INSERT INTO staging VALUES
    (1, ' ARI@example.test ', '32'), (2, '', '22'), (3, NULL, '18'),
    (4, 'blair@example.test', 'twenty'), (5, 'casey@example.test', '0'),
    (6, 'drew@example.test', '12x');
CREATE VIEW classified AS
SELECT *, LOWER(TRIM(email)) AS normalized_email,
    CASE
        WHEN NULLIF(TRIM(email), '') IS NULL THEN 'missing email'
        WHEN age_text IS NULL OR age_text = '' THEN 'missing age'
        WHEN age_text GLOB '*[^0-9]*' THEN 'non-numeric age'
        WHEN CAST(age_text AS INTEGER) > 130 THEN 'age out of range'
        ELSE NULL
    END AS rejection FROM staging;
CREATE TABLE person (id INTEGER PRIMARY KEY, email TEXT NOT NULL, age INTEGER NOT NULL CHECK(age BETWEEN 0 AND 130));
INSERT INTO person SELECT id, normalized_email, CAST(age_text AS INTEGER)
FROM classified WHERE rejection IS NULL;
SELECT id, rejection FROM classified WHERE rejection IS NOT NULL ORDER BY id;
SELECT * FROM person ORDER BY id;
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM person) = 2);
INSERT INTO checks VALUES ((SELECT email FROM person WHERE id = 1) = 'ari@example.test');
INSERT INTO checks VALUES ((SELECT age FROM person WHERE id = 5) = 0);
INSERT INTO checks VALUES ((SELECT rejection FROM classified WHERE id = 6) = 'non-numeric age');
-- SQLite CAST('12x' AS INTEGER) gives 12, so validate syntax before casting.
-- Email normalization here is a data-cleaning example, not complete validation.
COMMIT;
