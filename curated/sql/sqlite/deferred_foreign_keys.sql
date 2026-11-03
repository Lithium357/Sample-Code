-- SQLite 3.6.19+ foreign-key syntax; run via ../../python/deferred_sqlite.py.
-- The driver requires Python 3.11+ for exact extended constraint error codes.
-- Explicit transactions and driver-side assertions are part of this example.
-- Reference semantics, not copied fixtures:
-- https://www.sqlite.org/foreignkeys.html#fk_deferred
PRAGMA foreign_keys=ON;
CREATE TABLE owners(id INTEGER PRIMARY KEY, label TEXT NOT NULL UNIQUE);
CREATE TABLE parcels(
    id INTEGER PRIMARY KEY,
    owner_id INTEGER NOT NULL REFERENCES owners(id) DEFERRABLE INITIALLY DEFERRED,
    units INTEGER NOT NULL CHECK(units BETWEEN 1 AND 9)
);
INSERT INTO owners VALUES(1,'initial');
