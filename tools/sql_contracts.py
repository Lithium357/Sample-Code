"""Behavioral SQL contracts that SQLite scripts cannot catch by themselves.

Expected failures must have the intended extended error code AND message.
Persistent database state is compared immediately after rejection, before the
test's savepoint rollback, so rollback cannot hide an erroneous partial write.
"""
import sqlite3
import hashlib

OBSERVATIONS = []

TRIGGER = 'SQLITE_CONSTRAINT_TRIGGER'
CHECK = 'SQLITE_CONSTRAINT_CHECK'
UNIQUE = 'SQLITE_CONSTRAINT_UNIQUE'
FK = 'SQLITE_CONSTRAINT_FOREIGNKEY'
NOT_NULL = 'SQLITE_CONSTRAINT_NOTNULL'

# (statement, extended error name, identifying message substring).
REJECTIONS = {
    '14_nonoverlapping_bookings.sql': [
        ("INSERT INTO booking VALUES(10,10,570,630)", TRIGGER, 'room already booked'),
        ("INSERT INTO booking VALUES(10,10,500,700)", TRIGGER, 'room already booked'),
        ("INSERT INTO booking VALUES(10,10,550,560)", TRIGGER, 'room already booked'),
        ("UPDATE booking SET start_minute=590 WHERE id=2", TRIGGER, 'room already booked'),
        ("UPDATE booking SET room_id=10 WHERE id=3", TRIGGER, 'room already booked'),
        ("INSERT INTO booking VALUES(10,10,720,780),(11,10,570,630)", TRIGGER, 'room already booked'),
        ("INSERT INTO booking VALUES(10,30,600,600)", CHECK, 'CHECK constraint failed'),
        ("INSERT INTO booking VALUES(10,30,'bad','zzz')", CHECK, 'booking_integer_values'),
        ("INSERT INTO booking VALUES(10,30,1.5,2.5)", CHECK, 'booking_integer_values'),
        ("INSERT INTO booking VALUES(10,'text-room',700,800)", CHECK, 'booking_integer_values'),
        ("UPDATE booking SET start_minute='bad',end_minute='zzz' WHERE id=3", CHECK, 'booking_integer_values'),
        ("UPDATE booking SET room_id='text-room' WHERE id=3", CHECK, 'booking_integer_values'),
        ("INSERT INTO booking VALUES(10,30,0,9223372036854775808)", CHECK, 'booking_integer_values'),
        ("INSERT INTO booking VALUES(10,NULL,0,1)", NOT_NULL, 'booking.room_id'),
        ("UPDATE booking SET start_minute=NULL WHERE id=3", NOT_NULL, 'booking.start_minute'),
    ],
    '13_audit_triggers.sql': [
        ("UPDATE task SET status='active' WHERE id=1", TRIGGER, 'completed tasks cannot be reopened'),
        ("INSERT INTO task VALUES(2,'bad','unknown')", CHECK, 'CHECK constraint failed'),
        ("UPDATE task SET status=NULL WHERE id=1", NOT_NULL, 'task.status'),
        ("INSERT INTO task VALUES(2,'pending','queued'),(3,'invalid','unknown')", CHECK, 'CHECK constraint failed'),
    ],
    '23_savepoints_and_rollback.sql': [
        ("UPDATE wallet SET cents=-1 WHERE id=1", CHECK, 'CHECK constraint failed'),
        ("INSERT INTO transfer VALUES(99,1,999,1)", FK, 'FOREIGN KEY constraint failed'),
    ],
    '01_inventory_ledger.sql': [
        ("INSERT INTO movement VALUES(99,999,1,'receipt')", FK, 'FOREIGN KEY constraint failed'),
        ("INSERT INTO movement VALUES(99,1,0,'receipt')", CHECK, 'CHECK constraint failed'),
    ],
    'double_entry_posting.sql': [
        ('UPDATE line SET debit=debit+1 WHERE id=1',TRIGGER,'posted lines are immutable'),
        ('DELETE FROM line WHERE id=1',TRIGGER,'posted lines are immutable'),
        ('INSERT INTO line(journal_id,account_id,debit,credit) VALUES(1,1,1,0)',TRIGGER,'posted lines are immutable'),
        ("UPDATE journal SET state='posted' WHERE id=3",TRIGGER,'journal must contain balanced lines'),
        ('UPDATE line SET journal_id=1 WHERE id=5',TRIGGER,'posted lines are immutable'),
        ("INSERT INTO journal(id,external_key,state) VALUES(99,'bypass','posted')",TRIGGER,'create a draft before posting'),
    ],
    'bill_of_materials.sql': [
        ('INSERT INTO component VALUES(2,1,1)',TRIGGER,'component cycle'),
        ('UPDATE component SET child=1 WHERE parent=2 AND child=4',TRIGGER,'component cycle'),
        ('INSERT INTO component VALUES(4,7,1)',TRIGGER,'raw material cannot contain components'),
        ('UPDATE part SET assembly=0 WHERE id=2',TRIGGER,'assembly still has components'),
    ],
}

