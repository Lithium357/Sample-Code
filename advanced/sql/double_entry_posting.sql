-- SQLite: double-entry journal with deferred posting and immutable posted lines.
-- sqlite3 :memory: ".bail on" ".read double_entry_posting.sql"
-- Currency is integer cents. A journal is prepared as draft, then posted only
-- when balanced. This simplified ledger represents one currency and no FX.
PRAGMA foreign_keys=ON;
BEGIN;
CREATE TEMP TABLE checks(ok INTEGER NOT NULL CHECK(ok=1));
CREATE TABLE account(id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE);
CREATE TABLE journal(id INTEGER PRIMARY KEY, external_key TEXT NOT NULL UNIQUE,
    state TEXT NOT NULL DEFAULT 'draft' CHECK(state IN ('draft','posted')));
CREATE TABLE line(id INTEGER PRIMARY KEY, journal_id INTEGER NOT NULL REFERENCES journal(id),
    account_id INTEGER NOT NULL REFERENCES account(id),
    debit INTEGER NOT NULL DEFAULT 0, credit INTEGER NOT NULL DEFAULT 0,
    CHECK(debit BETWEEN 0 AND 1000000000 AND credit BETWEEN 0 AND 1000000000),
    CHECK((debit>0 AND credit=0) OR (credit>0 AND debit=0)));
CREATE TRIGGER new_journal_must_be_draft BEFORE INSERT ON journal
WHEN NEW.state<>'draft'
BEGIN SELECT RAISE(ABORT,'create a draft before posting'); END;
CREATE TRIGGER posted_journal_immutable BEFORE UPDATE ON journal
WHEN OLD.state='posted'
BEGIN SELECT RAISE(ABORT,'posted journals are immutable'); END;
CREATE TRIGGER cannot_delete_posted_journal BEFORE DELETE ON journal
WHEN OLD.state='posted'
BEGIN SELECT RAISE(ABORT,'cannot delete posted journal'); END;
CREATE TRIGGER validate_post BEFORE UPDATE OF state ON journal
WHEN NEW.state='posted' AND (
    (SELECT COUNT(*) FROM line WHERE journal_id=OLD.id)<2 OR
    (SELECT SUM(debit-credit) FROM line WHERE journal_id=OLD.id)<>0)
BEGIN SELECT RAISE(ABORT,'journal must contain balanced lines'); END;
CREATE TRIGGER insert_line_guard BEFORE INSERT ON line
WHEN (SELECT state FROM journal WHERE id=NEW.journal_id)<>'draft'
BEGIN SELECT RAISE(ABORT,'posted lines are immutable'); END;
CREATE TRIGGER update_line_guard BEFORE UPDATE ON line
WHEN (SELECT state FROM journal WHERE id=OLD.journal_id)<>'draft'
  OR (SELECT state FROM journal WHERE id=NEW.journal_id)<>'draft'
BEGIN SELECT RAISE(ABORT,'posted lines are immutable'); END;
CREATE TRIGGER delete_line_guard BEFORE DELETE ON line
WHEN (SELECT state FROM journal WHERE id=OLD.journal_id)<>'draft'
BEGIN SELECT RAISE(ABORT,'posted lines are immutable'); END;
INSERT INTO account VALUES(1,'Cash'),(2,'Sales'),(3,'Expenses');
INSERT INTO journal(id,external_key) VALUES(1,'sale-001'),(2,'expense-001'),(3,'unposted');
INSERT INTO line VALUES(1,1,1,10000,0),(2,1,2,0,10000),
    (3,2,3,2500,0),(4,2,1,0,2500),(5,3,1,999,0);
UPDATE journal SET state='posted' WHERE id IN (1,2);
CREATE VIEW balance AS
SELECT a.id,a.name,COALESCE(SUM(CASE WHEN j.state='posted' THEN l.debit-l.credit ELSE 0 END),0) AS cents
FROM account a LEFT JOIN line l ON l.account_id=a.id
LEFT JOIN journal j ON j.id=l.journal_id GROUP BY a.id,a.name;
INSERT INTO checks VALUES((SELECT cents FROM balance WHERE id=1)=7500);
INSERT INTO checks VALUES((SELECT SUM(cents) FROM balance)=0);
INSERT INTO checks VALUES((SELECT COUNT(*) FROM journal WHERE state='posted')=2);
-- Draft lines can still be corrected; they never leak into posted balances.
UPDATE line SET debit=1000 WHERE id=5;
INSERT INTO checks VALUES((SELECT cents FROM balance WHERE id=1)=7500);
-- Reversal is a new balanced journal, preserving the original accounting trail.
INSERT INTO journal(id,external_key) VALUES(4,'reverse-expense-001');
INSERT INTO line(journal_id,account_id,debit,credit)
SELECT 4,account_id,credit,debit FROM line WHERE journal_id=2;
UPDATE journal SET state='posted' WHERE id=4;
INSERT INTO checks VALUES((SELECT cents FROM balance WHERE id=1)=10000);
INSERT INTO checks VALUES((SELECT cents FROM balance WHERE id=3)=0);
SELECT * FROM balance ORDER BY id;
COMMIT;
