
GO

-- Clean rebuild: removes the old/incomplete objects so this script can be run from scratch.
-- WARNING: this deletes the existing tables/data in the cinema database.
IF OBJECT_ID(N'dbo.Ticket', N'U') IS NOT NULL DROP TABLE dbo.Ticket;
IF OBJECT_ID(N'dbo.PaymentMethod', N'U') IS NOT NULL DROP TABLE dbo.PaymentMethod;
IF OBJECT_ID(N'dbo.Payment', N'U') IS NOT NULL DROP TABLE dbo.Payment;
IF OBJECT_ID(N'dbo.MovieLanguage', N'U') IS NOT NULL DROP TABLE dbo.MovieLanguage;
IF OBJECT_ID(N'dbo.MovieActor', N'U') IS NOT NULL DROP TABLE dbo.MovieActor;
IF OBJECT_ID(N'dbo.MovieGenre', N'U') IS NOT NULL DROP TABLE dbo.MovieGenre;
IF OBJECT_ID(N'dbo.[Session]', N'U') IS NOT NULL DROP TABLE dbo.[Session];
IF OBJECT_ID(N'dbo.Seat', N'U') IS NOT NULL DROP TABLE dbo.Seat;
IF OBJECT_ID(N'dbo.Hall', N'U') IS NOT NULL DROP TABLE dbo.Hall;
IF OBJECT_ID(N'dbo.[User]', N'U') IS NOT NULL DROP TABLE dbo.[User];
IF OBJECT_ID(N'dbo.Movie', N'U') IS NOT NULL DROP TABLE dbo.Movie;
IF OBJECT_ID(N'dbo.Cinema', N'U') IS NOT NULL DROP TABLE dbo.Cinema;
GO

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.Cinema', N'U') IS NULL-- Checks if the Cinema table exists before creating it
BEGIN
    CREATE TABLE dbo.Cinema (
        CinemaID   INT IDENTITY(1,1) PRIMARY KEY,
        CinemaName NVARCHAR(100) NOT NULL,
        Phone1     NVARCHAR(20) NOT NULL UNIQUE,
        Phone2     NVARCHAR(20) NULL,
        Province   NVARCHAR(50) NOT NULL,
        City       NVARCHAR(50) NOT NULL,
        Street     NVARCHAR(80) NULL,
        Alley      NVARCHAR(80) NULL,
        CONSTRAINT CK_Cinema_Phone1 CHECK (Phone1 LIKE '[0-9+]%')
    );
END
GO

IF OBJECT_ID(N'dbo.Hall', N'U') IS NULL-- Checks if the Cinema table exists before creating it
BEGIN
    CREATE TABLE dbo.Hall (
        CinemaID   INT NOT NULL,
        HallNumber INT NOT NULL,
        Capacity   INT NOT NULL,

        CONSTRAINT PK_Hall PRIMARY KEY (CinemaID, HallNumber),

        CONSTRAINT FK_Hall_Cinema
            FOREIGN KEY (CinemaID)
            REFERENCES dbo.Cinema(CinemaID)
            ON DELETE CASCADE
            ON UPDATE CASCADE-- Foreign key to Cinema with cascade on update and delete

    );
END
GO

