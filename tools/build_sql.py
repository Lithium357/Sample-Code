"""Standalone SQLite relational examples with executable result checks."""
from build_corpus import ROOT, tokens
import hashlib
import json
import sqlite3

EXAMPLES = {}

EXAMPLES['inventory_ledger'] = '''
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
'''

EXAMPLES['organization_tree'] = '''
CREATE TABLE employee (
    id INTEGER PRIMARY KEY,
    manager_id INTEGER REFERENCES employee(id),
    name TEXT NOT NULL,
    CHECK (manager_id IS NULL OR manager_id <> id)
);
INSERT INTO employee VALUES
    (1, NULL, 'Ari'), (2, 1, 'Blair'), (3, 1, 'Casey'),
    (4, 2, 'Drew'), (5, 4, 'Eden'), (6, 3, 'Fin');
-- A delimiter-bounded visited path prevents revisiting any ancestor.
CREATE VIEW organization AS
WITH RECURSIVE tree(id, manager_id, name, depth, visited, display_path) AS (
    SELECT id, manager_id, name, 0, '/' || id || '/', name
    FROM employee WHERE manager_id IS NULL
    UNION ALL
    SELECT e.id, e.manager_id, e.name, t.depth + 1,
           t.visited || e.id || '/', t.display_path || ' > ' || e.name
    FROM employee AS e JOIN tree AS t ON e.manager_id = t.id
    WHERE INSTR(t.visited, '/' || e.id || '/') = 0 AND t.depth < 100
)
SELECT * FROM tree;
SELECT name, depth, display_path FROM organization ORDER BY display_path;
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM organization) = 6);
INSERT INTO checks VALUES ((SELECT depth FROM organization WHERE id = 5) = 3);
INSERT INTO checks VALUES ((SELECT display_path FROM organization WHERE id = 6) = 'Ari > Casey > Fin');
CREATE INDEX employee_manager ON employee(manager_id);
-- Find employees unreachable from a root: useful when auditing bad imports.
SELECT e.* FROM employee AS e
WHERE NOT EXISTS (SELECT 1 FROM organization AS o WHERE o.id = e.id);
'''

EXAMPLES['calendar_gap_fill'] = '''
CREATE TABLE daily_sale (
    day TEXT PRIMARY KEY CHECK (day = DATE(day)),
    cents INTEGER NOT NULL CHECK (cents >= 0)
);
INSERT INTO daily_sale VALUES ('2026-01-01', 100), ('2026-01-03', 300), ('2026-01-05', 500);
-- Generate an inclusive date spine; limit both the range and recursion.
CREATE VIEW calendar_report AS
WITH RECURSIVE calendar(day, ordinal) AS (
    SELECT DATE('2026-01-01'), 1
    UNION ALL
    SELECT DATE(day, '+1 day'), ordinal + 1 FROM calendar
    WHERE day < DATE('2026-01-07') AND ordinal < 366
), filled AS (
    SELECT c.day, COALESCE(s.cents, 0) AS cents
    FROM calendar AS c LEFT JOIN daily_sale AS s USING (day)
)
SELECT day, cents,
       SUM(cents) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_cents,
       ROUND(AVG(cents) OVER (ORDER BY day ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS trailing_three_day_mean
FROM filled;
SELECT * FROM calendar_report ORDER BY day;
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM calendar_report) = 7);
INSERT INTO checks VALUES ((SELECT cents FROM calendar_report WHERE day = '2026-01-02') = 0);
INSERT INTO checks VALUES ((SELECT running_cents FROM calendar_report WHERE day = '2026-01-07') = 900);
INSERT INTO checks VALUES ((SELECT trailing_three_day_mean FROM calendar_report WHERE day = '2026-01-03') = 133.33);
-- ROWS is appropriate after the spine gives every day exactly one row.
'''

