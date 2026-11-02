-- Relational division.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE document (id INTEGER PRIMARY KEY, title TEXT NOT NULL);
CREATE TABLE tag (id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE);
CREATE TABLE document_tag (
    document_id INTEGER NOT NULL REFERENCES document(id),
    tag_id INTEGER NOT NULL REFERENCES tag(id),
    PRIMARY KEY(document_id, tag_id)
);
CREATE TABLE required_tag (tag_id INTEGER PRIMARY KEY REFERENCES tag(id));
INSERT INTO document VALUES (1, 'SQL guide'), (2, 'SQLite windows'), (3, 'Shell guide');
INSERT INTO tag VALUES (1, 'database'), (2, 'tutorial'), (3, 'shell');
INSERT INTO document_tag VALUES (1, 1), (1, 2), (2, 1), (3, 2), (3, 3);
INSERT INTO required_tag VALUES (1), (2);
-- Select documents for which no required tag is missing.
CREATE VIEW matching_document AS
SELECT d.* FROM document AS d
WHERE NOT EXISTS (
    SELECT 1 FROM required_tag AS r
    WHERE NOT EXISTS (
        SELECT 1 FROM document_tag AS dt WHERE dt.document_id = d.id AND dt.tag_id = r.tag_id
    )
);
SELECT * FROM matching_document ORDER BY id;
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM matching_document) = 1);
INSERT INTO checks VALUES ((SELECT id FROM matching_document) = 1);
DELETE FROM required_tag;
-- Universal quantification over an empty requirement set matches everything.
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM matching_document) = 3);
CREATE INDEX document_tag_reverse ON document_tag(tag_id, document_id);
COMMIT;
