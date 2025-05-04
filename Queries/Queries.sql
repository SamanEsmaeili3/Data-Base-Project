SELECT FirstName, LastName
FROM user 
WHERE UserID NOT IN(
    SELECT DISTINCT UserID FROM reservation
);

SELECT DISTINCT u.FirstName, u.LastName
FROM user u
JOIN reservation r ON u.UserID = r.UserID
JOIN payment p ON r.ReservationID = p.ReservationID
WHERE p.PaymentStatus = 'موفق';

