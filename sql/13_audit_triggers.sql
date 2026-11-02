-- Audit triggers.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE task (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('queued', 'active', 'done'))
);
CREATE TABLE status_history (
    sequence INTEGER PRIMARY KEY,
    task_id INTEGER NOT NULL REFERENCES task(id),
    old_status TEXT NOT NULL,
    new_status TEXT NOT NULL
);
CREATE TRIGGER record_status_change AFTER UPDATE OF status ON task
WHEN OLD.status <> NEW.status
BEGIN
    INSERT INTO status_history(task_id, old_status, new_status)
    VALUES(NEW.id, OLD.status, NEW.status);
END;
CREATE TRIGGER prevent_reopening BEFORE UPDATE OF status ON task
WHEN OLD.status = 'done' AND NEW.status <> 'done'
BEGIN
    SELECT RAISE(ABORT, 'completed tasks cannot be reopened');
END;
INSERT INTO task VALUES (1, 'Import catalog', 'queued');
UPDATE task SET status = 'active' WHERE id = 1;
UPDATE task SET title = 'Import verified catalog' WHERE id = 1;
UPDATE task SET status = 'active' WHERE id = 1;
UPDATE task SET status = 'done' WHERE id = 1;
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM status_history) = 2);
INSERT INTO checks VALUES ((SELECT new_status FROM status_history ORDER BY sequence DESC LIMIT 1) = 'done');
SELECT t.title, h.old_status, h.new_status FROM status_history AS h
JOIN task AS t ON t.id = h.task_id ORDER BY h.sequence;
-- No-op updates and unrelated columns do not create history noise.
COMMIT;