def snapshot(connection):
    # SQLite's dump includes every persistent table and trigger, including audit
    # rows. Fixture temp checks tables are deliberately not part of domain state.
    return tuple(connection.iterdump())

def reject(connection, statement, code, message):
    before = snapshot(connection)
    connection.execute('SAVEPOINT contract_case')
    try:
        try:
            connection.execute(statement)
        except sqlite3.IntegrityError as error:
            OBSERVATIONS.append({'sql':statement,'expected_error':code,'actual_error':error.sqlite_errorname,
                                 'message':str(error),'before_state_sha256':hashlib.sha256(repr(before).encode()).hexdigest(),
                                 'after_state_sha256':hashlib.sha256(repr(snapshot(connection)).encode()).hexdigest()})
            if error.sqlite_errorname != code or message not in str(error):
                raise AssertionError(f'wrong rejection: {error.sqlite_errorname}: {error}') from error
        else:
            raise AssertionError('accepted forbidden operation: ' + statement)
        if snapshot(connection) != before:
            raise AssertionError('rejected statement changed database state: ' + statement)
    finally:
        connection.execute('ROLLBACK TO contract_case')
        connection.execute('RELEASE contract_case')
    if snapshot(connection) != before:
        raise AssertionError('test cleanup changed state')

def check_contracts(connection, name):
    cases = REJECTIONS.get(name, [])
    for case in cases:
        reject(connection, *case)
    positive = 0
    if name == '13_audit_triggers.sql':
        before = snapshot(connection)
        assert connection.execute('SELECT sequence,task_id,old_status,new_status FROM status_history ORDER BY sequence').fetchall() == [(1,1,'queued','active'),(2,1,'active','done')], 'audit pairs differ'
        assert connection.execute('SELECT id,title,status FROM task').fetchall() == [(1,'Import verified catalog','done')]
        connection.execute('SAVEPOINT audit_cases')
        try:
            connection.execute("INSERT INTO task VALUES(2,'Two','queued'),(3,'Three','queued')")
            assert connection.execute('SELECT COUNT(*) FROM status_history').fetchone() == (2,)
            connection.execute("UPDATE task SET status='active' WHERE id IN (2,3)")
            assert connection.execute('SELECT task_id,old_status,new_status FROM status_history WHERE sequence>2 ORDER BY task_id').fetchall() == [(2,'queued','active'),(3,'queued','active')], 'multirow audit pairs differ'
            # SQL does not promise a row visitation order, so compare by task id.
            after_transition = snapshot(connection)
            connection.execute("UPDATE task SET status=status")
            connection.execute("UPDATE task SET status='active' WHERE id=999")
            assert snapshot(connection) == after_transition, 'no-op/missing update created audit noise'
            connection.execute("UPDATE task SET title='Changed' WHERE id=2")
            assert connection.execute('SELECT COUNT(*) FROM status_history').fetchone() == (4,)
            connection.execute("UPDATE task SET status='done' WHERE id IN (2,3)")
            assert connection.execute('SELECT task_id,old_status,new_status FROM status_history WHERE sequence>4 ORDER BY task_id').fetchall() == [(2,'active','done'),(3,'active','done')]
            assert connection.execute('SELECT id,status FROM task ORDER BY id').fetchall() == [(1,'done'),(2,'done'),(3,'done')]
            positive = 8
        finally:
            connection.execute('ROLLBACK TO audit_cases')
            connection.execute('RELEASE audit_cases')
        assert snapshot(connection) == before
    if name == '14_nonoverlapping_bookings.sql':
        before = snapshot(connection)
        assert connection.execute('SELECT room_id,booked_minutes FROM booking_totals ORDER BY room_id').fetchall() == [(10,120),(20,120)]
        connection.execute('SAVEPOINT accepted_cases')
        try:
            # Updating a row to itself must not conflict with its own interval.
            connection.execute('UPDATE booking SET start_minute=start_minute WHERE id=1')
            assert snapshot(connection) == before
            connection.execute('INSERT INTO booking VALUES(10,10,660,720)')
            connection.execute('UPDATE booking SET start_minute=720,end_minute=780 WHERE id=10')
            connection.execute('INSERT INTO booking VALUES(11,30,540,660)')
            assert connection.execute('SELECT start_minute,end_minute FROM booking WHERE id=10').fetchone() == (720,780)
            assert connection.execute('SELECT COUNT(*) FROM booking').fetchone()[0] == 5
            connection.execute("INSERT INTO booking VALUES(12,'40','0','10')")
            assert connection.execute('''SELECT room_id,start_minute,end_minute,
                typeof(room_id),typeof(start_minute),typeof(end_minute)
                FROM booking WHERE id=12''').fetchone() == (40,0,10,'integer','integer','integer')
            assert connection.execute('SELECT COUNT(*) FROM booking').fetchone()[0] == 6
            assert connection.execute('SELECT room_id,booked_minutes FROM booking_totals ORDER BY room_id').fetchall() == [(10,180),(20,120),(30,120),(40,10)]
            positive = 7
        finally:
            connection.execute('ROLLBACK TO accepted_cases')
            connection.execute('RELEASE accepted_cases')
        assert snapshot(connection) == before
    if name == '08_idempotent_upsert.sql':
        before = snapshot(connection)
        connection.execute('''INSERT INTO reading VALUES(1,1000,2,99999)
            ON CONFLICT(sensor_id,observed_at) DO UPDATE SET version=excluded.version,
            milliunits=excluded.milliunits WHERE excluded.version>reading.version''')
        assert snapshot(connection) == before, 'equal-version retry overwrote the reading'
        positive = 1
    return len(cases), positive

