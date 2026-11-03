-- Nonoverlapping bookings.
-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.
-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"
-- Every checks insertion must evaluate to integer 1.
-- Rejection/state tests: python tools/research_validate.py --suite repairs
-- SQLite SQL alone cannot catch RAISE(ABORT); tools/sql_contracts.py attempts
-- overlapping inserts/updates, checks exact errors and verifies unchanged state.
-- Stored room/minute values must be INTEGER after SQLite affinity conversion.
-- Numeric text may convert to INTEGER; nonnumeric TEXT/fractional REAL may not.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));
CREATE TABLE booking (
    id INTEGER PRIMARY KEY,
    room_id INTEGER NOT NULL,
    start_minute INTEGER NOT NULL,
    end_minute INTEGER NOT NULL,
    CONSTRAINT booking_integer_values CHECK(
        typeof(room_id) = 'integer' AND typeof(start_minute) = 'integer'
        AND typeof(end_minute) = 'integer'
    ),
    CHECK(start_minute >= 0 AND end_minute > start_minute)
);
CREATE INDEX booking_room_start ON booking(room_id, start_minute);
CREATE TRIGGER prevent_overlap_insert BEFORE INSERT ON booking
WHEN EXISTS (
    SELECT 1 FROM booking AS b WHERE b.room_id = NEW.room_id
    AND NEW.start_minute < b.end_minute AND b.start_minute < NEW.end_minute
)
BEGIN SELECT RAISE(ABORT, 'room already booked'); END;
CREATE TRIGGER prevent_overlap_update BEFORE UPDATE ON booking
WHEN EXISTS (
    SELECT 1 FROM booking AS b WHERE b.room_id = NEW.room_id AND b.id <> OLD.id
    AND NEW.start_minute < b.end_minute AND b.start_minute < NEW.end_minute
)
BEGIN SELECT RAISE(ABORT, 'room already booked'); END;
INSERT INTO booking VALUES (1, 10, 540, 600), (2, 10, 600, 660), (3, 20, 540, 660);
-- Touching boundaries are valid because intervals are half-open.
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM booking WHERE room_id = 10) = 2);
INSERT INTO checks VALUES (NOT EXISTS (
    SELECT 1 FROM booking AS a JOIN booking AS b ON a.room_id = b.room_id AND a.id < b.id
    WHERE a.start_minute < b.end_minute AND b.start_minute < a.end_minute
));
CREATE VIEW booking_totals AS
SELECT room_id, SUM(end_minute - start_minute) AS booked_minutes
FROM booking GROUP BY room_id;
SELECT room_id, booked_minutes FROM booking_totals ORDER BY room_id;
COMMIT;