IF OBJECT_ID(N'dbo.Seat', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Seat (
        CinemaID    INT NOT NULL,
        HallNumber  INT NOT NULL,
        RowNo       INT NOT NULL,
        SeatNo      INT NOT NULL,
        SeatType    NVARCHAR(30) NULL,

        CONSTRAINT PK_Seat PRIMARY KEY (CinemaID, HallNumber, RowNo, SeatNo),

        CONSTRAINT FK_Seat_Hall
            FOREIGN KEY (CinemaID, HallNumber)
            REFERENCES dbo.Hall (CinemaID, HallNumber)
            ON DELETE CASCADE
            ON UPDATE CASCADE
    );
END
GO

IF OBJECT_ID(N'dbo.Movie', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Movie (
        FilmID        INT IDENTITY(1,1) PRIMARY KEY,
        ImdbID        NVARCHAR(20) NOT NULL UNIQUE,
        Title         NVARCHAR(150) NOT NULL,
        AgeRating     NVARCHAR(20) NULL,
        ReleaseYear   SMALLINT NOT NULL,
        ReleaseMonth  TINYINT  NOT NULL,
        ReleaseDay    TINYINT  NOT NULL,
        DurationMin   INT NOT NULL,
        Director      NVARCHAR(100) NULL,
        Producer      NVARCHAR(100) NULL,
        Description   NVARCHAR(MAX) NULL,

        -- Ensures the movie release date values are within valid ranges
        CONSTRAINT CK_Movie_ReleaseDate CHECK (
            ReleaseYear >= 1888 AND
            ReleaseMonth BETWEEN 1 AND 12 AND
            ReleaseDay BETWEEN 1 AND 31
        ),

        CONSTRAINT CK_Movie_Duration CHECK (DurationMin > 0)-- Ensures movie duration is greater than zero

    );
END
GO


IF OBJECT_ID(N'dbo.[Session]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[Session] (
        CinemaID    INT NOT NULL,
        HallNumber  INT NOT NULL,
        ShowDate    DATE NOT NULL,
        StartTime   TIME(0) NOT NULL,
        EndTime     TIME(0) NOT NULL,
        FilmID      INT NOT NULL,
        Price       DECIMAL(10,2) NOT NULL,

        CONSTRAINT PK_Session PRIMARY KEY (CinemaID, HallNumber, ShowDate, StartTime),

        CONSTRAINT FK_Session_Hall
            FOREIGN KEY (CinemaID, HallNumber)
            REFERENCES dbo.Hall (CinemaID, HallNumber)
            ON DELETE CASCADE
            ON UPDATE CASCADE,

        CONSTRAINT FK_Session_Movie
            FOREIGN KEY (FilmID)
            REFERENCES dbo.Movie(FilmID)
            ON DELETE NO ACTION
            ON UPDATE CASCADE,

        -- Ensures session end time is after start time
        -- Ensures session price is greater than zero
        CONSTRAINT CK_Session_Time CHECK (EndTime > StartTime),
        CONSTRAINT CK_Session_Price CHECK (Price > 0)
    );
END
GO

IF OBJECT_ID(N'dbo.[User]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[User] (
        Username  NVARCHAR(50)  NOT NULL PRIMARY KEY,
        [Password]  NVARCHAR(255) NOT NULL,
        Role      NVARCHAR(30)  NOT NULL,
        Email     NVARCHAR(120) NULL UNIQUE,
        FirstName NVARCHAR(50)  NOT NULL,
        LastName  NVARCHAR(80)  NOT NULL,
        Phone     NVARCHAR(20)  NULL
    );
END
GO


IF OBJECT_ID(N'dbo.Payment', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Payment (
        PaymentID BIGINT IDENTITY PRIMARY KEY,
        PaymentDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        Amount DECIMAL(10,2) NOT NULL,
        PaymentStatus NVARCHAR(30) NOT NULL
    );
END
GO

IF OBJECT_ID(N'dbo.Ticket', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Ticket (
        QRCode       NVARCHAR(80) NOT NULL PRIMARY KEY,
        Username     NVARCHAR(50) NOT NULL,

        CinemaID     INT NOT NULL,
        HallNumber   INT NOT NULL,
        ShowDate     DATE NOT NULL,
        StartTime    TIME(0) NOT NULL,

        RowNo        INT NOT NULL,
        SeatNo       INT NOT NULL,

        PaymentID    BIGINT NULL,
        TicketStatus NVARCHAR(30) NOT NULL,
        BuyDate      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Ticket_User
            FOREIGN KEY (Username)
            REFERENCES dbo.[User](Username),

        CONSTRAINT FK_Ticket_Session
            FOREIGN KEY (CinemaID, HallNumber, ShowDate, StartTime)
            REFERENCES dbo.[Session](CinemaID, HallNumber, ShowDate, StartTime)
            ON DELETE CASCADE
            ON UPDATE CASCADE,

        CONSTRAINT FK_Ticket_Seat
            FOREIGN KEY (CinemaID, HallNumber, RowNo, SeatNo)
            REFERENCES dbo.Seat (CinemaID, HallNumber, RowNo, SeatNo)
            ON DELETE NO ACTION
            ON UPDATE NO ACTION,

        CONSTRAINT FK_Ticket_Payment
            FOREIGN KEY (PaymentID)
            REFERENCES dbo.Payment(PaymentID)
            ON DELETE SET NULL
            ON UPDATE CASCADE,

        CONSTRAINT UQ_Ticket_SessionSeat
            UNIQUE (CinemaID, HallNumber, ShowDate, StartTime, RowNo, SeatNo)-- Prevents booking the same seat more than once for the same session

    );
END
GO

IF OBJECT_ID(N'dbo.MovieGenre', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.MovieGenre (
        FilmID INT NOT NULL,
        Genre NVARCHAR(50) NOT NULL,

        CONSTRAINT PK_MovieGenre PRIMARY KEY (FilmID, Genre),

        CONSTRAINT FK_MovieGenre_Movie
            FOREIGN KEY (FilmID)
            REFERENCES dbo.Movie(FilmID)
            ON DELETE CASCADE
            ON UPDATE NO ACTION
    );
END
GO

IF OBJECT_ID(N'dbo.MovieActor', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.MovieActor (
        FilmID INT NOT NULL,
        ActorLastName NVARCHAR(100) NOT NULL,

        CONSTRAINT PK_MovieActor PRIMARY KEY (FilmID, ActorLastName),

        CONSTRAINT FK_MovieActor_Movie
            FOREIGN KEY (FilmID)
            REFERENCES dbo.Movie(FilmID)
            ON DELETE CASCADE
            ON UPDATE NO ACTION
    );
END
GO

IF OBJECT_ID(N'dbo.MovieLanguage', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.MovieLanguage (
        FilmID INT NOT NULL,
        [Language] NVARCHAR(50) NOT NULL,

        CONSTRAINT PK_MovieLanguage PRIMARY KEY (FilmID, [Language]),

        CONSTRAINT FK_MovieLanguage_Movie
            FOREIGN KEY (FilmID)
            REFERENCES dbo.Movie(FilmID)
            ON DELETE CASCADE
            ON UPDATE NO ACTION
    );
END
GO

IF OBJECT_ID(N'dbo.PaymentMethod', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PaymentMethod (
        PaymentID BIGINT NOT NULL,
        MethodType NVARCHAR(50) NOT NULL,

        CONSTRAINT PK_PaymentMethod PRIMARY KEY (PaymentID, MethodType),

        CONSTRAINT FK_PaymentMethod_Payment
            FOREIGN KEY (PaymentID)
            REFERENCES dbo.Payment(PaymentID)
            ON DELETE CASCADE
            ON UPDATE NO ACTION
    );
END
GO



INSERT INTO dbo.Cinema (CinemaName, Phone1, Phone2, Province, City, Street, Alley)
  VALUES (N'Mellat Cinema', N'02198765432', N'02198765433', N'Tehran', N'Tehran', N'Valiasr St', N'Park Alley');
INSERT INTO dbo.Cinema (CinemaName, Phone1, Phone2, Province, City, Street, Alley)
   VALUES (N'Cinema Farhang', N'02634567890', NULL, N'Alborz', N'Karaj', N'Shahid Beheshti St', N'Alley 3');



SELECT * FROM dbo.Cinema;

INSERT INTO dbo.Hall (CinemaID, HallNumber, Capacity) VALUES (1, 3, 200);
INSERT INTO dbo.Hall (CinemaID, HallNumber, Capacity) VALUES (2, 1, 200);
INSERT INTO dbo.Hall (CinemaID, HallNumber, Capacity) VALUES (1, 2, 200);


INSERT INTO dbo.Movie(ImdbID, Title, AgeRating, ReleaseYear, ReleaseMonth, ReleaseDay,DurationMin, Director, Producer, Description)
VALUES(N'tt0111161', N'The Shawshank Redemption', N'R',1994, 9, 23,142, N'Frank Darabont', N'Niki Marvin',N'Two imprisoned men bond over a number of years, finding solace and eventual redemption.');
INSERT INTO dbo.Movie(ImdbID, Title, AgeRating, ReleaseYear, ReleaseMonth, ReleaseDay,DurationMin, Director, Producer, Description)
VALUES(N'tt1375666', N'Inception', N'PG-13',2010, 7, 16,148, N'Christopher Nolan', N'Emma Thomas',N'A thief who steals corporate secrets through dream-sharing technology.');
INSERT INTO dbo.Movie(ImdbID, Title, AgeRating, ReleaseYear, ReleaseMonth, ReleaseDay, DurationMin, Director, Producer, Description)
VALUES(N'tt1832382', N'جدایی نادر از سیمین', N'+12',2011, 2, 15,123, N'اصغر فرهادی', N'اصغر فرهادی',N'درامی اجتماعی درباره یک زوج ایرانی درگیر مسائل خانوادگی.');

SELECT FilmID, Title FROM dbo.Movie;
SELECT CinemaID, HallNumber
FROM dbo.Hall-- Lists cinema IDs and hall numbers ordered by cinema and hall
ORDER BY CinemaID, HallNumber;

INSERT INTO dbo.[Session](CinemaID, HallNumber, ShowDate, StartTime, EndTime, FilmID, Price)
VALUES(2, 1, '2027-06-01', '18:00', '20:30', 1, 150000.00);
INSERT INTO dbo.Session
VALUES
(1, 3, '2027-06-01', '21:00', '23:30', 2, 180000.00),
(1, 2, '2027-06-01', '17:30', '19:40', 3, 120000.00);

INSERT INTO dbo.[User](Username, Password, Role, Email, FirstName, LastName, Phone)
VALUES
(N'admin01', N'pbkdf2:sha256:600000$2d8974521f2d0cd3$bd037bb533a54b11109752dbbedb7954c47c70a3393e0f21043c706d86994893', N'Admin',N'admin@cinema.com', N'علی', N'محمدی', N'09120000001'),
(N'cashier01', N'pbkdf2:sha256:600000$1a0b75d0721f45dc$e22c02c3ebfabd9c659a2ff3a14d31f02415d3aab5aa5329743b692abddcfee1', N'Staff',N'cashier01@cinema.com', N'سارا', N'کاظمی', N'09120000002'),
(N'operator01', N'pbkdf2:sha256:600000$cb4287ef768954fc$8b661ebb8a8882bcf0e283b077966870b9464501577fe2b1b445d23577a3645a', N'Operator',N'operator01@cinema.com', N'مهدی', N'رضایی', NULL),
(N'user01', N'pbkdf2:sha256:600000$d6628efacf9bb7c4$62f2ce8dc8f479bd4b9753a328f22b64447ddd80d7c238b8138223218d96c97a', N'Customer', N'user01@gmail.com', N'نازنین', N'احمدی', NULL);

INSERT INTO dbo.Payment (Amount, PaymentStatus)
VALUES 
(180000.00, N'Failed'),
(120000.00, N'Pending'),
(150000.00, N'Success');

INSERT INTO dbo.MovieGenre(FilmID, Genre)
VALUES
(1, N'Drama'),
(1, N'Crime'),

(2, N'Sci-Fi'),
(2, N'Action'),
(2, N'Thriller'),

(3, N'Drama'),
(3, N'Family');

INSERT INTO dbo.MovieActor(FilmID, ActorLastName)
VALUES
(1, N'Robbins'),
(1, N'Freeman'),

(2, N'DiCaprio'),
(2, N'Hardy'),
(2, N'Page'),

(3, N'معادی'),
(3, N'حاتمی'),
(3, N'شهاب حسینی');

INSERT INTO dbo.MovieLanguage(FilmID, [Language])
VALUES
(1, N'English'),
(2, N'English'),
(2, N'Japanese'),
(2, N'French'),
(3, N'Persian');

INSERT INTO dbo.PaymentMethod (PaymentID, MethodType)
VALUES
-- PaymentID = 1 (Failed)
(1, N'CreditCard'),
-- PaymentID = 2 (Pending)
(2, N'OnlineGateway'),
-- PaymentID = 3 (Success)
(3, N'CreditCard'),
(3, N'Wallet');


SELECT * FROM dbo.Hall;
select * from dbo.Seat;
select * from dbo.Session;
SELECT * FROM dbo.Cinema;
select * from dbo.Payment;
select * from dbo.Ticket 
ORDER BY BuyDate DESC;
select * from dbo.PaymentMethod;


SELECT name FROM sys.tables;-- Lists the names of all tables in the current database

SELECT * FROM Movie;
SELECT * FROM MovieActor;
SELECT * FROM MovieLanguage;
SELECT * FROM MovieGenre;
SELECT * FROM dbo.[User];

SELECT * -- Retrieves all movies whose titles contain the word "The"
FROM dbo.Movie
WHERE FilmID IN (
    SELECT FilmID
    FROM dbo.Movie
    WHERE Title LIKE N'%The%'
);


SELECT -- Lists movies and their genres
    m.Title,
    g.Genre
FROM dbo.Movie AS m
INNER JOIN dbo.MovieGenre AS g
    ON m.FilmID = g.FilmID;

SELECT -- Lists basic user information
    Username,
    Role,
    FirstName
FROM dbo.[User];

SELECT * FROM dbo.Cinema ORDER BY CinemaID; --order by
SELECT * FROM dbo.Hall ORDER BY CinemaID, HallNumber;
SELECT * FROM dbo.Seat ORDER BY CinemaID, HallNumber, RowNo, SeatNo;
SELECT * FROM dbo.[Session] ORDER BY CinemaID, HallNumber, ShowDate, StartTime;



SELECT t.QRCode, t.Username, t.CinemaID, t.HallNumber, t.ShowDate, t.StartTime, t.RowNo, t.SeatNo, t.TicketStatus,s.Price, m.Title
FROM dbo.Ticket t -- Displays ticket details along with session price and movie title
JOIN dbo.[Session] s
  ON s.CinemaID = t.CinemaID
 AND s.HallNumber = t.HallNumber
 AND s.ShowDate = t.ShowDate
 AND s.StartTime = t.StartTime
JOIN dbo.Movie m
  ON m.FilmID = s.FilmID;


-- Lists movies with their sessions (date, time, hall, and price)
SELECT m.FilmID, m.Title,
       s.CinemaID, s.HallNumber, s.ShowDate, s.StartTime, s.EndTime, s.Price
FROM dbo.Movie m
JOIN dbo.[Session] s ON s.FilmID = m.FilmID
ORDER BY m.FilmID, s.ShowDate, s.StartTime;


-- Generates seats for a specific hall (Rows x SeatsPerRow)
DECLARE @CinemaID INT = 1;
DECLARE @HallNumber INT = 3;
DECLARE @Rows INT = 10;
DECLARE @Capacity INT;

SELECT @Capacity = Capacity 
FROM dbo.Hall 
WHERE CinemaID = @CinemaID AND HallNumber = @HallNumber;

DECLARE @SeatsPerRow INT = @Capacity / @Rows;

;WITH RowCTE AS (
    SELECT 1 AS RowNo
    UNION ALL
    SELECT RowNo + 1 FROM RowCTE WHERE RowNo < @Rows
),
SeatCTE AS (
    SELECT 1 AS SeatNo
    UNION ALL
    SELECT SeatNo + 1 FROM SeatCTE WHERE SeatNo < @SeatsPerRow
)
INSERT INTO dbo.Seat (CinemaID, HallNumber, RowNo, SeatNo, SeatType)
SELECT @CinemaID, @HallNumber, r.RowNo, s.SeatNo,
       CASE WHEN r.RowNo <= 2 THEN N'VIP' ELSE N'Normal' END
FROM RowCTE r
CROSS JOIN SeatCTE s
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Seat x
    WHERE x.CinemaID=@CinemaID AND x.HallNumber=@HallNumber
      AND x.RowNo=r.RowNo AND x.SeatNo=s.SeatNo
)
OPTION (MAXRECURSION 0);

-- Lists all seats of a specific cinema hall ordered by row and seat number
SELECT *
FROM dbo.Seat
WHERE CinemaID = 1
  AND HallNumber = 3
ORDER BY RowNo, SeatNo;

GO--another batch
-- Generates seats for Cinema 2, Hall 1 (Rows x SeatsPerRow)
DECLARE @CinemaID INT = 2;
DECLARE @HallNumber INT = 1;
DECLARE @Rows INT = 10;
DECLARE @Capacity INT;

SELECT @Capacity = Capacity 
FROM dbo.Hall 
WHERE CinemaID = @CinemaID AND HallNumber = @HallNumber;

DECLARE @SeatsPerRow INT = @Capacity / @Rows;

;WITH RowCTE AS (
    SELECT 1 AS RowNo
    UNION ALL
    SELECT RowNo + 1 FROM RowCTE WHERE RowNo < @Rows
),
SeatCTE AS (
    SELECT 1 AS SeatNo
    UNION ALL
    SELECT SeatNo + 1 FROM SeatCTE WHERE SeatNo < @SeatsPerRow
)
INSERT INTO dbo.Seat (CinemaID, HallNumber, RowNo, SeatNo, SeatType)
SELECT 
    @CinemaID,
    @HallNumber,
    r.RowNo,
    s.SeatNo,
    CASE WHEN r.RowNo <= 2 THEN N'VIP' ELSE N'Normal' END
FROM RowCTE r
CROSS JOIN SeatCTE s
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.Seat x
    WHERE x.CinemaID = @CinemaID
      AND x.HallNumber = @HallNumber
      AND x.RowNo = r.RowNo
      AND x.SeatNo = s.SeatNo
)
OPTION (MAXRECURSION 0);


SELECT *
FROM dbo.Seat
WHERE CinemaID = 2
  AND HallNumber = 1
ORDER BY RowNo, SeatNo;
Go
-- Generate seats for Cinema 1, Hall 2
DECLARE @CinemaID INT = 1;
DECLARE @HallNumber INT = 2;
DECLARE @Rows INT = 10;
DECLARE @Capacity INT;

SELECT @Capacity = Capacity 
FROM dbo.Hall 
WHERE CinemaID = @CinemaID AND HallNumber = @HallNumber;

DECLARE @SeatsPerRow INT = @Capacity / @Rows;
;WITH RowCTE AS (
    SELECT 1 AS RowNo
    UNION ALL
    SELECT RowNo + 1 FROM RowCTE WHERE RowNo < @Rows
),
SeatCTE AS (
    SELECT 1 AS SeatNo
    UNION ALL
    SELECT SeatNo + 1 FROM SeatCTE WHERE SeatNo < @SeatsPerRow
)
INSERT INTO dbo.Seat (CinemaID, HallNumber, RowNo, SeatNo, SeatType)
SELECT 
    @CinemaID,
    @HallNumber,
    r.RowNo,
    s.SeatNo,
    CASE WHEN r.RowNo <= 2 THEN N'VIP' ELSE N'Normal' END
FROM RowCTE r
CROSS JOIN SeatCTE s
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.Seat x
    WHERE x.CinemaID = @CinemaID
      AND x.HallNumber = @HallNumber
      AND x.RowNo = r.RowNo
      AND x.SeatNo = s.SeatNo
)
OPTION (MAXRECURSION 0);

INSERT INTO dbo.Ticket(QRCode, Username, CinemaID, HallNumber, ShowDate, StartTime, RowNo, SeatNo, PaymentID, TicketStatus)
VALUES
(N'QR-2-1-20270601-1800-R1S1', N'user01',     2, 1, '2027-06-01', '18:00:00', 1, 1, 3,    N'Paid'),
(N'QR-2-1-20270601-1800-R1S2', N'user01',     2, 1, '2027-06-01', '18:00:00', 1, 2, NULL, N'Reserved'),
(N'QR-2-1-20270601-1800-R1S4', N'operator01', 2, 1, '2027-06-01', '18:00:00', 1, 4, 2,    N'Pending'),
(N'QR-2-1-20270601-1800-R2S10',N'admin01',    2, 1, '2027-06-01', '18:00:00', 2,10, 1,    N'Failed'),
(N'QR-2-1-20270601-1800-R5S1', N'cashier01',  2, 1, '2027-06-01', '18:00:00', 5, 1, 3,    N'Paid'),
(N'QR-2-1-20270601-1800-R5S3', N'user01',     2, 1, '2027-06-01', '18:00:00', 5, 3, NULL, N'Reserved');

-- Verify seats for Cinema 1, Hall 2
SELECT *
FROM dbo.Seat
WHERE CinemaID = 1
  AND HallNumber = 2
ORDER BY RowNo, SeatNo;

GO

-- Final verification: these should all return data without foreign-key errors.
SELECT CinemaID, CinemaName FROM dbo.Cinema ORDER BY CinemaID;
SELECT CinemaID, HallNumber, Capacity FROM dbo.Hall ORDER BY CinemaID, HallNumber;
SELECT COUNT(*) AS SeatCount FROM dbo.Seat;
SELECT CinemaID, HallNumber, ShowDate, StartTime, FilmID FROM dbo.[Session] ORDER BY ShowDate, StartTime;
SELECT Username, Role FROM dbo.[User] ORDER BY Username;
SELECT COUNT(*) AS TicketCount FROM dbo.Ticket;
GO
