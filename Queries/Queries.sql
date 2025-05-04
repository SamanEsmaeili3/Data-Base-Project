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

