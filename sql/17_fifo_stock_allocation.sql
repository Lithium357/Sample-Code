-- Fifo stock allocation.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE lot (
    id INTEGER PRIMARY KEY,
    arrived_at INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK(quantity > 0)
);
CREATE TABLE demand (requested INTEGER NOT NULL CHECK(requested >= 0));
INSERT INTO lot VALUES (1, 100, 5), (2, 200, 8), (3, 200, 4);
INSERT INTO demand VALUES (10);
-- Map each lot to an interval in cumulative inventory order.
CREATE VIEW allocation AS
WITH cumulative AS (
    SELECT *, SUM(quantity) OVER (
        ORDER BY arrived_at, id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS end_unit FROM lot
), intervals AS (
    SELECT *, end_unit - quantity AS start_unit FROM cumulative
)
SELECT i.id, i.quantity, i.start_unit, i.end_unit,
    MAX(0, MIN(i.end_unit, d.requested) - i.start_unit) AS allocated
FROM intervals AS i CROSS JOIN demand AS d;
SELECT * FROM allocation ORDER BY start_unit;
INSERT INTO checks VALUES ((SELECT allocated FROM allocation WHERE id = 1) = 5);
INSERT INTO checks VALUES ((SELECT allocated FROM allocation WHERE id = 2) = 5);
INSERT INTO checks VALUES ((SELECT allocated FROM allocation WHERE id = 3) = 0);
INSERT INTO checks VALUES ((SELECT SUM(allocated) FROM allocation) = 10);
UPDATE demand SET requested = 30;
INSERT INTO checks VALUES ((SELECT SUM(allocated) FROM allocation) = 17);
SELECT MAX(0, requested - (SELECT SUM(quantity) FROM lot)) AS unfilled FROM demand;
-- Real stock reservation also needs a transaction and write-side concurrency rules.
COMMIT;