def mutations(source, name):
    """Selected rejection/behavior suites must detect specified broken variants."""
    if name == '13_audit_triggers.sql':
        variants = [
            ('drop prevent_reopening', None, 'prevent_reopening', 'accepted forbidden operation:'),
            ('drop record_status_change', None, 'record_status_change', 'multirow audit pairs differ'),
            ('remove no-op guard', source.replace('WHEN OLD.status <> NEW.status', ''), None, 'no-op/missing update created audit noise'),
        ]
        findings = []
        for label, replacement, trigger, expected in variants:
            with sqlite3.connect(':memory:') as connection:
                connection.executescript(source)
                if trigger:
                    connection.execute('DROP TRIGGER ' + trigger)
                else:
                    # Change only the trigger, preserving baseline fixture checks.
                    start = replacement.index('CREATE TRIGGER record_status_change')
                    end = replacement.index('END;', start) + len('END;')
                    connection.execute('DROP TRIGGER record_status_change')
                    connection.executescript(replacement[start:end])
                reason = None
                try: check_contracts(connection, name)
                except AssertionError as error: reason = str(error)
                if not reason or expected not in reason:
                    raise AssertionError('audit negative control failed for wrong reason: ' + label + ': ' + str(reason))
                findings.append({'mutation':label,'detected_by':reason})
        return findings
    if name != '14_nonoverlapping_bookings.sql':
        return []
    findings = []
    for trigger in ('prevent_overlap_insert','prevent_overlap_update'):
        with sqlite3.connect(':memory:') as connection:
            connection.executescript(source)
            connection.execute('DROP TRIGGER ' + trigger)
            caught = False
            try:
                check_contracts(connection, name)
            except AssertionError as error:
                caught = True
                findings.append({'mutation':'drop '+trigger,'detected_by':str(error)})
            if not caught:
                raise AssertionError('suite failed to detect removed trigger: ' + trigger)
    begin=source.index('    CONSTRAINT booking_integer_values CHECK(')
    end=source.index('),',begin)+2
    without_integer_check=source[:begin]+source[end:]
    with sqlite3.connect(':memory:') as connection:
        connection.executescript(without_integer_check)
        reason=None
        try:check_contracts(connection,name)
        except AssertionError as error:reason=str(error)
        if not reason or "accepted forbidden operation: INSERT INTO booking VALUES(10,30,'bad','zzz')" not in reason:
            raise AssertionError('integer-check negative control did not fail for the intended operation')
        findings.append({'mutation':'remove booking_integer_values','detected_by':reason})
    return findings
