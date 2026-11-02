-- Keyset pagination.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE article (
    id INTEGER PRIMARY KEY,
    published_at INTEGER NOT NULL,
    title TEXT NOT NULL
);
INSERT INTO article VALUES
    (1, 100, 'Alpha'), (2, 100, 'Beta'), (3, 200, 'Gamma'),
    (4, 200, 'Delta'), (5, 300, 'Epsilon');
CREATE INDEX article_order ON article(published_at DESC, id DESC);
CREATE TEMP TABLE first_page AS
SELECT * FROM article ORDER BY published_at DESC, id DESC LIMIT 2;
-- The next cursor is the final (published_at,id) pair from the first page.
CREATE TEMP TABLE cursor AS
SELECT published_at, id FROM first_page ORDER BY published_at, id LIMIT 1;
CREATE TEMP TABLE second_page AS
SELECT a.* FROM article AS a CROSS JOIN cursor AS c
WHERE (a.published_at, a.id) < (c.published_at, c.id)
ORDER BY a.published_at DESC, a.id DESC LIMIT 2;
SELECT * FROM first_page ORDER BY published_at DESC, id DESC;
SELECT * FROM second_page ORDER BY published_at DESC, id DESC;
INSERT INTO checks VALUES ((SELECT GROUP_CONCAT(id, ',') FROM (SELECT id FROM first_page ORDER BY published_at DESC, id DESC)) = '5,4');
INSERT INTO checks VALUES ((SELECT GROUP_CONCAT(id, ',') FROM (SELECT id FROM second_page ORDER BY published_at DESC, id DESC)) = '3,2');
INSERT INTO checks VALUES (NOT EXISTS (SELECT id FROM first_page INTERSECT SELECT id FROM second_page));
-- A unique tie-breaker prevents duplicate timestamps from skipping rows.
-- Across separate requests, use a snapshot boundary if insert consistency matters.
COMMIT;
