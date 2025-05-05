--query No: 1
SELECT FirstName, LastName
FROM user 
WHERE UserID NOT IN(
    SELECT DISTINCT UserID FROM reservation
);

--query No: 2
SELECT DISTINCT u.FirstName, u.LastName
FROM 
    user u
JOIN 
    reservation r ON u.UserID = r.UserID
WHERE
    r.ReservationStatus = 'تایید شده'

--query No: 3
SELECT 
    u.UserID,
    u.FirstName,
    u.LastName,
    u.Email,
    YEAR(p.PaymentTime) AS Year,
    MONTH(p.PaymentTime) AS Month,
    SUM(t.Price) AS TotalPayments
FROM 
    User u
JOIN 
    Payment p ON u.UserID = p.UserID
JOIN 
    Reservation r ON p.ReservationID = r.ReservationID
JOIN 
    Ticket t ON r.TicketID = t.TicketID
WHERE 
    r.ReservationStatus = 'تایید شده'
GROUP BY 
    u.UserID, u.FirstName, u.LastName, u.Email, YEAR(p.PaymentTime), MONTH(p.PaymentTime)
ORDER BY 
    u.UserID, Year, Month;

--query No: 4
SELECT
    u.UserID,
    u.FirstName,
    u.LastName,
    c.CityName
FROM
    User u
JOIN
    Reservation r ON u.UserID = r.UserID 
JOIN
    city c ON u.CityID = c.CityID
WHERE
    r.ReservationStatus = 'تایید شده' 
GROUP BY 
    u.FirstName, u.LastName, c.CityName
HAVING
    COUNT(r.ReservationID) = 1;

--query No: 5
SELECT 
    u.FirstName,
    u.LastName,
    u.Email,
    u.PhoneNumber
FROM
    User u
JOIN
    Reservation r ON u.UserID = r.UserID
WHERE
    r.ReservationStatus = (
        SELECT MAX(ReservationStatus) 
        FROM Reservation 
        WHERE UserID = u.UserID 
    )
ORDER BY
    r.`ReservationTime` DESC
LIMIT 1;

--query No: 6
SELECT 
    u.Email,
    u.PhoneNumber,
    SUM(t.Price) AS TotalPayments
FROM 
    User u
JOIN 
    Payment p ON u.UserID = p.UserID
JOIN 
    Reservation r ON p.ReservationID = r.ReservationID
JOIN 
    Ticket t ON r.TicketID = t.TicketID
WHERE 
    p.PaymentStatus = 'موفق'
GROUP BY 
    u.Email, u.PhoneNumber
HAVING 
    SUM(t.Price) > (
        SELECT AVG(user_payments.TotalPayment)
        FROM (
            SELECT SUM(t2.Price) AS TotalPayment
            FROM Payment p2
            JOIN Reservation r2 ON p2.ReservationID = r2.ReservationID
            JOIN Ticket t2 ON r2.TicketID = t2.TicketID
            WHERE p2.PaymentStatus = 'موفق'
            GROUP BY p2.UserID
        ) AS user_payments
    )
ORDER BY 
    TotalPayments DESC;

--query No: 7
SELECT 
    CASE
        WHEN at.TicketID IS NOT NULL THEN 'هواپیما'
        WHEN bt.TicketID IS NOT NULL THEN 'اتوبوس'
        WHEN tt.TicketID IS NOT NULL THEN 'قطار'
        ELSE 'نوع نامشخص'
    END AS VehicleType,
    COUNT(DISTINCT t.TicketID) AS TicketsSold
FROM 
    Ticket t
LEFT JOIN 
    AirplaneTicket at ON t.TicketID = at.TicketID
LEFT JOIN 
    BusTicket bt ON t.TicketID = bt.TicketID
LEFT JOIN 
    TrainTicket tt ON t.TicketID = tt.TicketID
JOIN 
    Reservation r ON t.TicketID = r.TicketID
WHERE 
    r.ReservationStatus = 'تایید شده'
GROUP BY 
    VehicleType
ORDER BY 
    TicketsSold DESC;

--query No: 8
SELECT 
    u.FirstName,
    u.LastName,
    u.Email,
    u.PhoneNumber,
    COUNT(r.`UserID`) AS ReservationCount
FROM
    User u
JOIN
    Reservation r ON u.UserID = r.UserID
WHERE
    r.ReservationStatus = 'تایید شده' AND r.ReservationTime >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY
    u.FirstName, u.LastName, u.Email, u.PhoneNumber
ORDER BY 
    ReservationCount DESC
LIMIT 3;


--query No: 9
SELECT
    c.CityName  AS DestinationCity,
    COUNT(*) AS TicketCount
FROM
    ticket t
JOIN
    city c ON t.Destination = c.CityID
JOIN
    city Origin ON t.Origin = Origin.CityID
JOIN
    reservation r ON t.TicketID = r.TicketID
WHERE
    Origin.CityName = 'تهران' AND r.ReservationStatus = 'تایید شده'
GROUP BY
    c.CityName;