EXAMPLES['event_sessions'] = '''
CREATE TABLE event (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    occurred_at INTEGER NOT NULL CHECK (occurred_at >= 0)
);
INSERT INTO event VALUES
    (1, 10, 0), (2, 10, 600), (3, 10, 2500), (4, 10, 2600),
    (5, 20, 100), (6, 20, 1900), (7, 20, 3701);
-- Times are integer seconds. A gap strictly greater than 1800 starts a session.
CREATE VIEW session_event AS
WITH lagged AS (
    SELECT *, LAG(occurred_at) OVER (PARTITION BY user_id ORDER BY occurred_at, id) AS previous_at
    FROM event
), marked AS (
    SELECT *, CASE WHEN previous_at IS NULL OR occurred_at - previous_at > 1800
                   THEN 1 ELSE 0 END AS starts_session
    FROM lagged
)
SELECT *, SUM(starts_session) OVER (
    PARTITION BY user_id ORDER BY occurred_at, id
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS session_number FROM marked;
SELECT user_id, session_number, MIN(occurred_at) AS started_at,
       MAX(occurred_at) AS ended_at, COUNT(*) AS event_count
FROM session_event GROUP BY user_id, session_number ORDER BY user_id, session_number;
INSERT INTO checks VALUES ((SELECT MAX(session_number) FROM session_event WHERE user_id = 10) = 2);
INSERT INTO checks VALUES ((SELECT session_number FROM session_event WHERE id = 6) = 1);
INSERT INTO checks VALUES ((SELECT session_number FROM session_event WHERE id = 7) = 2);
CREATE INDEX event_user_time ON event(user_id, occurred_at, id);
'''

EXAMPLES['running_balances'] = '''
CREATE TABLE entry (
    id INTEGER PRIMARY KEY,
    account_id INTEGER NOT NULL,
    day TEXT NOT NULL,
    delta_cents INTEGER NOT NULL
);
INSERT INTO entry VALUES
    (1, 1, '2026-01-01', 10000), (2, 1, '2026-01-01', -1200),
    (3, 1, '2026-01-03', -500), (4, 2, '2026-01-02', 3000);
-- The id breaks timestamp ties, making running totals deterministic.
CREATE VIEW running_balance AS
SELECT *, SUM(delta_cents) OVER (
    PARTITION BY account_id ORDER BY day, id
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS balance_cents FROM entry;
SELECT account_id, id, day, delta_cents, balance_cents
FROM running_balance ORDER BY account_id, day, id;
INSERT INTO checks VALUES ((SELECT balance_cents FROM running_balance WHERE id = 2) = 8800);
INSERT INTO checks VALUES ((SELECT balance_cents FROM running_balance WHERE id = 3) = 8300);
INSERT INTO checks VALUES ((SELECT balance_cents FROM running_balance WHERE id = 4) = 3000);
-- End-of-day snapshots keep only the last posting per account and date.
WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY account_id, day ORDER BY id DESC) AS position
    FROM running_balance
)
SELECT account_id, day, balance_cents FROM ranked WHERE position = 1
ORDER BY account_id, day;
CREATE INDEX entry_account_order ON entry(account_id, day, id);
'''

EXAMPLES['cohort_retention'] = '''
CREATE TABLE signup (user_id INTEGER PRIMARY KEY, cohort_month TEXT NOT NULL);
CREATE TABLE activity (user_id INTEGER REFERENCES signup(user_id), month TEXT NOT NULL,
                       PRIMARY KEY (user_id, month));
INSERT INTO signup VALUES (1, '2026-01-01'), (2, '2026-01-01'), (3, '2026-02-01');
INSERT INTO activity VALUES
    (1, '2026-01-01'), (1, '2026-02-01'), (1, '2026-03-01'),
    (2, '2026-01-01'), (3, '2026-02-01');
CREATE VIEW retention AS
WITH sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size FROM signup GROUP BY cohort_month
), observed AS (
    SELECT s.cohort_month,
           (CAST(STRFTIME('%Y', a.month) AS INTEGER) - CAST(STRFTIME('%Y', s.cohort_month) AS INTEGER)) * 12
           + CAST(STRFTIME('%m', a.month) AS INTEGER) - CAST(STRFTIME('%m', s.cohort_month) AS INTEGER) AS age_months,
           COUNT(DISTINCT a.user_id) AS active_users
    FROM signup AS s JOIN activity AS a USING (user_id)
    WHERE a.month >= s.cohort_month GROUP BY s.cohort_month, age_months
)
SELECT o.*, z.cohort_size, 1.0 * active_users / cohort_size AS retained_fraction
FROM observed AS o JOIN sizes AS z USING (cohort_month);
SELECT * FROM retention ORDER BY cohort_month, age_months;
INSERT INTO checks VALUES ((SELECT retained_fraction FROM retention WHERE cohort_month = '2026-01-01' AND age_months = 0) = 1.0);
INSERT INTO checks VALUES ((SELECT retained_fraction FROM retention WHERE cohort_month = '2026-01-01' AND age_months = 1) = 0.5);
-- Missing age cells are absent; a complete dashboard would join an age spine.
'''

