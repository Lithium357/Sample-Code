-- Inventory ledger.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE product (
    id INTEGER PRIMARY KEY,
    sku TEXT NOT NULL UNIQUE,
    reorder_level INTEGER NOT NULL CHECK (reorder_level >= 0)
);
CREATE TABLE movement (
    id INTEGER PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES product(id),
    quantity INTEGER NOT NULL CHECK (quantity <> 0),
    reason TEXT NOT NULL CHECK (reason IN ('receipt', 'sale', 'adjustment'))
);
INSERT INTO product VALUES (1, 'PENCIL', 10), (2, 'PAPER', 5), (3, 'ERASER', 2);
INSERT INTO movement VALUES
    (1, 1, 100, 'receipt'), (2, 1, -95, 'sale'),
    (3, 2, 20, 'receipt'), (4, 2, -2, 'sale');
-- LEFT JOIN retains products that have never had a movement.
CREATE VIEW stock AS
SELECT p.id, p.sku, p.reorder_level, COALESCE(SUM(m.quantity), 0) AS on_hand
FROM product AS p
LEFT JOIN movement AS m ON m.product_id = p.id
GROUP BY p.id, p.sku, p.reorder_level;
SELECT sku, on_hand, reorder_level - on_hand AS shortage
FROM stock WHERE on_hand < reorder_level ORDER BY sku;
INSERT INTO checks VALUES ((SELECT on_hand FROM stock WHERE id = 1) = 5);
INSERT INTO checks VALUES ((SELECT on_hand FROM stock WHERE id = 3) = 0);
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM stock WHERE on_hand < reorder_level) = 2);
-- The ledger preserves history; stock is derived rather than overwritten.
CREATE INDEX movement_product ON movement(product_id);
EXPLAIN QUERY PLAN SELECT SUM(quantity) FROM movement WHERE product_id = 1;
COMMIT;
