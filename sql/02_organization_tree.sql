-- Organization tree.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE employee (
    id INTEGER PRIMARY KEY,
    manager_id INTEGER REFERENCES employee(id),
    name TEXT NOT NULL,
    CHECK (manager_id IS NULL OR manager_id <> id)
);
INSERT INTO employee VALUES
    (1, NULL, 'Ari'), (2, 1, 'Blair'), (3, 1, 'Casey'),
    (4, 2, 'Drew'), (5, 4, 'Eden'), (6, 3, 'Fin');
-- A delimiter-bounded visited path prevents revisiting any ancestor.
CREATE VIEW organization AS
WITH RECURSIVE tree(id, manager_id, name, depth, visited, display_path) AS (
    SELECT id, manager_id, name, 0, '/' || id || '/', name
    FROM employee WHERE manager_id IS NULL
    UNION ALL
    SELECT e.id, e.manager_id, e.name, t.depth + 1,
           t.visited || e.id || '/', t.display_path || ' > ' || e.name
    FROM employee AS e JOIN tree AS t ON e.manager_id = t.id
    WHERE INSTR(t.visited, '/' || e.id || '/') = 0 AND t.depth < 100
)
SELECT * FROM tree;
SELECT name, depth, display_path FROM organization ORDER BY display_path;
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM organization) = 6);
INSERT INTO checks VALUES ((SELECT depth FROM organization WHERE id = 5) = 3);
INSERT INTO checks VALUES ((SELECT display_path FROM organization WHERE id = 6) = 'Ari > Casey > Fin');
CREATE INDEX employee_manager ON employee(manager_id);
-- Find employees unreachable from a root: useful when auditing bad imports.
SELECT e.* FROM employee AS e
WHERE NOT EXISTS (SELECT 1 FROM organization AS o WHERE o.id = e.id);
COMMIT;