EXAMPLES['deduplicate_import'] = '''
CREATE TABLE incoming (
    source_id INTEGER PRIMARY KEY,
    email TEXT NOT NULL,
    updated_at INTEGER NOT NULL,
    display_name TEXT NOT NULL
);
INSERT INTO incoming VALUES
    (1, ' Ari@example.test ', 100, 'Old Ari'),
    (2, 'ari@example.test', 200, 'Ari'),
    (3, 'BLAIR@example.test', 200, 'Blair'),
    (4, 'ari@example.test', 200, 'Ari Latest');
CREATE TABLE contact (
    email TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    source_id INTEGER NOT NULL UNIQUE
);
-- Normalize the natural key, then resolve equal timestamps by source id.
WITH ranked AS (
    SELECT LOWER(TRIM(email)) AS normalized_email, display_name, source_id,
           ROW_NUMBER() OVER (
               PARTITION BY LOWER(TRIM(email)) ORDER BY updated_at DESC, source_id DESC
           ) AS position FROM incoming
)
INSERT INTO contact(email, display_name, source_id)
SELECT normalized_email, display_name, source_id FROM ranked WHERE position = 1;
SELECT * FROM contact ORDER BY email;
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM contact) = 2);
INSERT INTO checks VALUES ((SELECT source_id FROM contact WHERE email = 'ari@example.test') = 4);
-- Report discarded rows separately so the import remains explainable.
SELECT i.source_id, i.email FROM incoming AS i
WHERE NOT EXISTS (SELECT 1 FROM contact AS c WHERE c.source_id = i.source_id)
ORDER BY i.source_id;
'''

EXAMPLES['idempotent_upsert'] = '''
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
'''

EXAMPLES['graph_reachability'] = '''
CREATE TABLE edge (
    source INTEGER NOT NULL,
    target INTEGER NOT NULL,
    PRIMARY KEY(source, target), CHECK(source <> target)
);
INSERT INTO edge VALUES (1, 2), (2, 3), (3, 1), (2, 4), (4, 5), (8, 9);
CREATE VIEW reachable AS
WITH RECURSIVE walk(node) AS (
    VALUES(1)
    UNION
    SELECT e.target FROM edge AS e JOIN walk AS w ON e.source = w.node
)
SELECT node FROM walk;
-- UNION deduplicates visited nodes and makes this cyclic traversal terminate.
SELECT node FROM reachable ORDER BY node;
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM reachable) = 5);
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM reachable WHERE node = 8) = 0);
-- Enumerate simple paths separately; include a visited set and depth cap.
WITH RECURSIVE paths(node, route, depth) AS (
    VALUES(1, '/1/', 0)
    UNION ALL
    SELECT e.target, p.route || e.target || '/', p.depth + 1
    FROM paths AS p JOIN edge AS e ON p.node = e.source
    WHERE INSTR(p.route, '/' || e.target || '/') = 0 AND p.depth < 10
)
SELECT node, route, depth FROM paths ORDER BY depth, route;
CREATE INDEX edge_reverse ON edge(target, source);
'''

EXAMPLES['ranking_with_ties'] = '''
CREATE TABLE score (
    contestant TEXT PRIMARY KEY,
    division TEXT NOT NULL,
    points INTEGER NOT NULL CHECK(points >= 0)
);
INSERT INTO score VALUES
    ('Ari', 'red', 100), ('Blair', 'red', 90), ('Casey', 'red', 90), ('Drew', 'red', 80),
    ('Eden', 'blue', 80), ('Fin', 'blue', 80), ('Gale', 'blue', 70);
CREATE VIEW standings AS
SELECT *,
    RANK() OVER (PARTITION BY division ORDER BY points DESC) AS competition_rank,
    DENSE_RANK() OVER (PARTITION BY division ORDER BY points DESC) AS dense_rank,
    ROW_NUMBER() OVER (PARTITION BY division ORDER BY points DESC, contestant) AS deterministic_row
FROM score;
-- RANK preserves competition gaps; DENSE_RANK counts distinct score levels.
SELECT * FROM standings ORDER BY division, deterministic_row;
SELECT division, contestant, points FROM standings
WHERE dense_rank <= 2 ORDER BY division, points DESC, contestant;
INSERT INTO checks VALUES ((SELECT competition_rank FROM standings WHERE contestant = 'Drew') = 4);
INSERT INTO checks VALUES ((SELECT dense_rank FROM standings WHERE contestant = 'Drew') = 3);
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM standings WHERE division = 'red' AND dense_rank <= 2) = 3);
INSERT INTO checks VALUES ((SELECT deterministic_row FROM standings WHERE contestant = 'Fin') = 2);
-- Do not add contestant to the ranking ORDER BY: that would break score ties.
'''

