-- Recursive bill-of-materials explosion with shared subassemblies and cycle guards.
-- SQLite 3.25+; quantities are small bounded integers, not arbitrary-precision.
PRAGMA foreign_keys=ON;
BEGIN;
CREATE TEMP TABLE checks(ok INTEGER NOT NULL CHECK(ok=1));
CREATE TABLE part(id INTEGER PRIMARY KEY, sku TEXT NOT NULL UNIQUE,
    assembly INTEGER NOT NULL CHECK(assembly IN (0,1)));
CREATE TABLE component(parent INTEGER NOT NULL REFERENCES part(id),
    child INTEGER NOT NULL REFERENCES part(id),
    quantity INTEGER NOT NULL CHECK(quantity BETWEEN 1 AND 1000),
    PRIMARY KEY(parent,child), CHECK(parent<>child));
CREATE TRIGGER validate_component_insert BEFORE INSERT ON component
BEGIN
    SELECT CASE WHEN (SELECT assembly FROM part WHERE id=NEW.parent)<>1
        THEN RAISE(ABORT,'raw material cannot contain components') END;
    SELECT CASE WHEN EXISTS(
        WITH RECURSIVE reachable(id) AS (
            SELECT NEW.child UNION
            SELECT c.child FROM component c JOIN reachable r ON c.parent=r.id
        ) SELECT 1 FROM reachable WHERE id=NEW.parent
    ) THEN RAISE(ABORT,'component cycle') END;
END;
CREATE TRIGGER validate_component_update BEFORE UPDATE ON component
BEGIN
    SELECT CASE WHEN (SELECT assembly FROM part WHERE id=NEW.parent)<>1
        THEN RAISE(ABORT,'raw material cannot contain components') END;
    SELECT CASE WHEN EXISTS(
        WITH RECURSIVE reachable(id) AS (
            SELECT NEW.child UNION
            SELECT c.child FROM component c JOIN reachable r ON c.parent=r.id
            WHERE NOT(c.parent=OLD.parent AND c.child=OLD.child)
        ) SELECT 1 FROM reachable WHERE id=NEW.parent
    ) THEN RAISE(ABORT,'component cycle') END;
END;
CREATE TRIGGER part_kind_immutable_with_components BEFORE UPDATE OF assembly ON part
WHEN NEW.assembly=0 AND EXISTS(SELECT 1 FROM component WHERE parent=OLD.id)
BEGIN SELECT RAISE(ABORT,'assembly still has components'); END;
INSERT INTO part VALUES(1,'BIKE',1),(2,'WHEEL',1),(3,'FRAME',1),
    (4,'RIM',0),(5,'SPOKE',0),(6,'HUB',0),(7,'TUBE',0),(8,'BOLT',0);
INSERT INTO component VALUES(1,2,2),(1,3,1),(1,8,4),
    (2,4,1),(2,5,20),(2,6,1),(2,8,2),(3,7,3);
CREATE TABLE demand(part_id INTEGER REFERENCES part(id), units INTEGER NOT NULL CHECK(units>0));
INSERT INTO demand VALUES(1,3),(2,1);
-- UNION ALL is essential: merging visits would lose quantities when the same
-- raw component is reached by several different branches of the assembly DAG.
CREATE VIEW requirement AS
WITH RECURSIVE explosion(part_id,units,depth) AS (
    SELECT part_id,units,0 FROM demand
    UNION ALL
    SELECT c.child,e.units*c.quantity,e.depth+1
    FROM explosion e JOIN component c ON c.parent=e.part_id
)
SELECT p.sku,SUM(e.units) AS required
FROM explosion e JOIN part p ON p.id=e.part_id
WHERE p.assembly=0 GROUP BY p.id,p.sku;
INSERT INTO checks VALUES((SELECT required FROM requirement WHERE sku='SPOKE')=140);
INSERT INTO checks VALUES((SELECT required FROM requirement WHERE sku='RIM')=7);
INSERT INTO checks VALUES((SELECT required FROM requirement WHERE sku='TUBE')=9);
INSERT INTO checks VALUES((SELECT required FROM requirement WHERE sku='BOLT')=26);
CREATE TABLE on_hand(sku TEXT PRIMARY KEY REFERENCES part(sku),units INTEGER NOT NULL CHECK(units>=0));
INSERT INTO on_hand VALUES('SPOKE',100),('RIM',10),('BOLT',20);
CREATE VIEW shortage AS
SELECT r.sku,MAX(0,r.required-COALESCE(h.units,0)) AS missing
FROM requirement r LEFT JOIN on_hand h USING(sku);
INSERT INTO checks VALUES((SELECT missing FROM shortage WHERE sku='SPOKE')=40);
INSERT INTO checks VALUES((SELECT missing FROM shortage WHERE sku='RIM')=0);
INSERT INTO checks VALUES((SELECT missing FROM shortage WHERE sku='HUB')=7);
INSERT INTO checks VALUES((SELECT missing FROM shortage WHERE sku='BOLT')=6);
SELECT * FROM shortage ORDER BY sku;
COMMIT;
