-- Running balances.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE entry (
    id INTEGER PRIMARY KEY,
    account_id INTEGER NOT NULL,
    day TEXT NOT NULL,
    delta_cents INTEGER NOT NULL
);
INSERT INTO entry VALUES
    (1, 1, '2026-01-01', 10000), (2, 1, '2026-01-01', -1200),
    (3, 1, '2026-01-03', -500), (4, 2, '2026-01-02', 3000),
    (5, 2, '2026-01-01', 700), (6, 2, '2026-01-01', -700);
-- The id breaks timestamp ties, making running totals deterministic.
CREATE VIEW running_balance AS
SELECT *, SUM(delta_cents) OVER (
    PARTITION BY account_id ORDER BY day, id
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS balance_cents FROM entry;
SELECT account_id, id, day, delta_cents, balance_cents
FROM running_balance ORDER BY account_id, day, id;
INSERT INTO checks VALUES ((SELECT balance_cents FROM running_balance WHERE id = 2) = 8800);
INSERT INTO checks VALUES ((SELECT balance_cents FROM running_balance WHERE id = 3) = 8300);
INSERT INTO checks VALUES ((SELECT balance_cents FROM running_balance WHERE id = 4) = 3000);
INSERT INTO checks VALUES ((SELECT balance_cents FROM running_balance WHERE id = 5) = 700);
INSERT INTO checks VALUES ((SELECT balance_cents FROM running_balance WHERE id = 6) = 0);
-- End-of-day snapshots keep only the last posting per account and date.
CREATE VIEW end_of_day_balance AS
WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY account_id, day ORDER BY id DESC) AS position
    FROM running_balance
)
SELECT account_id, day, balance_cents FROM ranked WHERE position = 1;
SELECT account_id, day, balance_cents FROM end_of_day_balance ORDER BY account_id, day;
-- Literal expectations include shared dates, same-day ties and a zero balance.
CREATE TEMP TABLE expected_end_of_day(account_id INTEGER, day TEXT, balance_cents INTEGER,
    PRIMARY KEY(account_id, day));
INSERT INTO expected_end_of_day VALUES
    (1,'2026-01-01',8800),(1,'2026-01-03',8300),
    (2,'2026-01-01',0),(2,'2026-01-02',3000);
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM end_of_day_balance) = 4);
INSERT INTO checks VALUES (NOT EXISTS(SELECT * FROM end_of_day_balance EXCEPT SELECT * FROM expected_end_of_day));
INSERT INTO checks VALUES (NOT EXISTS(SELECT * FROM expected_end_of_day EXCEPT SELECT * FROM end_of_day_balance));
CREATE INDEX entry_account_order ON entry(account_id, day, id);
COMMIT;