EXAMPLES['consecutive_day_islands'] = '''
CREATE TABLE attendance (
    user_id INTEGER NOT NULL,
    day TEXT NOT NULL,
    PRIMARY KEY(user_id, day)
);
INSERT INTO attendance VALUES
    (1, '2026-01-01'), (1, '2026-01-02'), (1, '2026-01-03'),
    (1, '2026-01-05'), (1, '2026-01-06'), (2, '2026-01-02');
CREATE VIEW streaks AS
WITH numbered AS (
    SELECT user_id, day,
        CAST(JULIANDAY(day) AS INTEGER)
        - ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY day) AS island
    FROM attendance
)
SELECT user_id, MIN(day) AS first_day, MAX(day) AS last_day, COUNT(*) AS days
FROM numbered GROUP BY user_id, island;
SELECT * FROM streaks ORDER BY user_id, first_day;
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM streaks WHERE user_id = 1) = 2);
INSERT INTO checks VALUES ((SELECT MAX(days) FROM streaks WHERE user_id = 1) = 3);
-- A second window selects the longest streak, with earliest date as tie-break.
WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY days DESC, first_day) AS position
    FROM streaks
)
SELECT user_id, first_day, last_day, days FROM ranked WHERE position = 1 ORDER BY user_id;
-- The primary key prevents duplicates from distorting the row-number trick.
'''

EXAMPLES['effective_dated_prices'] = '''
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
SELECT a.product_id, a.valid_from, b.valid_from FROM price AS a JOIN price AS b
ON a.product_id = b.product_id AND a.valid_from < b.valid_from
AND (a.valid_to IS NULL OR b.valid_from < a.valid_to);
'''

EXAMPLES['audit_triggers'] = '''
CREATE TABLE task (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('queued', 'active', 'done'))
);
CREATE TABLE status_history (
    sequence INTEGER PRIMARY KEY,
    task_id INTEGER NOT NULL REFERENCES task(id),
    old_status TEXT NOT NULL,
    new_status TEXT NOT NULL
);
CREATE TRIGGER record_status_change AFTER UPDATE OF status ON task
WHEN OLD.status <> NEW.status
BEGIN
    INSERT INTO status_history(task_id, old_status, new_status)
    VALUES(NEW.id, OLD.status, NEW.status);
END;
CREATE TRIGGER prevent_reopening BEFORE UPDATE OF status ON task
WHEN OLD.status = 'done' AND NEW.status <> 'done'
BEGIN
    SELECT RAISE(ABORT, 'completed tasks cannot be reopened');
END;
INSERT INTO task VALUES (1, 'Import catalog', 'queued');
UPDATE task SET status = 'active' WHERE id = 1;
UPDATE task SET title = 'Import verified catalog' WHERE id = 1;
UPDATE task SET status = 'active' WHERE id = 1;
UPDATE task SET status = 'done' WHERE id = 1;
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM status_history) = 2);
INSERT INTO checks VALUES ((SELECT new_status FROM status_history ORDER BY sequence DESC LIMIT 1) = 'done');
SELECT t.title, h.old_status, h.new_status FROM status_history AS h
JOIN task AS t ON t.id = h.task_id ORDER BY h.sequence;
-- No-op updates and unrelated columns do not create history noise.
'''

EXAMPLES['nonoverlapping_bookings'] = '''
CREATE TABLE booking (
    id INTEGER PRIMARY KEY,
    room_id INTEGER NOT NULL,
    start_minute INTEGER NOT NULL,
    end_minute INTEGER NOT NULL,
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
SELECT room_id, SUM(end_minute - start_minute) AS booked_minutes
FROM booking GROUP BY room_id ORDER BY room_id;
'''