--query No: 10
SELECT DISTINCT
    c.CityName
FROM
    city c
JOIN
    ticket t ON c.CityID = t.Origin
JOIN
    reservation r ON r.TicketID = t.TicketID
WHERE
    r.UserID = (
        SELECT UserID
        FROM user
        ORDER BY RegistrationDate ASC
        LIMIT 1
    )
    AND r.ReservationStatus = 'تایید شده'
GROUP BY
    c.CityName

--query No: 11
SELECT
    u.FirstName,
    u.LastName
FROM
    user u
WHERE
    u.`Role` = 'admin'

--query No: 12
SELECT
    u.FirstName,
    u.LastName,
    COUNT(r.ReservationID) AS ReservationCount
FROM
    user u
JOIN
    reservation r ON u.UserID = r.UserID
WHERE
    r.ReservationStatus = 'تایید شده'
GROUP BY
    u.FirstName, u.LastName
HAVING
    COUNT(r.ReservationID) > 1;

--query No: 13
-- This query is for ONLY Train tickets
SELECT
    u.FirstName,
    u.LastName,
    COUNT(*) AS TicketCount
FROM
    user u
JOIN
    reservation r ON u.UserID = r.UserID
JOIN
    ticket t ON r.TicketID = t.TicketID
JOIN
    trainticket tt ON t.TicketID = tt.TicketID
WHERE
    r.ReservationStatus = 'تایید شده'
GROUP BY
    u.FirstName, u.LastName
HAVING
    COUNT(*) < 3;

-- This query is for ONLY Airplane tickets
SELECT
    u.FirstName,
    u.LastName,
    COUNT(*) AS TicketCount
FROM
    user u
JOIN
    reservation r ON u.UserID = r.UserID
JOIN
    ticket t ON r.TicketID = t.TicketID
JOIN
    airplaneticket tt ON t.TicketID = tt.TicketID
WHERE
    r.ReservationStatus = 'تایید شده'
GROUP BY
    u.FirstName, u.LastName
HAVING
    COUNT(*) < 3;


-- This query is for ONLY bus tickets
SELECT
    u.FirstName,
    u.LastName,
    COUNT(*) AS TicketCount
FROM
    user u
JOIN
    reservation r ON u.UserID = r.UserID
JOIN
    ticket t ON r.TicketID = t.TicketID
JOIN
    busticket tt ON t.TicketID = tt.TicketID
WHERE
    r.ReservationStatus = 'تایید شده'
GROUP BY
    u.FirstName, u.LastName
HAVING
    COUNT(*) < 3;

--query No: 14
SELECT
    u.Email,
    u.PhoneNumber
FROM
    user u
WHERE
        EXISTS (
            SELECT 1
            From reservation r
            JOIN payment p ON r.ReservationID = p.ReservationID
            JOIN ticket t ON r.TicketID = t.TicketID
            JOIN TrainTicket tt ON t.TicketID = tt.TicketID
            WHERE r.UserID = u.UserID AND p.PaymentStatus = 'موفق'
        )
    AND 
        EXISTS (
            SELECT 1
            FROM reservation r
            JOIN payment p ON r.ReservationID = p.ReservationID
            JOIN ticket t ON r.TicketID = t.TicketID
            JOIN AirplaneTicket at ON t.TicketID = at.TicketID
            WHERE r.UserID = u.UserID AND p.PaymentStatus = 'موفق'
        )
    AND
        EXISTS (
            SELECT 1
            FROM reservation r
            JOIN payment p ON r.ReservationID = p.ReservationID
            JOIN ticket t ON r.TicketID = t.TicketID
            JOIN BusTicket bt ON t.TicketID = bt.TicketID
            WHERE r.UserID = u.UserID AND p.PaymentStatus = 'موفق'
        );

--query No: 15
SELECT 
    t.TicketID,
    origin.CityName AS OriginCity,
    dest.CityName AS DestinationCity,
    t.DepartureDate,
    t.DepartureTime,
    t.ArrivalDate,
    t.ArrivalTime,
    t.Price,
    p.PaymentTime
FROM
    payment p
JOIN
    reservation r ON p.ReservationID = r.ReservationID
JOIN
    ticket t ON r.TicketID = t.TicketID
JOIN
    city origin ON t.Origin = origin.CityID
JOIN
    city dest ON t.Destination = dest.CityID
WHERE
    DATE(p.`PaymentTime`) = CURDATE() AND p.PaymentStatus = 'موفق'
ORDER BY
    p.PaymentTime DESC;

--query No: 16
SELECT 
    t.TicketID,
    origin.CityName AS OriginCity,
    dest.CityName AS DestinationCity,
    t.DepartureDate,
    t.DepartureTime,
    t.ArrivalDate,
    t.ArrivalTime,
    t.Price,
    sales.TotalSales
FROM 
    Ticket t
JOIN 
    City origin ON t.Origin = origin.CityID
JOIN 
    City dest ON t.Destination = dest.CityID
