-- DIALECT: Microsoft SQL Server 2019+ (T-SQL), not SQLite or PostgreSQL.
-- RUNTIME: local SQL Server engine + sqlcmd; scratch session, #temp objects only.
-- Intended command: sqlcmd -b -S localhost -E -i constraint_migration.sql
-- No credentials are embedded. Engine execution is required for validation.
-- Semantics reference: https://learn.microsoft.com/sql/t-sql/language-elements/try-catch-transact-sql
SET NOCOUNT ON;
SET XACT_ABORT OFF; -- Expected statement failures must leave this fixture usable.
BEGIN TRY
    BEGIN TRANSACTION;
    CREATE TABLE #Invoice(
        Id int NOT NULL PRIMARY KEY,
        ExternalId nvarchar(24) NOT NULL UNIQUE,
        Quantity int NOT NULL CHECK(Quantity BETWEEN 1 AND 10)
    );
    INSERT INTO #Invoice VALUES(1,N'local-1',2);
    BEGIN TRY
        INSERT INTO #Invoice VALUES(2,N'bad-range',0);
        THROW 51000,'quantity violation was accepted',1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
    END CATCH;
    IF XACT_STATE() <> 1 OR (SELECT COUNT(*) FROM #Invoice) <> 1
        THROW 51001,'range rejection changed state or transaction',1;
    BEGIN TRY
        INSERT INTO #Invoice VALUES(2,N'local-1',3);
        THROW 51002,'duplicate was accepted',1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (2601,2627) THROW;
    END CATCH;
    IF (SELECT COUNT(*) FROM #Invoice) <> 1 THROW 51003,'duplicate changed state',1;
    SAVE TRANSACTION pending_change;
    UPDATE #Invoice SET Quantity=9 WHERE Id=1;
    ROLLBACK TRANSACTION pending_change;
    IF (SELECT Quantity FROM #Invoice WHERE Id=1) <> 2 THROW 51004,'savepoint rollback failed',1;
    -- Compile statements referencing a newly added column at a later dynamic
    -- scope: SQL Server can otherwise bind them before ALTER TABLE runs.
    ALTER TABLE #Invoice ADD Note nvarchar(100) NOT NULL DEFAULT N'' WITH VALUES;
    DECLARE @literal nvarchar(100)=N'''); DROP TABLE #Invoice; --';
    EXEC sys.sp_executesql
        N'UPDATE #Invoice SET Note=@note WHERE Id=@id',
        N'@note nvarchar(100),@id int',@note=@literal,@id=1;
    EXEC sys.sp_executesql
        N'IF NOT EXISTS(SELECT 1 FROM #Invoice WHERE Id=1 AND Note=@note)
            THROW 51005,''parameter binding changed literal'',1;',
        N'@note nvarchar(100)',@note=@literal;
    ROLLBACK TRANSACTION;
    PRINT 'T-SQL: constraints, exact errors, savepoints, migration and bound text passed';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
