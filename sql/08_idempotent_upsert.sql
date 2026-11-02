-- Idempotent upsert.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE reading (
    sensor_id INTEGER NOT NULL,
    observed_at INTEGER NOT NULL,
    version INTEGER NOT NULL CHECK (version >= 1),
    milliunits INTEGER NOT NULL,
    PRIMARY KEY(sensor_id, observed_at)
);
INSERT INTO reading VALUES (1, 1000, 1, 22000), (2, 1000, 1, 18000);
-- Newer versions replace values. Equal or older retransmissions do nothing.
INSERT INTO reading(sensor_id, observed_at, version, milliunits)
VALUES (1, 1000, 2, 22500), (1, 1100, 1, 23000)
ON CONFLICT(sensor_id, observed_at) DO UPDATE SET
    version = excluded.version,
    milliunits = excluded.milliunits
WHERE excluded.version > reading.version;
INSERT INTO reading VALUES (1, 1000, 1, 99999)
ON CONFLICT(sensor_id, observed_at) DO UPDATE SET
    version = excluded.version, milliunits = excluded.milliunits
WHERE excluded.version > reading.version;
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM reading) = 3);
INSERT INTO checks VALUES ((SELECT version FROM reading WHERE sensor_id = 1 AND observed_at = 1000) = 2);
INSERT INTO checks VALUES ((SELECT milliunits FROM reading WHERE sensor_id = 1 AND observed_at = 1000) = 22500);
SELECT sensor_id, COUNT(*) AS samples, AVG(milliunits) / 1000.0 AS mean_units
FROM reading GROUP BY sensor_id ORDER BY sensor_id;
-- Version checks belong in the write statement to avoid a read/write race.
COMMIT;
