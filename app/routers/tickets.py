from fastapi import APIRouter, Depends, HTTPException, status
import mysql.connector
from typing import List
import json
from datetime import datetime, timedelta

from app.database import get_db_connection, redis_client
from app.dependencies import get_current_user
from app.schemas import CitySchema, TicketSearchResponse, TicketDetailsResponse, ReservationCreate, PaymentRequest, ReportCreate, ReservationResponse

router = APIRouter(prefix="/tickets", tags=["Tickets & Reservations"])

#(API 4) Get list of all cities
@router.get("/cities", response_model=List[CitySchema])
def get_cities(db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT CityID, CityName FROM City")
    cities = cursor.fetchall()
    cursor.close()
    return cities

#(API 5) Search for available tickets
@router.get("/search", response_model=TicketSearchResponse)
def search_tickets(origin_id: int, destination_id: int, date: str, 
                   db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cache_key = f"search:{origin_id}:{destination_id}:{date}"
    if cashed_result := redis_client.get(cache_key):
        return json.loads(cashed_result)
    query = """
        SELECT t.TicketID, c1.CityName AS Origin, c2.CityName AS Destination,
               CONCAT(t.DepartureDate, ' ', t.DepartureTime) as DepartureDateTime,
               CONCAT(t.ArrivalDate, ' ', t.ArrivalTime) as ArrivalDateTime,
               t.Price, t.RemainingCapacity, tc.CompanyName
        FROM Ticket t
        JOIN City c1 ON t.Origin = c1.CityID
        JOIN City c2 ON t.Destination = c2.CityID
        JOIN TransportCompany tc ON t.TransportCompanyID = tc.CompanyID
        WHERE t.Origin = %s AND t.Destination = %s AND t.DepartureDate = %s AND t.RemainingCapacity > 0
    """
    cursor = db.cursor(dictionary=True)
    cursor.execute(query, (origin_id, destination_id, date))
    tickets = cursor.fetchall()
    cursor.close()
    redis_client.set(cache_key, json.dumps(tickets), ex=60)
    return tickets
    
#(API 6) Get detailed information for a single ticket
@router.get("/tickets/{ticket_id}", response_model=TicketDetailsResponse)
def get_ticket_details(ticket_id: int, 
                       db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor(dictionary=True)
    query = """SELECT TicketID, Origin, Destination, DepartureDate, DepartureTime, Price, RemainingCapacity FROM Ticket WHERE TicketID = %s"""
    cursor.execute(query, (ticket_id,))
    ticket = cursor.fetchone()
    
    if not ticket:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket not found")
    
    features = {}
    cursor.execute("SELECT * FROM AirplaneTicket WHERE TicketID = %s", (ticket_id,))
    if features_db := cursor.fetchone(): features = features_db
    elif cursor.execute("SELECT * FROM BusTicket WHERE TicketID = %s", (ticket_id,)) and (features_db := cursor.fetchone()): features = features_db
    elif cursor.execute("SELECT * FROM TrainTicket WHERE TicketID = %s", (ticket_id,)) and (features_db := cursor.fetchone()): features = features_db

    ticket['Features'] = features
    cursor.close()
    return ticket

#(API 7) Reserve a ticket for the current user.
@router.post("/reserve", response_model=ReservationResponse)
def reserve_ticket(reservation: ReservationCreate, current_user: dict = Depends(get_current_user), db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):

    cursor = db.cursor(dictionary=True)
    try:
        db.start_transaction()
        cursor.execute("SELECT RemainingCapacity FROM Ticket WHERE TicketID = %s AND RemainingCapacity > 0 FOR UPDATE", (reservation.TicketID,))
        if not cursor.fetchone():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket is not available or sold out")

        cursor.execute("UPDATE Ticket SET RemainingCapacity = RemainingCapacity - 1 WHERE TicketID = %s", (reservation.TicketID,))

        expiry_time = datetime.utcnow() + timedelta(minutes=10)
        insert_query = "INSERT INTO Reservation (UserID, TicketID, ReservationStatus, ReservationTime, ReservationExpiryTime) VALUES (%s, %s, %s, %s, %s)"
        cursor.execute(insert_query, (current_user['UserID'], reservation.TicketID, "Reserved", datetime.utcnow(), expiry_time))
        reservation_id = cursor.lastrowid
        db.commit()

        cursor.execute("SELECT * FROM Reservation WHERE ReservationID = %s", (reservation_id,))
        new_reservation = cursor.fetchone()
        return new_reservation
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Database transaction failed: {e}")
    finally:
        cursor.close()

#(API 8) Pay for a reserved ticket
@router.post("/pay")
def pay_for_ticket(payment: PaymentRequest, current_user: dict = Depends(get_current_user), db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor()
    try:
        db.start_transaction()
        query = "SELECT ReservationID FROM Reservation WHERE ReservationID = %s AND UserID = %s AND ReservationStatus = 'در انتظار پرداخت' AND ReservationExpiryTime > NOW()"
        cursor.execute(query, (payment.ReservationID, current_user['UserID']))
        if not cursor.fetchone():
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Reservation is invalid, expired, or does not exist")

        cursor.execute("UPDATE Reservation SET ReservationStatus = 'Paid' WHERE ReservationID = %s", (payment.ReservationID,))
        insert_payment = "INSERT INTO Payment (UserID, ReservationID, PaymentMethod, PaymentStatus, PaymentTime) VALUES (%s, %s, %s, %s, %s)"
        cursor.execute(insert_payment, (current_user['UserID'], payment.ReservationID, payment.PaymentMethod, "Successful", datetime.utcnow()))
        db.commit()
        return {"message": "Payment successful. Ticket confirmed."}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Database error during payment: {e}")
    finally:
        cursor.close()

#(API 9) Check the cancellation penalty for a ticket
@router.get("/{ticket_id}/cancellation-penalty")
def check_cancellation_penalty(ticket_id: int, db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT Price, DepartureDate FROM Ticket WHERE TicketID = %s", (ticket_id,))
    ticket = cursor.fetchone()
    cursor.close()
    if not ticket: raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket not found")
    
    time_to_departure = datetime.strptime(ticket['DepartureDate'], '%Y-%m-%d') - datetime.now()
    penalty_percent = 90 if time_to_departure.days < 1 else (50 if time_to_departure.days < 3 else 20)
    penalty_amount = ticket['Price'] * (penalty_percent / 100)
    return {"penalty_percent": penalty_percent, "penalty_amount": penalty_amount, "refund_amount": ticket['Price'] - penalty_amount}

#(API 12) Cancel a confirmed reservation and get a refund
@router.post("/reservations/{reservation_id}/cancel")
def cancel_ticket(reservation_id: int, current_user: dict = Depends(get_current_user), db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor(dictionary=True)
    try:
        db.start_transaction()
        cursor.execute("SELECT TicketID FROM Reservation WHERE ReservationID = %s AND UserID = %s AND ReservationStatus = 'Paid", (reservation_id, current_user['UserID']))
        reservation = cursor.fetchone()
        if not reservation:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Confirmed reservation not found for this user")
        
        ticket_id = reservation['TicketID']

        penalty_info = check_cancellation_penalty(ticket_id, db=db)
        
        cursor.execute("UPDATE Reservation SET ReservationStatus = 'لغو شده' WHERE ReservationID = %s", (reservation_id,))
        cursor.execute("UPDATE Ticket SET RemainingCapacity = RemainingCapacity + 1 WHERE TicketID = %s", (ticket_id,))
        
        db.commit()
        return {"message": "Ticket cancelled successfully", "refund_amount": penalty_info['refund_amount']}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Database error during cancellation: {e}")
    finally:
        cursor.close()

#(API 13) Report an issue with a ticket
@router.post("/report")
def report_issue(report: ReportCreate, current_user: dict = Depends(get_current_user), db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    query = "INSERT INTO Reports (ReportingUserID, TicketID, ReservationID, ReportSubject, ReportText, ReportStatus) VALUES (%s, %s, %s, %s, %s, %s)"
    data = (current_user['UserID'], report.TicketID, report.ReservationID, report.ReportSubject, report.ReportText, "Pending")
    cursor = db.cursor()
    cursor.execute(query, data)
    db.commit()
    cursor.close()
    return {"message": "Your report has been submitted."}