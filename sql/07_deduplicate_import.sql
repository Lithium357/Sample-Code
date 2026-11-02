-- Deduplicate import.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE incoming (
    source_id INTEGER PRIMARY KEY,
    email TEXT NOT NULL,
    updated_at INTEGER NOT NULL,
    display_name TEXT NOT NULL
);
INSERT INTO incoming VALUES
    (1, ' Ari@example.test ', 100, 'Old Ari'),
    (2, 'ari@example.test', 200, 'Ari'),
    (3, 'BLAIR@example.test', 200, 'Blair'),
    (4, 'ari@example.test', 200, 'Ari Latest');
CREATE TABLE contact (
    email TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    source_id INTEGER NOT NULL UNIQUE
);
-- Normalize the natural key, then resolve equal timestamps by source id.
WITH ranked AS (
    SELECT LOWER(TRIM(email)) AS normalized_email, display_name, source_id,
           ROW_NUMBER() OVER (
               PARTITION BY LOWER(TRIM(email)) ORDER BY updated_at DESC, source_id DESC
           ) AS position FROM incoming
)
INSERT INTO contact(email, display_name, source_id)
SELECT normalized_email, display_name, source_id FROM ranked WHERE position = 1;
SELECT * FROM contact ORDER BY email;
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM contact) = 2);
INSERT INTO checks VALUES ((SELECT source_id FROM contact WHERE email = 'ari@example.test') = 4);
-- Report discarded rows separately so the import remains explainable.
SELECT i.source_id, i.email FROM incoming AS i
WHERE NOT EXISTS (SELECT 1 FROM contact AS c WHERE c.source_id = i.source_id)
ORDER BY i.source_id;
COMMIT;