EXAMPLES['relational_division'] = '''
CREATE TABLE document (id INTEGER PRIMARY KEY, title TEXT NOT NULL);
CREATE TABLE tag (id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE);
CREATE TABLE document_tag (
    document_id INTEGER NOT NULL REFERENCES document(id),
    tag_id INTEGER NOT NULL REFERENCES tag(id),
    PRIMARY KEY(document_id, tag_id)
);
CREATE TABLE required_tag (tag_id INTEGER PRIMARY KEY REFERENCES tag(id));
INSERT INTO document VALUES (1, 'SQL guide'), (2, 'SQLite windows'), (3, 'Shell guide');
INSERT INTO tag VALUES (1, 'database'), (2, 'tutorial'), (3, 'shell');
INSERT INTO document_tag VALUES (1, 1), (1, 2), (2, 1), (3, 2), (3, 3);
INSERT INTO required_tag VALUES (1), (2);
-- Select documents for which no required tag is missing.
CREATE VIEW matching_document AS
SELECT d.* FROM document AS d
WHERE NOT EXISTS (
    SELECT 1 FROM required_tag AS r
    WHERE NOT EXISTS (
        SELECT 1 FROM document_tag AS dt WHERE dt.document_id = d.id AND dt.tag_id = r.tag_id
    )
);
SELECT * FROM matching_document ORDER BY id;
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM matching_document) = 1);
INSERT INTO checks VALUES ((SELECT id FROM matching_document) = 1);
DELETE FROM required_tag;
-- Universal quantification over an empty requirement set matches everything.
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM matching_document) = 3);
CREATE INDEX document_tag_reverse ON document_tag(tag_id, document_id);
'''

EXAMPLES['keyset_pagination'] = '''
CREATE TABLE article (
    id INTEGER PRIMARY KEY,
    published_at INTEGER NOT NULL,
    title TEXT NOT NULL
);
INSERT INTO article VALUES
    (1, 100, 'Alpha'), (2, 100, 'Beta'), (3, 200, 'Gamma'),
    (4, 200, 'Delta'), (5, 300, 'Epsilon');
CREATE INDEX article_order ON article(published_at DESC, id DESC);
CREATE TEMP TABLE first_page AS
SELECT * FROM article ORDER BY published_at DESC, id DESC LIMIT 2;
-- The next cursor is the final (published_at,id) pair from the first page.
CREATE TEMP TABLE cursor AS
SELECT published_at, id FROM first_page ORDER BY published_at, id LIMIT 1;
CREATE TEMP TABLE second_page AS
SELECT a.* FROM article AS a CROSS JOIN cursor AS c
WHERE (a.published_at, a.id) < (c.published_at, c.id)
ORDER BY a.published_at DESC, a.id DESC LIMIT 2;
SELECT * FROM first_page ORDER BY published_at DESC, id DESC;
SELECT * FROM second_page ORDER BY published_at DESC, id DESC;
INSERT INTO checks VALUES ((SELECT GROUP_CONCAT(id, ',') FROM (SELECT id FROM first_page ORDER BY published_at DESC, id DESC)) = '5,4');
INSERT INTO checks VALUES ((SELECT GROUP_CONCAT(id, ',') FROM (SELECT id FROM second_page ORDER BY published_at DESC, id DESC)) = '3,2');
INSERT INTO checks VALUES (NOT EXISTS (SELECT id FROM first_page INTERSECT SELECT id FROM second_page));
-- A unique tie-breaker prevents duplicate timestamps from skipping rows.
-- Across separate requests, use a snapshot boundary if insert consistency matters.
'''

EXAMPLES['fifo_stock_allocation'] = '''
CREATE TABLE lot (
    id INTEGER PRIMARY KEY,
    arrived_at INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK(quantity > 0)
);
CREATE TABLE demand (requested INTEGER NOT NULL CHECK(requested >= 0));
INSERT INTO lot VALUES (1, 100, 5), (2, 200, 8), (3, 200, 4);
INSERT INTO demand VALUES (10);
-- Map each lot to an interval in cumulative inventory order.
CREATE VIEW allocation AS
WITH cumulative AS (
    SELECT *, SUM(quantity) OVER (
        ORDER BY arrived_at, id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS end_unit FROM lot
), intervals AS (
    SELECT *, end_unit - quantity AS start_unit FROM cumulative
)
SELECT i.id, i.quantity, i.start_unit, i.end_unit,
    MAX(0, MIN(i.end_unit, d.requested) - i.start_unit) AS allocated
FROM intervals AS i CROSS JOIN demand AS d;
SELECT * FROM allocation ORDER BY start_unit;
INSERT INTO checks VALUES ((SELECT allocated FROM allocation WHERE id = 1) = 5);
INSERT INTO checks VALUES ((SELECT allocated FROM allocation WHERE id = 2) = 5);
INSERT INTO checks VALUES ((SELECT allocated FROM allocation WHERE id = 3) = 0);
INSERT INTO checks VALUES ((SELECT SUM(allocated) FROM allocation) = 10);
UPDATE demand SET requested = 30;
INSERT INTO checks VALUES ((SELECT SUM(allocated) FROM allocation) = 17);
SELECT MAX(0, requested - (SELECT SUM(quantity) FROM lot)) AS unfilled FROM demand;
-- Real stock reservation also needs a transaction and write-side concurrency rules.
'''

