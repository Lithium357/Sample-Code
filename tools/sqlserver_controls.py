"""Specified bad T-SQL variants; harness/control material, not training volume."""


def variants(source):
    definitions = [
        ('remove quantity CHECK', ' CHECK(Quantity BETWEEN 1 AND 10)', '',
         51000, 'quantity violation was accepted'),
        ('remove external-id UNIQUE', 'ExternalId nvarchar(24) NOT NULL UNIQUE',
         'ExternalId nvarchar(24) NOT NULL', 51002, 'duplicate was accepted'),
        ('skip savepoint rollback', '    ROLLBACK TRANSACTION pending_change;', '',
         51004, 'savepoint rollback failed'),
        ('wrong migration default', "NOT NULL DEFAULT N'' WITH VALUES",
         "NOT NULL DEFAULT N'wrong' WITH VALUES", 51017, 'migration backfill default differs'),
        ('wrong bound note', '@note=@literal,@id=1;', "@note=N'changed',@id=1;",
         51005, 'parameter binding changed literal'),
    ]
    result = []
    for name, old, new, code, message in definitions:
        if source.count(old) != 1:
            raise AssertionError('negative-control edit target is not unique: ' + name)
        result.append(dict(name=name, source=source.replace(old, new), error=code, message=message))
    return result
