-- SQLite 3.35+: transactional outbox, expiring leases and fencing tokens.
-- Delivery is at-least-once. Real consumers deduplicate using the event id;
-- no transaction can atomically commit both SQLite and an arbitrary HTTP call.
PRAGMA foreign_keys=ON;
BEGIN IMMEDIATE;
CREATE TEMP TABLE checks(ok INTEGER NOT NULL CHECK(ok=1));
CREATE TABLE clock(now INTEGER NOT NULL CHECK(now>=0));
INSERT INTO clock VALUES(100);
CREATE TABLE purchase(id INTEGER PRIMARY KEY, cents INTEGER NOT NULL CHECK(cents>0));
CREATE TABLE outbox(
    id INTEGER PRIMARY KEY,
    purchase_id INTEGER NOT NULL UNIQUE REFERENCES purchase(id),
    payload TEXT NOT NULL,
    available_at INTEGER NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0 CHECK(attempts>=0),
    lease_owner TEXT,
    lease_until INTEGER,
    token INTEGER NOT NULL DEFAULT 0,
    delivered_at INTEGER,
    CHECK((lease_owner IS NULL)=(lease_until IS NULL))
);
CREATE INDEX claimable ON outbox(available_at,id) WHERE delivered_at IS NULL;
-- Domain state and event insertion share one transaction: neither can survive
-- without the other. A savepoint demonstrates rollback of both together.
SAVEPOINT rejected_purchase;
INSERT INTO purchase VALUES(99,123);
INSERT INTO outbox(id,purchase_id,payload,available_at) VALUES(99,99,'cancelled',100);
ROLLBACK TO rejected_purchase;
RELEASE rejected_purchase;
INSERT INTO checks VALUES(NOT EXISTS(SELECT 1 FROM outbox WHERE id=99));
INSERT INTO checks VALUES(NOT EXISTS(SELECT 1 FROM purchase WHERE id=99));
INSERT INTO purchase VALUES(1,1000),(2,2000),(3,3000);
INSERT INTO outbox(id,purchase_id,payload,available_at) VALUES
    (1,1,'purchase:1',100),(2,2,'purchase:2',100),(3,3,'purchase:3',200);
-- Claim and fencing-token increment are one write statement. Separate workers
-- use separate connections; SQLite serializes their BEGIN IMMEDIATE writers.
UPDATE outbox SET lease_owner='worker-a',lease_until=(SELECT now+10 FROM clock),
    token=token+1,attempts=attempts+1
WHERE id IN (
    SELECT id FROM outbox WHERE delivered_at IS NULL
    AND available_at<=(SELECT now FROM clock)
    AND (lease_until IS NULL OR lease_until<=(SELECT now FROM clock))
    ORDER BY available_at,id LIMIT 2
) RETURNING id,payload,token;
INSERT INTO checks VALUES((SELECT COUNT(*) FROM outbox WHERE lease_owner='worker-a')=2);
-- Another claimant cannot steal an unexpired lease.
UPDATE outbox SET lease_owner='worker-b',lease_until=110,token=token+1,attempts=attempts+1
WHERE id=1 AND delivered_at IS NULL AND (lease_until IS NULL OR lease_until<=100);
INSERT INTO checks VALUES(changes()=0);
-- Acknowledgement includes owner, token and unexpired lease predicates.
UPDATE outbox SET delivered_at=100,lease_owner=NULL,lease_until=NULL
WHERE id=1 AND lease_owner='worker-a' AND token=1 AND lease_until>100;
INSERT INTO checks VALUES(changes()=1);
UPDATE clock SET now=111;
UPDATE outbox SET lease_owner='worker-b',lease_until=121,token=token+1,attempts=attempts+1
WHERE id=2 AND delivered_at IS NULL AND lease_until<=(SELECT now FROM clock);
INSERT INTO checks VALUES((SELECT token FROM outbox WHERE id=2)=2);
-- The old worker wakes after its lease expired: its token cannot acknowledge
-- or release the replacement worker's ownership.
UPDATE outbox SET delivered_at=111,lease_owner=NULL,lease_until=NULL
WHERE id=2 AND lease_owner='worker-a' AND token=1 AND lease_until>111;
INSERT INTO checks VALUES(changes()=0);
UPDATE outbox SET lease_owner=NULL,lease_until=NULL,available_at=116
WHERE id=2 AND lease_owner='worker-b' AND token=2;
INSERT INTO checks VALUES(changes()=1);
INSERT INTO checks VALUES((SELECT attempts FROM outbox WHERE id=2)=2);
INSERT INTO checks VALUES((SELECT COUNT(*) FROM outbox WHERE delivered_at IS NULL AND available_at<=111)=0);
UPDATE clock SET now=116;
INSERT INTO checks VALUES((SELECT COUNT(*) FROM outbox WHERE delivered_at IS NULL AND available_at<=(SELECT now FROM clock))=1);
SELECT id,attempts,token,available_at,delivered_at FROM outbox ORDER BY id;
COMMIT;