EXAMPLES['largest_remainder_allocation'] = '''
CREATE TABLE weight (recipient TEXT PRIMARY KEY, units INTEGER NOT NULL CHECK(units > 0));
CREATE TABLE budget (cents INTEGER NOT NULL CHECK(cents >= 0));
INSERT INTO weight VALUES ('Ari', 1), ('Blair', 1), ('Casey', 1);
INSERT INTO budget VALUES (100);
-- Allocate integer cents proportionally, then give leftover cents to the
-- largest fractional remainders. Recipient name breaks exact ties.
CREATE VIEW payout AS
WITH totals AS (
    SELECT SUM(units) AS total_units FROM weight
), raw AS (
    SELECT recipient, b.cents * w.units / t.total_units AS floor_cents,
           b.cents * w.units % t.total_units AS remainder
    FROM weight AS w CROSS JOIN budget AS b CROSS JOIN totals AS t
), ranked AS (
    SELECT *, ROW_NUMBER() OVER (ORDER BY remainder DESC, recipient) AS position,
           SUM(floor_cents) OVER () AS allocated_floor FROM raw
)
SELECT recipient, floor_cents + CASE WHEN position <= b.cents - allocated_floor
    THEN 1 ELSE 0 END AS cents FROM ranked CROSS JOIN budget AS b;
SELECT * FROM payout ORDER BY recipient;
INSERT INTO checks VALUES ((SELECT SUM(cents) FROM payout) = 100);
INSERT INTO checks VALUES ((SELECT cents FROM payout WHERE recipient = 'Ari') = 34);
INSERT INTO checks VALUES ((SELECT cents FROM payout WHERE recipient = 'Blair') = 33);
UPDATE weight SET units = 2 WHERE recipient = 'Casey';
INSERT INTO checks VALUES ((SELECT cents FROM payout WHERE recipient = 'Casey') = 50);
INSERT INTO checks VALUES ((SELECT SUM(cents) FROM payout) = 100);
-- Keep cents*units below signed 64-bit overflow; no floating arithmetic is needed.
'''

EXAMPLES['cleaning_staged_records'] = '''
CREATE TABLE staging (id INTEGER PRIMARY KEY, email TEXT, age_text TEXT);
INSERT INTO staging VALUES
    (1, ' ARI@example.test ', '32'), (2, '', '22'), (3, NULL, '18'),
    (4, 'blair@example.test', 'twenty'), (5, 'casey@example.test', '0'),
    (6, 'drew@example.test', '12x');
CREATE VIEW classified AS
SELECT *, LOWER(TRIM(email)) AS normalized_email,
    CASE
        WHEN NULLIF(TRIM(email), '') IS NULL THEN 'missing email'
        WHEN age_text IS NULL OR age_text = '' THEN 'missing age'
        WHEN age_text GLOB '*[^0-9]*' THEN 'non-numeric age'
        WHEN CAST(age_text AS INTEGER) > 130 THEN 'age out of range'
        ELSE NULL
    END AS rejection FROM staging;
CREATE TABLE person (id INTEGER PRIMARY KEY, email TEXT NOT NULL, age INTEGER NOT NULL CHECK(age BETWEEN 0 AND 130));
INSERT INTO person SELECT id, normalized_email, CAST(age_text AS INTEGER)
FROM classified WHERE rejection IS NULL;
SELECT id, rejection FROM classified WHERE rejection IS NOT NULL ORDER BY id;
SELECT * FROM person ORDER BY id;
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM person) = 2);
INSERT INTO checks VALUES ((SELECT email FROM person WHERE id = 1) = 'ari@example.test');
INSERT INTO checks VALUES ((SELECT age FROM person WHERE id = 5) = 0);
INSERT INTO checks VALUES ((SELECT rejection FROM classified WHERE id = 6) = 'non-numeric age');
-- SQLite CAST('12x' AS INTEGER) gives 12, so validate syntax before casting.
-- Email normalization here is a data-cleaning example, not complete validation.
'''

