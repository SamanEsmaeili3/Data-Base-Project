from fastapi import APIRouter, Depends, HTTPException, status
import mysql.connector
from typing import List

from app.database import get_db_connection
from app.dependencies import get_current_admin_user
from app.schemas import AdminReservationUpdate, ReportResponse, CancelledTicketReportResponse, PaymentResponse

router = APIRouter(prefix="/admin", tags=["Admin Management"], dependencies=[Depends(get_current_admin_user)])

#(API 10,14) Get list of all submitted reports
@router.get("/reports", response_model=List[ReportResponse])
def get_all_reports(db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor(dictionary=True)
    try:
        query = """
           SELECT
                r.ReportID,
                u.FirstName,
                u.LastName,
                u.Email,
                c1.CityName AS OriginCity,
                c2.CityName AS DestinationCity,
                tc.CompanyName,
                rsb.SubjectName AS ReportSubject,
                r.ReportText,
                r.ReportStatus
            FROM Reports r
            JOIN User u ON r.ReportingUserID = u.UserID
            LEFT JOIN Reservation rs ON r.ReservationID = rs.ReservationID
            LEFT JOIN Ticket t ON rs.TicketID = t.TicketID
            LEFT JOIN City c1 ON t.Origin = c1.CityID
            LEFT JOIN City c2 ON t.Destination = c2.CityID
            LEFT JOIN TransportCompany tc ON t.TransportCompanyID = tc.TransportCompanyID
            LEFT JOIN ReportSubject rsb ON r.ReportSubject = rsb.ReportSubjectID
            ORDER BY r.ReportID DESC
        """
        cursor.execute(query)
        reports = cursor.fetchall()
        return reports

    except mysql.connector.Error as e:
        print(f"DB error in get_all_reports: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch reports.")
    finally:
        cursor.close()

#(API 10 & 14) Admin: Manually update the status of any reservation
@router.put("/reservations/{reservation_id}")
def update_reservation_status(reservation_id: int, update: AdminReservationUpdate, db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor()
    cursor.execute("UPDATE Reservation SET ReservationStatus = %s WHERE ReservationID = %s", (update.NewStatus, reservation_id))
    if cursor.rowcount == 0:
        cursor.close()
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reservation not found")
    db.commit()
    cursor.close()
    return {"message": f"Reservation {reservation_id} status updated to '{update.NewStatus}'."}

@router.get("/cancellReports",response_model=List[CancelledTicketReportResponse])
def get_all_cancelled_tickets(db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor(dictionary=True)
    try:
        query = """SELECT 
                t.TicketID,
                c1.CityName AS Origin,
                c2.CityName AS Destination,
                t.DepartureDate,
                t.DepartureTime,
                t.ArrivalDate,
                t.ArrivalTime,
                t.Price,
                tc.CompanyName
            FROM Ticket t
            JOIN City c1 ON t.Origin = c1.CityID
            JOIN City c2 ON t.Destination = c2.CityID
            JOIN TransportCompany tc ON t.TransportCompanyID = tc.TransportCompanyID
            JOIN Reservation r ON t.TicketID = r.TicketID
            WHERE r.ReservationStatus = 'Cancelled'"""
        cursor.execute(query)
        cancelled_ticket_reports = cursor.fetchall()
        for t in cancelled_ticket_reports:
            t["DepartureDate"] = str(t["DepartureDate"])
            t["DepartureTime"] = str(t["DepartureTime"])
            t["ArrivalDate"] = str(t["ArrivalDate"])
            t["ArrivalTime"] = str(t["ArrivalTime"])
        return cancelled_ticket_reports

    except mysql.connector.Error as e:
        print(f"DB error in get_all_reports: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch cancelled ticket reports.")
    finally:
        cursor.close()

@router.get("/paymentReports", response_model=List[PaymentResponse])
def get_payment_report(db:mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor(dictionary=True)
    try:
        query ="""SELECT
        u.FirstName,
        u.LastName,
        c1.CityName AS Origin,
        c2.CityName AS Destination,
        t.DepartureDate,
        t.DepartureTime,
        t.ArrivalDate,
        t.ArrivalTime,
        tc.CompanyName,
        t.Price,
        p.PaymentTime,
        p.PaymentMethod
    FROM payment p
    JOIN reservation r ON p.ReservationID = r.ReservationID
    JOIN ticket t ON r.ReservationID = t.TicketID
    JOIN user u ON r.UserID = u.UserID
    JOIN City c1 ON t.Origin = c1.CityID
    JOIN City c2 ON t.Destination = c2.CityID
    JOIN TransportCompany tc ON t.TransportCompanyID = tc.TransportCompanyID
    WHERE p.PaymentStatus = 'Successful'"""
        cursor.execute(query)
        reports = cursor.fetchall()
        for t in reports:
            t["DepartureDate"] = str(t["DepartureDate"])
            t["DepartureTime"] = str(t["DepartureTime"])
            t["ArrivalDate"] = str(t["ArrivalDate"])
            t["ArrivalTime"] = str(t["ArrivalTime"])
        return reports
    except mysql.connector.Error as e:
        print(f"DB error in get_all_reports: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch cancelled ticket reports.")
    finally:
        cursor.close()
