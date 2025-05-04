SELECT FirstName, LastName
FROM user 
WHERE UserID NOT IN(
    SELECT DISTINCT UserID FROM reservation
);

SELECT DISTINCT u.FirstName, u.LastName
FROM 
    user u
JOIN 
    reservation r ON u.UserID = r.UserID
WHERE
    r.ReservationStatus = 'تایید شده'


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

SELECT reservation

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

SELECT 
    c.CityName,
    COUNT(t.TicketID) AS TicketCount
FROM
    city c
JOIN
    ticket t ON c.CityID = t.Origin
JOIN
    reservation r ON t.TicketID = r.TicketID
WHERE
    r.ReservationStatus = 'تایید شده' AND t.Origin = 1
GROUP BY 
    c.CityName
ORDER BY 
    TicketCount DESC;