EXAMPLES['conditional_pivot'] = '''
CREATE TABLE response (
    person_id INTEGER NOT NULL,
    question TEXT NOT NULL CHECK(question IN ('speed', 'quality', 'support')),
    rating INTEGER NOT NULL CHECK(rating BETWEEN 1 AND 5),
    PRIMARY KEY(person_id, question)
);
INSERT INTO response VALUES
    (1, 'speed', 4), (1, 'quality', 5), (1, 'support', 3),
    (2, 'speed', 2), (2, 'quality', 4), (3, 'support', 5);
CREATE VIEW wide_response AS
SELECT person_id,
    MAX(CASE WHEN question = 'speed' THEN rating END) AS speed,
    MAX(CASE WHEN question = 'quality' THEN rating END) AS quality,
    MAX(CASE WHEN question = 'support' THEN rating END) AS support,
    COUNT(*) AS answered_questions
FROM response GROUP BY person_id;
SELECT * FROM wide_response ORDER BY person_id;
INSERT INTO checks VALUES ((SELECT quality FROM wide_response WHERE person_id = 1) = 5);
INSERT INTO checks VALUES ((SELECT support FROM wide_response WHERE person_id = 2) IS NULL);
INSERT INTO checks VALUES ((SELECT answered_questions FROM wide_response WHERE person_id = 3) = 1);
-- Missing answers remain NULL instead of being turned into artificial zeros.
SELECT question, COUNT(*) AS responses, ROUND(AVG(rating), 2) AS mean_rating,
    SUM(CASE WHEN rating >= 4 THEN 1 ELSE 0 END) AS positive_responses
FROM response GROUP BY question ORDER BY question;
-- The unique person/question key makes MAX an unambiguous pivot operation.
'''

EXAMPLES['medians_and_quantiles'] = '''
CREATE TABLE observation (id INTEGER PRIMARY KEY, segment TEXT NOT NULL, value INTEGER NOT NULL);
INSERT INTO observation VALUES
    (1, 'odd', 1), (2, 'odd', 5), (3, 'odd', 9),
    (4, 'even', 2), (5, 'even', 4), (6, 'even', 8), (7, 'even', 10);
CREATE VIEW median_value AS
WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY segment ORDER BY value, id) AS position,
        COUNT(*) OVER (PARTITION BY segment) AS size FROM observation
)
SELECT segment, AVG(value * 1.0) AS median FROM ranked
WHERE position IN ((size + 1) / 2, (size + 2) / 2) GROUP BY segment;
SELECT * FROM median_value ORDER BY segment;
INSERT INTO checks VALUES ((SELECT median FROM median_value WHERE segment = 'odd') = 5.0);
INSERT INTO checks VALUES ((SELECT median FROM median_value WHERE segment = 'even') = 6.0);
-- Nearest-rank 75th percentile uses ceil(3*N/4), expressed in integers.
WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY segment ORDER BY value, id) AS position,
        COUNT(*) OVER (PARTITION BY segment) AS size FROM observation
)
SELECT segment, value AS percentile_75 FROM ranked WHERE position = (3 * size + 3) / 4
ORDER BY segment;
-- Different percentile definitions may interpolate; this one deliberately does not.
'''

EXAMPLES['ledger_reconciliation'] = '''
CREATE TABLE internal_posting (reference TEXT PRIMARY KEY, cents INTEGER NOT NULL);
CREATE TABLE bank_posting (reference TEXT PRIMARY KEY, cents INTEGER NOT NULL);
INSERT INTO internal_posting VALUES ('A', 100), ('B', 200), ('C', 300);
INSERT INTO bank_posting VALUES ('A', 100), ('B', 250), ('D', 400);
CREATE VIEW reconciliation AS
WITH all_references AS (
    SELECT reference FROM internal_posting UNION SELECT reference FROM bank_posting
)
SELECT r.reference, i.cents AS internal_cents, b.cents AS bank_cents,
    CASE WHEN i.reference IS NULL THEN 'bank only'
         WHEN b.reference IS NULL THEN 'internal only'
         WHEN i.cents <> b.cents THEN 'amount mismatch'
         ELSE 'matched' END AS status,
    COALESCE(b.cents, 0) - COALESCE(i.cents, 0) AS difference_cents
FROM all_references AS r
LEFT JOIN internal_posting AS i USING(reference)
LEFT JOIN bank_posting AS b USING(reference);
SELECT * FROM reconciliation ORDER BY reference;
INSERT INTO checks VALUES ((SELECT status FROM reconciliation WHERE reference = 'A') = 'matched');
INSERT INTO checks VALUES ((SELECT status FROM reconciliation WHERE reference = 'B') = 'amount mismatch');
INSERT INTO checks VALUES ((SELECT status FROM reconciliation WHERE reference = 'C') = 'internal only');
INSERT INTO checks VALUES ((SELECT status FROM reconciliation WHERE reference = 'D') = 'bank only');
INSERT INTO checks VALUES ((SELECT SUM(difference_cents) FROM reconciliation) = 150);
-- UNION of keys works as a portable full-join strategy and preserves missing sides.
'''

