-- Effective dated prices.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE price (
    product_id INTEGER NOT NULL,
    valid_from INTEGER NOT NULL,
    valid_to INTEGER,
    cents INTEGER NOT NULL CHECK(cents >= 0),
    PRIMARY KEY(product_id, valid_from),
    CHECK(valid_to IS NULL OR valid_to > valid_from)
);
CREATE TABLE purchase (id INTEGER PRIMARY KEY, product_id INTEGER NOT NULL, purchased_at INTEGER NOT NULL);
INSERT INTO price VALUES (1, 0, 100, 500), (1, 100, 200, 600), (1, 200, NULL, 700);
-- Unpurchased products exercise a true overlap and a touching non-overlap.
INSERT INTO price VALUES (3,0,150,100),(3,100,200,120),(4,0,100,50),(4,100,200,60);
INSERT INTO purchase VALUES (1, 1, 99), (2, 1, 100), (3, 1, 200), (4, 2, 150);
-- Half-open intervals [from,to) assign a boundary instant to exactly one price.
CREATE VIEW priced_purchase AS
SELECT s.id, s.product_id, s.purchased_at, p.cents
FROM purchase AS s LEFT JOIN price AS p
ON p.product_id = s.product_id AND s.purchased_at >= p.valid_from
AND (p.valid_to IS NULL OR s.purchased_at < p.valid_to);
SELECT * FROM priced_purchase ORDER BY id;
INSERT INTO checks VALUES ((SELECT cents FROM priced_purchase WHERE id = 1) = 500);
INSERT INTO checks VALUES ((SELECT cents FROM priced_purchase WHERE id = 2) = 600);
INSERT INTO checks VALUES ((SELECT cents FROM priced_purchase WHERE id = 3) = 700);
INSERT INTO checks VALUES ((SELECT cents FROM priced_purchase WHERE id = 4) IS NULL);
-- Audit overlap; production writers must enforce this invariant atomically.
CREATE VIEW price_overlap_audit AS
SELECT a.product_id, a.valid_from AS earlier_from, b.valid_from AS later_from FROM price AS a JOIN price AS b
ON a.product_id = b.product_id AND a.valid_from < b.valid_from
AND (a.valid_to IS NULL OR b.valid_from < a.valid_to);
SELECT * FROM price_overlap_audit ORDER BY product_id, earlier_from, later_from;
CREATE TEMP TABLE expected_overlap(product_id INTEGER, earlier_from INTEGER, later_from INTEGER);
INSERT INTO expected_overlap VALUES (3,0,100);
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM price_overlap_audit) = 1);
INSERT INTO checks VALUES (NOT EXISTS(SELECT * FROM price_overlap_audit EXCEPT SELECT * FROM expected_overlap));
INSERT INTO checks VALUES (NOT EXISTS(SELECT * FROM expected_overlap EXCEPT SELECT * FROM price_overlap_audit));
COMMIT;
