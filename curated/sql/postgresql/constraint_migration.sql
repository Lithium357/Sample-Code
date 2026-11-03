-- DIALECT: PostgreSQL 16+, SQL + PL/pgSQL; not SQLite/T-SQL.
-- RUNTIME: local PostgreSQL instance and psql, using an owned scratch database.
-- Intended command: psql -X -v ON_ERROR_STOP=1 -d scratch -f constraint_migration.sql
-- All objects are TEMP; the outer transaction is rolled back. No credentials.
-- Semantics: https://www.postgresql.org/docs/16/plpgsql-control-structures.html#PLPGSQL-ERROR-TRAPPING
BEGIN;
CREATE TEMP TABLE fixture_product(sku text PRIMARY KEY);
CREATE TEMP TABLE fixture_order(
    id integer PRIMARY KEY,
    sku text NOT NULL REFERENCES fixture_product(sku),
    quantity integer NOT NULL CHECK(quantity BETWEEN 1 AND 10)
);
INSERT INTO fixture_product VALUES('PEN'),('INK');
INSERT INTO fixture_order VALUES(1,'PEN',2);
DO $test$
BEGIN
    BEGIN
        INSERT INTO fixture_order VALUES(2,'PEN',0);
        RAISE EXCEPTION 'accepted invalid quantity';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    BEGIN
        INSERT INTO fixture_order VALUES(1,'INK',3);
        RAISE EXCEPTION 'accepted duplicate key';
    EXCEPTION WHEN unique_violation THEN NULL;
    END;
    BEGIN
        INSERT INTO fixture_order VALUES(2,'MISSING',1);
        RAISE EXCEPTION 'accepted missing product';
    EXCEPTION WHEN foreign_key_violation THEN NULL;
    END;
    IF (SELECT count(*) FROM fixture_order) <> 1 OR
       (SELECT quantity FROM fixture_order WHERE id=1) <> 2 THEN
        RAISE EXCEPTION 'rejected writes changed state';
    END IF;
    -- LEFT JOIN must preserve the product with no orders, including its NULL id.
    IF (SELECT count(*) FROM fixture_product p LEFT JOIN fixture_order o USING(sku) WHERE o.id IS NULL) <> 1 THEN
        RAISE EXCEPTION 'left join lost unmatched product';
    END IF;
END $test$;
SAVEPOINT temporary_change;
UPDATE fixture_order SET quantity=8 WHERE id=1;
ROLLBACK TO SAVEPOINT temporary_change;
ALTER TABLE fixture_order ADD COLUMN note text NOT NULL DEFAULT '';
PREPARE set_note(integer,text) AS UPDATE fixture_order SET note=$2 WHERE id=$1;
EXECUTE set_note(1, '''); DROP TABLE fixture_order; --');
DEALLOCATE set_note;
DO $test$
BEGIN
    IF (SELECT quantity FROM fixture_order WHERE id=1) <> 2 THEN
        RAISE EXCEPTION 'savepoint did not restore quantity';
    END IF;
    IF (SELECT note FROM fixture_order WHERE id=1) <> '''); DROP TABLE fixture_order; --' THEN
        RAISE EXCEPTION 'prepared literal changed';
    END IF;
END $test$;
ROLLBACK;
SELECT 'PostgreSQL: subtransaction errors, joins, savepoints and migration passed' AS result;