EXAMPLES['savepoints_and_rollback'] = '''
CREATE TABLE wallet (id INTEGER PRIMARY KEY, cents INTEGER NOT NULL CHECK(cents >= 0));
CREATE TABLE transfer (id INTEGER PRIMARY KEY, sender INTEGER REFERENCES wallet(id),
    recipient INTEGER REFERENCES wallet(id), cents INTEGER NOT NULL CHECK(cents > 0));
INSERT INTO wallet VALUES (1, 1000), (2, 200);
SAVEPOINT transfer_attempt;
UPDATE wallet SET cents = cents - 300 WHERE id = 1;
UPDATE wallet SET cents = cents + 300 WHERE id = 2;
INSERT INTO transfer VALUES (1, 1, 2, 300);
-- Simulate a failed business validation after the writes.
ROLLBACK TO transfer_attempt;
RELEASE transfer_attempt;
INSERT INTO checks VALUES ((SELECT cents FROM wallet WHERE id = 1) = 1000);
INSERT INTO checks VALUES ((SELECT COUNT(*) FROM transfer) = 0);
SAVEPOINT accepted_transfer;
UPDATE wallet SET cents = cents - 300 WHERE id = 1 AND cents >= 300;
-- The application must inspect changes() before proceeding with the credit.
INSERT INTO checks VALUES (changes() = 1);
UPDATE wallet SET cents = cents + 300 WHERE id = 2;
INSERT INTO transfer VALUES (1, 1, 2, 300);
RELEASE accepted_transfer;
INSERT INTO checks VALUES ((SELECT SUM(cents) FROM wallet) = 1200);
INSERT INTO checks VALUES ((SELECT cents FROM wallet WHERE id = 1) = 700);
INSERT INTO checks VALUES ((SELECT cents FROM wallet WHERE id = 2) = 500);
SELECT * FROM wallet ORDER BY id;
-- A savepoint can roll back a unit of work without aborting the outer transaction.
'''

def build():
    destination = ROOT / 'sql'
    destination.mkdir(exist_ok=True)
    manifest_path = ROOT / 'manifest.json'
    manifest = [entry for entry in json.loads(manifest_path.read_text()) if entry['language'] != 'sql']
    total = 0
    for i,(name,body) in enumerate(EXAMPLES.items(),1):
        source = (f'-- {name.replace("_", " ").capitalize()}.\n'
                  '-- Dialect: SQLite 3.25+; standalone, in-memory-friendly fixture.\n'
                  '-- Run: sqlite3 :memory: ".bail on" ".read FILE.sql"\n'
                  '-- Every checks insertion must evaluate to integer 1.\n'
                  'PRAGMA foreign_keys = ON;\nBEGIN;\n'
                  'CREATE TEMP TABLE checks (ok INTEGER NOT NULL CHECK(ok = 1));\n'
                  + body.strip() + '\nCOMMIT;\n')
        connection = sqlite3.connect(':memory:')
        try:
            connection.executescript(source)
            count = connection.execute('SELECT COUNT(*) FROM checks').fetchone()[0]
            assert count > 0
            assert connection.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
            assert not connection.execute('PRAGMA foreign_key_check').fetchall()
        finally:
            connection.close()
        path = destination / f'{i:02}_{name}.sql'
        path.write_text(source,encoding='utf-8',newline='\n')
        n = tokens(source)
        manifest.append({'path':path.relative_to(ROOT).as_posix(),'language':'sql','tokens':n,'bytes':len(source.encode()),'sha256':hashlib.sha256(source.encode()).hexdigest(),'fixtures':count})
        total += n
    manifest_path.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    print('sql',total,'tokens',len(EXAMPLES),'files')

if __name__ == '__main__':
    build()
