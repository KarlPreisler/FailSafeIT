/* ============================================================================
   FAILSAFE IT – REGISTER FÖR KUNDER, KONSULTER OCH UPPDRAG
   Körs mot SQL Server LocalDB: (localdb)\mssqllocaldb
   ============================================================================ */

   /* ----------------------------------------------------------------------------
   1. ÅTERSTÄLL OCH SKAPA DATABASEN
   Skriptet ska kunna köras flera gånger. Om databasen redan finns raderas den
   och byggs upp på nytt.
   ---------------------------------------------------------------------------- */

   PRINT 'Återställer och skapar databasen...';
USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'FailSafeIT_Konsultregister')
BEGIN
    -- Kopplar bort andra öppna anslutningar så att databasen kan raderas
    ALTER DATABASE FailSafeIT_Konsultregister SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE FailSafeIT_Konsultregister;
END
GO

CREATE DATABASE FailSafeIT_Konsultregister;
GO

USE FailSafeIT_Konsultregister;
GO


/* ----------------------------------------------------------------------------
   2. SKAPA TABELLER
   Tabeller utan främmande nycklar skapas först, eftersom en främmande nyckel
   bara kan peka på en tabell som redan finns.
   ---------------------------------------------------------------------------- */
PRINT 'Skapar tabeller...';

-- 2.1 Oberoende tabeller

CREATE TABLE Specialitet (
    SpecialitetId   INT IDENTITY(1,1)   NOT NULL,
    Namn            NVARCHAR(50)        NOT NULL,

    CONSTRAINT PK_Specialitet PRIMARY KEY (SpecialitetId),
    CONSTRAINT UQ_Specialitet_Namn UNIQUE (Namn)
);

CREATE TABLE Kund (
    KundId              INT IDENTITY(1,1)   NOT NULL,
    Organisationsnummer CHAR(11)            NOT NULL,
    Foretagsnamn        NVARCHAR(100)       NOT NULL,
    Epost               NVARCHAR(256)       NOT NULL,
    Telefonnummer       VARCHAR(20)         NOT NULL,

    CONSTRAINT PK_Kund PRIMARY KEY (KundId),
    CONSTRAINT UQ_Kund_Organisationsnummer UNIQUE (Organisationsnummer),
    -- Format: NNNNNN-NNNN
    CONSTRAINT CK_Kund_Organisationsnummer
        CHECK (Organisationsnummer LIKE '[0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]')
);

-- 2.2 Beroende tabeller

CREATE TABLE Konsult (
    KonsultId       INT IDENTITY(1,1)   NOT NULL,
    Personnummer    CHAR(13)            NOT NULL,
    Fornamn         NVARCHAR(50)        NOT NULL,
    Efternamn       NVARCHAR(50)        NOT NULL,
    Timpris         DECIMAL(10,2)       NOT NULL,
    SpecialitetId   INT                 NOT NULL,

    CONSTRAINT PK_Konsult PRIMARY KEY (KonsultId),
    CONSTRAINT UQ_Konsult_Personnummer UNIQUE (Personnummer),
    -- Format: ÅÅÅÅMMDD-NNNN
    CONSTRAINT CK_Konsult_Personnummer
        CHECK (Personnummer LIKE '[12][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'),
    CONSTRAINT CK_Konsult_Timpris CHECK (Timpris > 0),
    CONSTRAINT FK_Konsult_Specialitet FOREIGN KEY (SpecialitetId)
        REFERENCES Specialitet (SpecialitetId)
        ON DELETE NO ACTION
);

CREATE TABLE Uppdrag (
    UppdragId       INT IDENTITY(1,1)   NOT NULL,
    KundId          INT                 NOT NULL,
    KonsultId       INT                 NOT NULL,
    Rollbeskrivning NVARCHAR(200)       NOT NULL,
    Startdatum      DATE                NOT NULL,
    Slutdatum       DATE                NOT NULL,

    CONSTRAINT PK_Uppdrag PRIMARY KEY (UppdragId),
    CONSTRAINT FK_Uppdrag_Kund FOREIGN KEY (KundId)
        REFERENCES Kund (KundId)
        ON DELETE NO ACTION,
    CONSTRAINT FK_Uppdrag_Konsult FOREIGN KEY (KonsultId)
        REFERENCES Konsult (KonsultId)
        ON DELETE NO ACTION,
    CONSTRAINT CK_Uppdrag_Datum CHECK (Slutdatum >= Startdatum)
);
GO