JOIN (
    SELECT 
        r.TicketID, COUNT(*) AS TotalSales
    FROM 
        Reservation r
    JOIN 
        Payment p ON r.ReservationID = p.ReservationID
    WHERE 
        p.PaymentStatus = 'موفق'
    GROUP BY 
        r.TicketID
    ORDER BY 
        TotalSales DESC
    LIMIT 2
) AS sales ON t.TicketID = sales.TicketID
ORDER BY 
    sales.TotalSales ASC
LIMIT 1;

--query No: 17
SELECT 
    u.FirstName,
    u.LastName,
    COUNT(*) AS CancelCount,
    ROUND(
        COUNT(*) * 100.0 / (
            SELECT COUNT(*) 
            FROM reservationIssue ri2
            WHERE ri2.IssueCategory = 2
        ), 2
    ) AS CancelPercentage
FROM 
    ReservationIssue ri
JOIN 
    User u ON ri.HandledBy = u.UserID
WHERE 
    ri.IssueCategory = 2 AND u.Role = 'admin'
GROUP BY 
    u.UserID, u.FirstName, u.LastName
ORDER BY 
    CancelCount DESC
LIMIT 1;

--query No: 18
UPDATE 
    User
SET 
    LastName = 'ردینگتون'
WHERE 
    UserID = (
        SELECT 
            UserID
        FROM 
            Reservation
        WHERE 
            ReservationStatus = 'لغو شده'
        GROUP BY 
            UserID
        ORDER BY 
            COUNT(*) DESC
    LIMIT 1
);

--query No: 19
DELETE FROM Reservation
WHERE UserID = (
    SELECT 
        UserID 
    FROM 
        User 
    WHERE 
        LastName = 'ردینگتون'
)
AND ReservationStatus = 'لغو شده';
--delete records from all tables that are related to the deleted reservation
-- DELETE FROM PaymentHistory
-- WHERE PaymentID IN (
--     SELECT PaymentID
--     FROM Payment
--     WHERE ReservationID IN (
--         SELECT ReservationID
--         FROM Reservation
--         WHERE UserID = (SELECT UserID FROM User WHERE LastName = 'ردینگتون')
--         AND ReservationStatus = 'لغو شده'
--     )
-- );
-- DELETE FROM Payment
-- WHERE ReservationID IN (
--     SELECT ReservationID
--     FROM Reservation
--     WHERE UserID = (SELECT UserID FROM User WHERE LastName = 'ردینگتون')
--     AND ReservationStatus = 'لغو شده'
-- );
-- DELETE FROM Reports
-- WHERE ReservationID IN (
--     SELECT ReservationID
--     FROM Reservation
--     WHERE UserID = (SELECT UserID FROM User WHERE LastName = 'ردینگتون')
--     AND ReservationStatus = 'لغو شده'
-- );
-- DELETE FROM ReservationIssue
-- WHERE ReservationID IN (
--     SELECT ReservationID
--     FROM Reservation
--     WHERE UserID = (SELECT UserID FROM User WHERE LastName = 'ردینگتون')
--     AND ReservationStatus = 'لغو شده'
-- );
-- DELETE FROM Reservation
-- WHERE UserID = (SELECT UserID FROM User WHERE LastName = 'ردینگتون')
-- AND ReservationStatus = 'لغو شده';

--query No: 20
DELETE FROM PaymentHistory
WHERE PaymentID IN (
  SELECT PaymentID FROM Payment
  WHERE ReservationID IN (
    SELECT ReservationID FROM Reservation
    WHERE ReservationStatus = 'لغو شده'
  )
);
DELETE FROM Payment
WHERE ReservationID IN (
  SELECT ReservationID FROM Reservation
  WHERE ReservationStatus = 'لغو شده'
);
DELETE FROM Reports
WHERE ReservationID IN (
  SELECT ReservationID FROM Reservation
  WHERE ReservationStatus = 'لغو شده'
);
DELETE FROM ReservationIssue
WHERE ReservationID IN (
  SELECT ReservationID FROM Reservation
  WHERE ReservationStatus = 'لغو شده'
);
UPDATE Ticket
SET RemainingCapacity = RemainingCapacity + 1
WHERE TicketID IN (
  SELECT TicketID
  FROM Reservation
  WHERE ReservationStatus = 'لغو شده'
);
DELETE FROM Reservation
WHERE ReservationStatus = 'لغو شده';

--query No: 21
UPDATE 
    Ticket t
JOIN 
    AirplaneTicket at ON t.TicketID = at.TicketID
JOIN 
    Reservation r ON t.TicketID = r.TicketID
SET 
    t.Price = t.Price * 0.9
WHERE 
    at.CompanyName = 'ماهان'
    AND DATE(r.ReservationTime) = CURDATE() - INTERVAL 1 DAY;

--query No: 22
SELECT ReportSubject, COUNT(*) AS ReportCount
FROM Reports
WHERE TicketID = (
    SELECT TicketID
    FROM Reports
    GROUP BY TicketID
    ORDER BY COUNT(*) DESC
    LIMIT 1
)
GROUP BY ReportSubject;

