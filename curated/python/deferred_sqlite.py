"""Python 3.11+ / SQLite: deferred constraints at transaction boundaries.

Run: python deferred_sqlite.py. In-memory database, adjacent repository fixture.
Nested RELEASE differs from a transaction-opening SAVEPOINT's RELEASE. A failed
commit is not a rollback. Each test verifies transaction and row state explicitly.
"""
from pathlib import Path
import sqlite3

SCHEMA = Path(__file__).resolve().parents[1] / "sql/sqlite/deferred_foreign_keys.sql"


def reject(db, sql, code):
    try:
        db.execute(sql)
    except sqlite3.IntegrityError as error:
        assert error.sqlite_errorname == code, (error.sqlite_errorname, sql)
    else:
        raise AssertionError("expected constraint rejection: " + sql)


def parcels(db):
    return db.execute("SELECT id,owner_id,units FROM parcels ORDER BY id").fetchall()


def main():
    with sqlite3.connect(":memory:", isolation_level=None) as db:
        db.executescript(SCHEMA.read_text(encoding="utf-8"))
        assert db.execute("PRAGMA foreign_keys").fetchone() == (1,)
        # Autocommit: a deferred FK is still checked at this statement's end.
        reject(db, "INSERT INTO parcels VALUES(10,2,1)", "SQLITE_CONSTRAINT_FOREIGNKEY")
        assert not db.in_transaction and parcels(db) == []
        db.execute("BEGIN")
        db.execute("INSERT INTO parcels VALUES(10,2,1)")
        assert parcels(db) == [(10, 2, 1)]
        assert db.execute("PRAGMA foreign_key_check").fetchall() == [("parcels", 10, "owners", 0)]
        reject(db, "COMMIT", "SQLITE_CONSTRAINT_FOREIGNKEY")
        assert db.in_transaction and parcels(db) == [(10, 2, 1)]
        # Repair within the still-open transaction, then commit successfully.
        db.execute("INSERT INTO owners VALUES(2,'repaired')")
        db.execute("COMMIT")
        baseline = [(10, 2, 1)]
        assert not db.in_transaction and parcels(db) == baseline

        db.execute("BEGIN")
        db.execute("SAVEPOINT inner_scope")
        db.execute("INSERT INTO parcels VALUES(20,3,2)")
        db.execute("RELEASE inner_scope")  # legal even with the deferred violation
        assert db.in_transaction and parcels(db) == baseline + [(20, 3, 2)]
        reject(db, "COMMIT", "SQLITE_CONSTRAINT_FOREIGNKEY")
        assert db.in_transaction and parcels(db) == baseline + [(20, 3, 2)]
        db.execute("ROLLBACK")
        assert not db.in_transaction and parcels(db) == baseline

        # An outer SAVEPOINT opened in autocommit behaves like a transaction.
        db.execute("SAVEPOINT outer_scope")
        db.execute("SAVEPOINT inner_scope")
        db.execute("INSERT INTO parcels VALUES(30,4,3)")
        reject(db, "RELEASE outer_scope", "SQLITE_CONSTRAINT_FOREIGNKEY")
        assert db.in_transaction and parcels(db) == baseline + [(30, 4, 3)]
        db.execute("ROLLBACK TO inner_scope")  # failed RELEASE left nested savepoints usable
        assert parcels(db) == baseline
        db.execute("RELEASE inner_scope")
        db.execute("RELEASE outer_scope")
        assert not db.in_transaction and parcels(db) == baseline

        # A CHECK remains immediate even though a different constraint is deferred.
        db.execute("BEGIN")
        reject(db, "INSERT INTO parcels VALUES(40,1,0)", "SQLITE_CONSTRAINT_CHECK")
        reject(db, "INSERT INTO parcels VALUES(40,1,10)", "SQLITE_CONSTRAINT_CHECK")
        reject(db, "UPDATE parcels SET units=0 WHERE id=10", "SQLITE_CONSTRAINT_CHECK")
        assert db.in_transaction and parcels(db) == baseline
        db.execute("INSERT INTO parcels VALUES(40,1,9)")
        db.execute("COMMIT")
        assert parcels(db) == baseline + [(40, 1, 9)]
        assert db.execute("PRAGMA foreign_key_check").fetchall() == []
        assert db.execute("PRAGMA integrity_check").fetchone() == ("ok",)
    print(f"SQLite {sqlite3.sqlite_version}: deferred commit failures, repairs, nested/outer release, rollback and immediate checks passed")


if __name__ == "__main__":
    main()
