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


/* ----------------------------------------------------------------------------
   3. TESTDATA
   Raderna läggs in i samma ordning som tabellerna skapades, så att varje
   främmande nyckel pekar på en rad som redan finns. Databasen byggs om från
   noll vid varje körning, så IDENTITY ger alltid samma id-värden (1, 2, 3 ...).

   All persondata är fiktiv: personnummer och organisationsnummer har felaktig
   kontrollsiffra och kan inte tillhöra verkliga personer eller företag.
   ---------------------------------------------------------------------------- */
PRINT 'Lägger in testdata...';

INSERT INTO Specialitet (Namn)
VALUES
    (N'Cybersecurity'),     -- SpecialitetId 1
    (N'DevOps'),            -- SpecialitetId 2
    (N'C# Developer'),      -- SpecialitetId 3
    (N'Cloud Engineer');    -- SpecialitetId 4 (ingen konsult ännu)

INSERT INTO Kund (Organisationsnummer, Foretagsnamn, Epost, Telefonnummer)
VALUES
    ('559900-1237', N'Ljusdal Logistik AB',   N'it@ljusdallogistik.example',  '070-1740605'),   -- KundId 1
    ('559900-4561', N'Vasa Hälsa AB',         N'kontakt@vasahalsa.example',   '070-1740610'),   -- KundId 2
    ('559900-7895', N'Bergström Fintech AB',  N'info@bergstromfintech.example', '070-1740620'), -- KundId 3
    ('559900-3217', N'Kustlinjen Media AB',   N'hej@kustlinjen.example',      '070-1740630');   -- KundId 4 (inga uppdrag)

INSERT INTO Konsult (Personnummer, Fornamn, Efternamn, Timpris, SpecialitetId)
VALUES
    ('19850312-1232', N'Anna',  N'Lindqvist', 1450.00, 1),  -- KonsultId 1, Cybersecurity
    ('19900724-4561', N'Erik',  N'Holm',      1200.00, 2),  -- KonsultId 2, DevOps
    ('19780115-7898', N'Sara',  N'Ekström',   1100.00, 3),  -- KonsultId 3, C# Developer
    ('19930602-2349', N'Omar',  N'Haddad',    1350.00, 1);  -- KonsultId 4, Cybersecurity

INSERT INTO Uppdrag (KundId, KonsultId, Rollbeskrivning, Startdatum, Slutdatum)
VALUES
    (1, 1, N'Säkerhetsgranskning av API-miljö',          '2026-09-01', '2026-12-18'),
    (1, 2, N'Uppsättning av CI/CD-pipeline',             '2026-03-02', '2026-06-30'),
    (2, 3, N'Vidareutveckling av bokningssystem i C#',   '2026-10-05', '2027-03-31'),
    (2, 4, N'Penetrationstest av patientportal',         '2027-01-11', '2027-02-26'),
    (3, 1, N'Incidenthantering och loggövervakning',     '2026-08-17', '2027-06-30'),
    (1, 1, N'Uppföljande säkerhetsgranskning',           '2027-04-06', '2027-04-30');
GO


/* ----------------------------------------------------------------------------
   4. FRÅGOR
   ---------------------------------------------------------------------------- */
-- Fråga A: Namn och timpris för konsulter med timpris över 1200 kr, högst pris först
PRINT 'Fråga A: Konsulter med timpris över 1200 kr';
SELECT
    CONCAT(Fornamn, ' ', Efternamn) AS Konsult,
    Timpris
FROM Konsult
WHERE Timpris > 1200
ORDER BY Timpris DESC;

-- Fråga B: Alla uppdrag med kundens företagsnamn, konsultens namn samt start- och slutdatum
PRINT 'Fråga B: Sammanställning av alla uppdrag';
SELECT
    Kund.Foretagsnamn                                       AS Kund,
    CONCAT(Konsult.Fornamn, ' ', Konsult.Efternamn)         AS Konsult,
    Uppdrag.Startdatum,
    Uppdrag.Slutdatum
FROM Uppdrag
INNER JOIN Kund    ON Kund.KundId       = Uppdrag.KundId
INNER JOIN Konsult ON Konsult.KonsultId = Uppdrag.KonsultId
ORDER BY Uppdrag.Startdatum;

-- Fråga C: Antal uppdrag per kund
PRINT 'Fråga C: Antal uppdrag per kund';
SELECT
    Kund.Foretagsnamn           AS Kund,
    COUNT(Uppdrag.UppdragId)    AS AntalUppdrag
FROM Kund
LEFT JOIN Uppdrag ON Uppdrag.KundId = Kund.KundId
GROUP BY Kund.KundId, Kund.Foretagsnamn
ORDER BY AntalUppdrag DESC, Kund.Foretagsnamn;

-- Fråga D: Uppdatera timpriset för en specifik konsult (KonsultId 3 = Sara Ekström)
PRINT 'Fråga D: Uppdaterar timpris för en konsult';
UPDATE Konsult
SET Timpris = 1150.00
WHERE KonsultId = 3;