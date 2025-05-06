--Proc No: 1
CREATE PROCEDURE GetTicketsByEmailOrPhone(IN identifier VARCHAR(100))
BEGIN
    SELECT 
        c1.CityName AS OriginCity,
        c2.CityName AS DestinationCity,
        T.`DepartureDate`, T.`DepartureTime`,
        T.`ArrivalDate`, T.`ArrivalTime`,
        tc.CompanyName AS TransportCompany,
        T.`Price`
    FROM Ticket T
    JOIN Reservation R ON T.TicketID = R.TicketID
    JOIN User U ON R.UserID = U.UserID
    JOIN city c1 ON t.Origin = c1.CityID
    JOIN city c2 ON t.Destination = c2.CityID
    JOIN transportcompany tc ON tc.`TransportCompanyID` = T.`TransportCompanyID`
    WHERE U.Email = identifier OR U.PhoneNumber = identifier
    ORDER BY R.ReservationTime;
END

--Proc No: 2
CREATE PROCEDURE GetCancelledReservationsForAdmin (
    IN email_or_phone VARCHAR(255)
)
BEGIN
    DECLARE admin_count INT;

    SELECT COUNT(*) INTO admin_count
    FROM User
    WHERE Role = 'admin'
      AND (Email = email_or_phone OR PhoneNumber = email_or_phone);

    IF admin_count > 0 THEN
        SELECT DISTINCT u.`UserID`,u.FirstName, u.LastName
        FROM User u
        JOIN Reservation r ON u.UserID = r.UserID
        WHERE r.ReservationStatus = 'لغو شده';
    ELSE
        SELECT 'شما دسترسی لازم را ندارید.' AS Message;
    END IF;
END

--Proc No: 3
CREATE PROCEDURE GetSoldTicketsByOriginCity (
    IN input_city_name VARCHAR(100)
)
BEGIN
    SELECT 
        t.TicketID,
        c1.CityName AS OriginCity,
        c2.CityName AS DestinationCity,
        t.DepartureDate,
        t.DepartureTime,
        t.Price,
        u.FirstName,
        u.LastName
    FROM Ticket t
    JOIN City c1 ON t.Origin = c1.CityID
    JOIN City c2 ON t.Destination = c2.CityID
    JOIN Reservation r ON t.TicketID = r.TicketID
    JOIN User u ON r.UserID = u.UserID
    WHERE c1.CityName = input_city_name
      AND r.ReservationStatus = 'تایید شده';
END

--Proc No: 4
CREATE PROCEDURE SearchTicketsByVehicleType (
    IN search_term VARCHAR(100)
)
BEGIN
    SELECT 
        t.TicketID,
        c1.CityName AS OriginCity,
        c2.CityName AS DestinationCity,
        u.FirstName,
        u.LastName,
        CASE 
            WHEN at.TicketID IS NOT NULL THEN 'هواپیما'
            WHEN bt.TicketID IS NOT NULL THEN 'اتوبوس'
            WHEN tt.TicketID IS NOT NULL THEN 'قطار'
            ELSE 'نامشخص'
        END AS VehicleType,
        t.DepartureDate,
        t.DepartureTime,
        t.Price
    FROM Ticket t
    JOIN City c1 ON t.Origin = c1.CityID
    JOIN City c2 ON t.Destination = c2.CityID
    JOIN Reservation r ON r.TicketID = t.TicketID
    JOIN User u ON u.UserID = r.UserID
    LEFT JOIN AirplaneTicket at ON t.TicketID = at.TicketID
    LEFT JOIN BusTicket bt ON t.TicketID = bt.TicketID
    LEFT JOIN TrainTicket tt ON t.TicketID = tt.TicketID
    WHERE 
        c1.CityName LIKE CONCAT('%', search_term, '%') OR
        c2.CityName LIKE CONCAT('%', search_term, '%') OR
        u.FirstName LIKE CONCAT('%', search_term, '%') OR
        u.LastName LIKE CONCAT('%', search_term, '%') OR
        (search_term LIKE '%هواپیما%' AND at.TicketID IS NOT NULL) OR
        (search_term LIKE '%اتوبوس%' AND bt.TicketID IS NOT NULL) OR
        (search_term LIKE '%قطار%' AND tt.TicketID IS NOT NULL);
