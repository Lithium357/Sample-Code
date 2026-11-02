-- Savepoints and rollback.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE wallet (id INTEGER PRIMARY KEY, cents INTEGER NOT NULL CHECK(cents >= 0));
CREATE TABLE transfer (id INTEGER PRIMARY KEY, sender INTEGER REFERENCES wallet(id),
    recipient INTEGER REFERENCES wallet(id), cents INTEGER NOT NULL CHECK(cents > 0));
INSERT INTO wallet VALUES (1, 1000), (2, 200);
SAVEPOINT transfer_attempt;
UPDATE wallet SET cents = cents - 300 WHERE id = 1;
UPDATE wallet SET cents = cents + 300 WHERE id = 2;
INSERT INTO transfer VALUES (1, 1, 2, 300);
-- Simulate a failed business validation after the writes.
ROLLBACK TO transfer_attempt;
RELEASE transfer_attempt;
INSERT INTO checks VALUES ((SELECT cents FROM wallet WHERE id = 1) = 1000);
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM transfer) = 0);
SAVEPOINT accepted_transfer;
UPDATE wallet SET cents = cents - 300 WHERE id = 1 AND cents >= 300;
-- The application must inspect changes() before proceeding with the credit.
INSERT INTO checks VALUES (changes() = 1);
UPDATE wallet SET cents = cents + 300 WHERE id = 2;
INSERT INTO transfer VALUES (1, 1, 2, 300);
RELEASE accepted_transfer;
INSERT INTO checks VALUES ((SELECT SUM(cents) FROM wallet) = 1200);
INSERT INTO checks VALUES ((SELECT cents FROM wallet WHERE id = 1) = 700);
INSERT INTO checks VALUES ((SELECT cents FROM wallet WHERE id = 2) = 500);
SELECT * FROM wallet ORDER BY id;
-- A savepoint can roll back a unit of work without aborting the outer transaction.
COMMIT;
