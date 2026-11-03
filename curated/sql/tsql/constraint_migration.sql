-- DIALECT: Microsoft SQL Server 2019+ (T-SQL), not SQLite or PostgreSQL.
-- RUNTIME: local SQL Server engine + sqlcmd; scratch session, #temp objects only.
-- Intended command: sqlcmd -b -S localhost -E -i constraint_migration.sql
-- No credentials are embedded. Engine execution is required for validation.
-- Semantics reference: https://learn.microsoft.com/sql/t-sql/language-elements/try-catch-transact-sql
-- Actual engine versions are in source-bound evidence. This is one fresh
-- session, with no preexisting transaction. Schema syntax requires SQL Server;
-- a clean run is not a claim that every 2019+ engine version was tested.
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
    SELECT Id,ExternalId,Quantity INTO #Before FROM #Invoice;
    DECLARE @rejected int=0;
    BEGIN TRY
        INSERT INTO #Invoice VALUES(2,N'bad-range',0);
        THROW 51000,'quantity violation was accepted',1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
        SET @rejected+=1;
    END CATCH;
    IF XACT_STATE() <> 1 OR @@TRANCOUNT <> 1
        OR EXISTS(SELECT * FROM #Invoice EXCEPT SELECT * FROM #Before)
        OR EXISTS(SELECT * FROM #Before EXCEPT SELECT * FROM #Invoice)
        THROW 51001,'range rejection changed state or transaction',1;
    BEGIN TRY
        INSERT INTO #Invoice VALUES(2,N'local-1',3);
        THROW 51002,'duplicate was accepted',1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (2601,2627) THROW;
        SET @rejected+=1;
    END CATCH;
    IF XACT_STATE() <> 1 OR @@TRANCOUNT <> 1
        OR EXISTS(SELECT * FROM #Invoice EXCEPT SELECT * FROM #Before)
        OR EXISTS(SELECT * FROM #Before EXCEPT SELECT * FROM #Invoice)
        THROW 51003,'duplicate changed state',1;
    BEGIN TRY
        INSERT INTO #Invoice VALUES(2,NULL,3);
        THROW 51006,'NULL external id was accepted',1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 515 THROW;
        SET @rejected+=1;
    END CATCH;
    IF XACT_STATE() <> 1 OR @@TRANCOUNT <> 1
        OR EXISTS(SELECT * FROM #Invoice EXCEPT SELECT * FROM #Before)
        OR EXISTS(SELECT * FROM #Before EXCEPT SELECT * FROM #Invoice)
        THROW 51007,'NULL rejection changed state',1;
    BEGIN TRY
        INSERT INTO #Invoice VALUES(2,N'too-many',11);
        THROW 51008,'upper quantity limit was accepted',1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
        SET @rejected+=1;
    END CATCH;
    IF XACT_STATE() <> 1 OR @@TRANCOUNT <> 1
        OR EXISTS(SELECT * FROM #Invoice EXCEPT SELECT * FROM #Before)
        OR EXISTS(SELECT * FROM #Before EXCEPT SELECT * FROM #Invoice)
        THROW 51009,'upper-limit rejection changed state',1;
    BEGIN TRY
        UPDATE #Invoice SET Quantity=0 WHERE Id=1;
        THROW 51010,'invalid quantity update was accepted',1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
        SET @rejected+=1;
    END CATCH;
    IF XACT_STATE() <> 1 OR @@TRANCOUNT <> 1
        OR EXISTS(SELECT * FROM #Invoice EXCEPT SELECT * FROM #Before)
        OR EXISTS(SELECT * FROM #Before EXCEPT SELECT * FROM #Invoice)
        THROW 51011,'rejected update changed state',1;
    BEGIN TRY
        -- A valid row in the same statement must not survive the failed row.
        INSERT INTO #Invoice VALUES(2,N'would-be-valid',1),(3,N'bad-member',11);
        THROW 51012,'invalid multirow insert was accepted',1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 547 THROW;
        SET @rejected+=1;
    END CATCH;
    IF XACT_STATE() <> 1 OR @@TRANCOUNT <> 1
        OR EXISTS(SELECT * FROM #Invoice EXCEPT SELECT * FROM #Before)
        OR EXISTS(SELECT * FROM #Before EXCEPT SELECT * FROM #Invoice)
        THROW 51013,'multirow rejection left partial state',1;
    IF @rejected <> 6 THROW 51014,'expected rejection path was skipped',1;
    UPDATE #Invoice SET Quantity=9 WHERE Id=999;
    IF @@ROWCOUNT <> 0 THROW 51015,'missing-row update affected data',1;
    INSERT INTO #Invoice VALUES(2,N'lower-bound',1),(3,N'upper-bound',10);
    IF (SELECT COUNT(*) FROM #Invoice) <> 3
        OR NOT EXISTS(SELECT 1 FROM #Invoice WHERE Id=2 AND ExternalId=N'lower-bound' AND Quantity=1)
        OR NOT EXISTS(SELECT 1 FROM #Invoice WHERE Id=3 AND ExternalId=N'upper-bound' AND Quantity=10)
        THROW 51016,'accepted quantity boundary rows differ',1;
    DELETE FROM #Invoice WHERE Id IN (2,3);
    SAVE TRANSACTION pending_change;
    UPDATE #Invoice SET Quantity=9 WHERE Id=1;
    ROLLBACK TRANSACTION pending_change;
    IF XACT_STATE() <> 1 OR @@TRANCOUNT <> 1
        OR EXISTS(SELECT * FROM #Invoice EXCEPT SELECT * FROM #Before)
        OR EXISTS(SELECT * FROM #Before EXCEPT SELECT * FROM #Invoice)
        THROW 51004,'savepoint rollback failed',1;
    -- Compile statements referencing a newly added column at a later dynamic
    -- scope: SQL Server can otherwise bind them before ALTER TABLE runs.
    ALTER TABLE #Invoice ADD Note nvarchar(100) NOT NULL DEFAULT N'' WITH VALUES;
    -- Check backfill BEFORE an explicit update could hide a wrong default.
    -- Later-scope compilation is still required for every reference to Note.
    DECLARE @migration_rejected int=0;
    EXEC sys.sp_executesql
        N'IF (SELECT COUNT(*) FROM #Invoice) <> 1
            OR NOT EXISTS(SELECT 1 FROM #Invoice WHERE Id=1 AND DATALENGTH(Note)=0)
            THROW 51017,''migration backfill default differs'',1;
          INSERT INTO #Invoice(Id,ExternalId,Quantity) VALUES(2,N''new-default'',1);
          IF NOT EXISTS(SELECT 1 FROM #Invoice WHERE Id=2 AND DATALENGTH(Note)=0)
            THROW 51018,''new-row default differs'',1;
          BEGIN TRY
            UPDATE #Invoice SET Note=NULL WHERE Id=2;
            THROW 51019,''NULL note update was accepted'',1;
          END TRY
          BEGIN CATCH
            IF ERROR_NUMBER() <> 515 THROW;
            SET @rejections+=1;
          END CATCH;
          IF XACT_STATE() <> 1 OR @@TRANCOUNT <> 1
            OR (SELECT COUNT(*) FROM #Invoice) <> 2
            OR NOT EXISTS(SELECT 1 FROM #Invoice WHERE Id=2 AND DATALENGTH(Note)=0)
            THROW 51020,''rejected note update changed state'',1;
          DELETE FROM #Invoice WHERE Id=2;',
        N'@rejections int OUTPUT',@rejections=@migration_rejected OUTPUT;
    IF @migration_rejected <> 1 THROW 51021,'migration rejection path was skipped',1;
    DECLARE @literal nvarchar(100)=N'''); DROP TABLE #Invoice; --';
    EXEC sys.sp_executesql
        N'UPDATE #Invoice SET Note=@note WHERE Id=@id',
        N'@note nvarchar(100),@id int',@note=@literal,@id=1;
    EXEC sys.sp_executesql
        N'IF NOT EXISTS(SELECT 1 FROM #Invoice WHERE Id=1
            AND CONVERT(varbinary(200),Note)=CONVERT(varbinary(200),@note))
            THROW 51005,''parameter binding changed literal'',1;',
        N'@note nvarchar(100)',@note=@literal;
    ROLLBACK TRANSACTION;
    IF @@TRANCOUNT <> 0 OR XACT_STATE() <> 0
        THROW 51022,'outer rollback left a transaction',1;
    IF OBJECT_ID(N'tempdb..#Invoice') IS NOT NULL OR OBJECT_ID(N'tempdb..#Before') IS NOT NULL
        THROW 51023,'rolled-back fixture schema survived',1;
    PRINT 'T-SQL: constraints, exact errors, savepoints, migration and bound text passed';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
