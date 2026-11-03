-- PostgreSQL 16+, SQL/PLpgSQL; psql -X -v ON_ERROR_STOP=1 -f window_events.sql
-- Local scratch database; TEMP objects and final rollback. No external service.
-- Contract: event_id breaks timestamp ties; NULL amounts contribute zero.
-- Window frames are ROWS, not the default peer-inclusive RANGE frame.
BEGIN;
CREATE TEMP TABLE event_accounts(id integer PRIMARY KEY);
CREATE TEMP TABLE account_events(
    event_id integer PRIMARY KEY,
    account_id integer NOT NULL REFERENCES event_accounts,
    tick integer NOT NULL,
    amount integer,
    label text NOT NULL CHECK(length(label)>0)
);
INSERT INTO event_accounts VALUES (1),(2),(3);
-- Intentionally arrive out of event order and contain tied timestamps.
INSERT INTO account_events VALUES
    (30,1,20,-3,'spend'), (20,1,10,5,'deposit'),
    (10,1,10,2,'opening'), (40,1,30,NULL,'annotation'),
    (50,2,5,-8,'overdraft');
CREATE TEMP VIEW ordered_events AS
SELECT event_id, account_id,
       sum(coalesce(amount,0)) OVER (
         PARTITION BY account_id ORDER BY tick,event_id
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS balance,
       lag(event_id) OVER (PARTITION BY account_id ORDER BY tick,event_id) AS previous
FROM account_events;
DO $checks$
DECLARE balances bigint[]; predecessors integer[]; touched integer;
BEGIN
    SELECT array_agg(balance ORDER BY event_id), array_agg(previous ORDER BY event_id)
      INTO balances,predecessors FROM ordered_events WHERE account_id=1;
    IF balances IS DISTINCT FROM ARRAY[2,7,4,4]::bigint[] THEN
        RAISE EXCEPTION 'running balance mismatch: %', balances;
    END IF;
    IF predecessors IS DISTINCT FROM ARRAY[NULL,10,20,30]::integer[] THEN
        RAISE EXCEPTION 'tie order mismatch';
    END IF;
    IF (SELECT balance FROM ordered_events WHERE event_id=50) <> -8 THEN
        RAISE EXCEPTION 'partition leakage';
    END IF;
    -- Exact retry is ignored; RETURNING cannot be faked by SELECT row count.
    WITH inserted AS (
      INSERT INTO account_events VALUES(20,1,10,5,'deposit')
      ON CONFLICT(event_id) DO NOTHING RETURNING event_id
    ) SELECT count(*) INTO touched FROM inserted;
    IF touched<>0 THEN RAISE EXCEPTION 'retry created an event'; END IF;
    BEGIN
        UPDATE account_events SET account_id=999 WHERE event_id=10;
        RAISE EXCEPTION 'accepted dangling reference';
    EXCEPTION WHEN foreign_key_violation THEN NULL;
    END;
    BEGIN
        UPDATE account_events SET label='' WHERE event_id=10;
        RAISE EXCEPTION 'accepted empty label';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    IF (SELECT row(account_id,label) FROM account_events WHERE event_id=10)
       IS DISTINCT FROM row(1,'opening'::text) THEN
        RAISE EXCEPTION 'rejected update changed state';
    END IF;
    IF (SELECT count(*) FROM account_events)<>5 THEN RAISE EXCEPTION 'row count changed'; END IF;
END $checks$;
-- LEFT JOIN LATERAL preserves accounts with no events. An inner join loses id=3.
CREATE TEMP VIEW latest_per_account AS
SELECT a.id, e.event_id
FROM event_accounts a LEFT JOIN LATERAL (
  SELECT event_id FROM account_events e WHERE e.account_id=a.id
  ORDER BY tick DESC,event_id DESC LIMIT 1
) e ON true;
DO $checks$
BEGIN
    IF (SELECT array_agg(event_id ORDER BY id) FROM latest_per_account)
       IS DISTINCT FROM ARRAY[40,50,NULL]::integer[] THEN
        RAISE EXCEPTION 'latest/empty account mismatch';
    END IF;
    DELETE FROM account_events;
    IF EXISTS(SELECT 1 FROM ordered_events) THEN RAISE EXCEPTION 'nonempty empty-input window'; END IF;
    IF (SELECT count(*) FROM latest_per_account WHERE event_id IS NULL)<>3 THEN
        RAISE EXCEPTION 'empty accounts were lost';
    END IF;
END $checks$;
ROLLBACK;
SELECT 'PostgreSQL windows: ties, frames, partitions, retries, failed updates and empty lateral joins passed';
