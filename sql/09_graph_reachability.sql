-- Graph reachability.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE edge (
    source INTEGER NOT NULL,
    target INTEGER NOT NULL,
    PRIMARY KEY(source, target), CHECK(source <> target)
);
INSERT INTO edge VALUES (1, 2), (2, 3), (3, 1), (2, 4), (4, 5), (8, 9);
CREATE VIEW reachable AS
WITH RECURSIVE walk(node) AS (
    VALUES(1)
    UNION
    SELECT e.target FROM edge AS e JOIN walk AS w ON e.source = w.node
)
SELECT node FROM walk;
-- UNION deduplicates visited nodes and makes this cyclic traversal terminate.
SELECT node FROM reachable ORDER BY node;
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM reachable) = 5);
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM reachable WHERE node = 8) = 0);
-- Enumerate simple paths separately; include a visited set and depth cap.
WITH RECURSIVE paths(node, route, depth) AS (
    VALUES(1, '/1/', 0)
    UNION ALL
    SELECT e.target, p.route || e.target || '/', p.depth + 1
    FROM paths AS p JOIN edge AS e ON p.node = e.source
    WHERE INSTR(p.route, '/' || e.target || '/') = 0 AND p.depth < 10
)
SELECT node, route, depth FROM paths ORDER BY depth, route;
CREATE INDEX edge_reverse ON edge(target, source);
COMMIT;
