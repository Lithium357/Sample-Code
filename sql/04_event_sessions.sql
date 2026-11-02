-- Event sessions.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE event (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    occurred_at INTEGER NOT NULL CHECK (occurred_at >= 0)
);
INSERT INTO event VALUES
    (1, 10, 0), (2, 10, 600), (3, 10, 2500), (4, 10, 2600),
    (5, 20, 100), (6, 20, 1900), (7, 20, 3701);
-- Times are integer seconds. A gap strictly greater than 1800 starts a session.
CREATE VIEW session_event AS
WITH lagged AS (
    SELECT *, LAG(occurred_at) OVER (PARTITION BY user_id ORDER BY occurred_at, id) AS previous_at
    FROM event
), marked AS (
    SELECT *, CASE WHEN previous_at IS NULL OR occurred_at - previous_at > 1800
                   THEN 1 ELSE 0 END AS starts_session
    FROM lagged
)
SELECT *, SUM(starts_session) OVER (
    PARTITION BY user_id ORDER BY occurred_at, id
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS session_number FROM marked;
SELECT user_id, session_number, MIN(occurred_at) AS started_at,
       MAX(occurred_at) AS ended_at, COUNT(*) AS event_count
FROM session_event GROUP BY user_id, session_number ORDER BY user_id, session_number;
INSERT INTO checks VALUES ((SELECT MAX(session_number) FROM session_event WHERE user_id = 10) = 2);
INSERT INTO checks VALUES ((SELECT session_number FROM session_event WHERE id = 6) = 1);
INSERT INTO checks VALUES ((SELECT session_number FROM session_event WHERE id = 7) = 2);
CREATE INDEX event_user_time ON event(user_id, occurred_at, id);
COMMIT;
