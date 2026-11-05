-- Ranking with ties.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE score (
    contestant TEXT PRIMARY KEY,
    division TEXT NOT NULL,
    points INTEGER NOT NULL CHECK(points >= 0)
);
INSERT INTO score VALUES
    ('Ari', 'red', 100), ('Blair', 'red', 90), ('Casey', 'red', 90), ('Drew', 'red', 80),
    ('Eden', 'blue', 80), ('Fin', 'blue', 80), ('Gale', 'blue', 70);
CREATE VIEW standings AS
SELECT *,
    RANK() OVER (PARTITION BY division ORDER BY points DESC) AS competition_rank,
    DENSE_RANK() OVER (PARTITION BY division ORDER BY points DESC) AS dense_rank,
    ROW_NUMBER() OVER (PARTITION BY division ORDER BY points DESC, contestant) AS deterministic_row
FROM score;
-- RANK preserves competition gaps; DENSE_RANK counts distinct score levels.
SELECT * FROM standings ORDER BY division, deterministic_row;
CREATE VIEW top_division_scores AS
SELECT division, contestant, points FROM standings
WHERE dense_rank <= 3 ORDER BY division, points DESC, contestant;
SELECT * FROM top_division_scores ORDER BY division, points DESC, contestant;
INSERT INTO checks VALUES ((SELECT competition_rank FROM standings WHERE contestant = 'Drew') = 4);
INSERT INTO checks VALUES ((SELECT dense_rank FROM standings WHERE contestant = 'Drew') = 3);
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM standings WHERE division = 'red' AND dense_rank <= 2) = 3);
INSERT INTO checks VALUES ((SELECT deterministic_row FROM standings WHERE contestant = 'Fin') = 2);
CREATE TEMP TABLE expected_top(division TEXT, contestant TEXT, points INTEGER);
INSERT INTO expected_top VALUES ('blue','Eden',80),('blue','Fin',80),('blue','Gale',70),
    ('red','Ari',100),('red','Blair',90),('red','Casey',90);
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM top_division_scores) = 6);
INSERT INTO checks VALUES (NOT EXISTS(SELECT * FROM top_division_scores EXCEPT SELECT * FROM expected_top));
INSERT INTO checks VALUES (NOT EXISTS(SELECT * FROM expected_top EXCEPT SELECT * FROM top_division_scores));
-- Do not add contestant to the ranking ORDER BY: that would break score ties.
COMMIT;