END

--Proc No: 5
CREATE PROCEDURE GetCityMates(IN userIdentifier VARCHAR(100))
BEGIN
    SELECT U2.`FirstName`, U2.`LastName`, U2.`Email`, U2.`PhoneNumber`
    FROM User U1
    JOIN User U2 ON U1.CityID = U2.CityID AND U1.UserID != U2.UserID
    WHERE U1.Email = userIdentifier OR U1.PhoneNumber = userIdentifier;
END

--Proc No: 6
CREATE PROCEDURE GetTopBuyersFromDate (
    IN start_date DATE,
    IN limit_count INT
)
BEGIN
    SELECT 
        u.UserID,
        u.FirstName,
        u.LastName,
        u.Email,
        COUNT(r.ReservationID) AS TotalReservations
    FROM Reservation r
    JOIN User u ON u.UserID = r.UserID
    WHERE r.ReservationStatus = 'تایید شده'
      AND r.ReservationTime >= start_date
    GROUP BY u.UserID, u.FirstName, u.LastName, u.Email
    ORDER BY TotalReservations DESC
    LIMIT limit_count;
END 

--Proc No: 7
CREATE PROCEDURE GetCancelledTicketsByVehicle (
    IN vehicle_type VARCHAR(20)
)
BEGIN
    SELECT 
        DATE(r.ReservationTime) AS CancelDate,
        c1.CityName AS OriginCity,
        c2.CityName AS DestinationCity,
        t.`DepartureDate`, t.`DepartureTime`,
        t.`ArrivalDate`, t.`ArrivalTime`,
        t.`Price`,
        COUNT(*) AS CancelledCount
    FROM Reservation r
    JOIN Ticket t ON r.TicketID = t.TicketID
    JOIN city c1 ON t.Origin = c1.CityID
    JOIN city c2 ON t.Destination = c2.CityID
    LEFT JOIN AirplaneTicket at ON t.TicketID = at.TicketID
    LEFT JOIN BusTicket bt ON t.TicketID = bt.TicketID
    LEFT JOIN TrainTicket tt ON t.TicketID = tt.TicketID
    WHERE r.ReservationStatus = 'لغو شده'
      AND (
          (vehicle_type = 'هواپیما' AND at.TicketID IS NOT NULL) OR
          (vehicle_type = 'اتوبوس' AND bt.TicketID IS NOT NULL) OR
          (vehicle_type = 'قطار' AND tt.TicketID IS NOT NULL)
      )
    GROUP BY CancelDate, OriginCity, DestinationCity, t.`DepartureDate`, t.`DepartureTime`, t.`ArrivalDate`, t.`ArrivalTime`, t.`Price`
    ORDER BY CancelDate;
END

--Proc No: 8
CREATE PROCEDURE GetTopUsersByReportSubject (
    IN input_subject VARCHAR(100)
)
BEGIN
    SELECT 
        u.UserID,
        u.FirstName,
        u.LastName,
        COUNT(r.ReportID) AS ReportCount
    FROM Reports r
    JOIN User u ON r.ReportingUserID = u.UserID
    JOIN ReportSubject rs ON r.`ReportID` = rs.id
    WHERE rs.subject = input_subject
    GROUP BY u.UserID, u.FirstName, u.LastName
    HAVING COUNT(r.ReportID) = (
        SELECT MAX(ReportTotal) FROM (
            SELECT COUNT(*) AS ReportTotal
            FROM Reports r2
            JOIN ReportSubject rs2 ON r2.`ReportSubject` = rs2.id
            WHERE rs2.subject = input_subject
            GROUP BY r2.ReportingUserID
        ) AS counts
    );
END