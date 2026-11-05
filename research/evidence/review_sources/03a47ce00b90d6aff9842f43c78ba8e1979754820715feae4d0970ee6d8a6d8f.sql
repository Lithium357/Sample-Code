-- Conditional pivot.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE response (
    person_id INTEGER NOT NULL,
    question TEXT NOT NULL CHECK(question IN ('speed', 'quality', 'support')),
    rating INTEGER NOT NULL CHECK(rating BETWEEN 1 AND 5),
    PRIMARY KEY(person_id, question)
);
INSERT INTO response VALUES
    (1, 'speed', 4), (1, 'quality', 5), (1, 'support', 3),
    (2, 'speed', 2), (2, 'quality', 4), (3, 'support', 5);
CREATE VIEW wide_response AS
SELECT person_id,
    MAX(CASE WHEN question = 'speed' THEN rating END) AS speed,
    MAX(CASE WHEN question = 'quality' THEN rating END) AS quality,
    MAX(CASE WHEN question = 'support' THEN rating END) AS support,
    COUNT(*) AS answered_questions
FROM response GROUP BY person_id;
SELECT * FROM wide_response ORDER BY person_id;
INSERT INTO checks VALUES ((SELECT quality FROM wide_response WHERE person_id = 1) = 5);
INSERT INTO checks VALUES ((SELECT support FROM wide_response WHERE person_id = 2) IS NULL);
INSERT INTO checks VALUES ((SELECT answered_questions FROM wide_response WHERE person_id = 3) = 1);
-- Missing answers remain NULL instead of being turned into artificial zeros.
CREATE VIEW question_summary AS
SELECT question, COUNT(*) AS responses, ROUND(AVG(rating), 2) AS mean_rating,
    SUM(CASE WHEN rating >= 4 THEN 1 ELSE 0 END) AS positive_responses
FROM response GROUP BY question ORDER BY question;
SELECT * FROM question_summary ORDER BY question;
CREATE TEMP TABLE expected_summary(question TEXT, responses INTEGER, mean_rating REAL, positive_responses INTEGER);
INSERT INTO expected_summary VALUES ('quality',2,4.5,2),('speed',2,3.0,1),('support',2,4.0,1);
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM question_summary) = 3);
INSERT INTO checks VALUES (NOT EXISTS(SELECT * FROM question_summary EXCEPT SELECT * FROM expected_summary));
INSERT INTO checks VALUES (NOT EXISTS(SELECT * FROM expected_summary EXCEPT SELECT * FROM question_summary));
-- The unique person/question key makes MAX an unambiguous pivot operation.
COMMIT;
