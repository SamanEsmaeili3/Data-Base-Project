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
@router.get("/search", response_model=List[TicketSearchResponse])
def search_tickets(origin_name: str, destination_name: str, date: str,
                   db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute("SELECT CityID FROM City WHERE CityName = %s", (origin_name,))
        city_record = cursor.fetchone()
        cursor.fetchall()

        # if city not found return error
        if not city_record:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"City '{origin_name}' not found. Please use a valid city name."
            )
        origin_id = city_record['CityID']

        cursor.execute("SELECT CityID FROM City WHERE CityName = %s", (destination_name,))
        city_record = cursor.fetchone()
        cursor.fetchall()

        # if city not found return error
        if not city_record:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"City '{destination_name}' not found. Please use a valid city name."
            )
        destination_id = city_record['CityID']

    except mysql.connector.Error as err:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail= "An error occurred while getting user info."
        )


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
        JOIN TransportCompany tc ON t.TransportCompanyID = tc.TransportCompanyID
        WHERE t.Origin = %s AND t.Destination = %s AND t.DepartureDate = %s AND t.RemainingCapacity > 0
    """
    cursor = db.cursor(dictionary=True)
    cursor.execute(query, (origin_id, destination_id, date))
    tickets = cursor.fetchall()
    cursor.close()
    redis_client.set(cache_key, json.dumps(tickets), ex=600)
    return tickets
    
#(API 6) Get detailed information for a single ticket
@router.get("/tickets/{ticket_id}", response_model=TicketDetailsResponse)
def get_ticket_details(ticket_id: int, 
                       db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor(dictionary=True)

    query = """
        SELECT 
            t.TicketID,
            c1.CityName AS Origin,
            c2.CityName AS Destination,
            t.DepartureDate,
            t.DepartureTime,
            t.ArrivalDate,
            t.ArrivalTime,
            t.Price,
            t.RemainingCapacity,
            tc.CompanyName
        FROM Ticket t
        JOIN City c1 ON t.Origin = c1.CityID
        JOIN City c2 ON t.Destination = c2.CityID
        JOIN TransportCompany tc ON t.TransportCompanyID = tc.TransportCompanyID
        WHERE t.TicketID = %s
    """
    cursor.execute(query, (ticket_id,))
    ticket = cursor.fetchone()

    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")

    # convert date and time to string to prevent from ValidationError
    ticket["DepartureDate"] = str(ticket["DepartureDate"])
    ticket["DepartureTime"] = str(ticket["DepartureTime"])
    ticket["ArrivalDate"] = str(ticket["ArrivalDate"])
    ticket["ArrivalTime"] = str(ticket["ArrivalTime"])

    # check features
    vehicle_features = {}

    cursor.execute("SELECT * FROM AirplaneTicket WHERE TicketID = %s", (ticket_id,))
    result = cursor.fetchone()
    if result:
        vehicle_features["Type"] = "Airplane"
        vehicle_features.update(result)
    else:
        cursor.execute("SELECT * FROM BusTicket WHERE TicketID = %s", (ticket_id,))
        result = cursor.fetchone()
        if result:
            vehicle_features["Type"] = "Bus"
            vehicle_features.update(result)
        else:
            cursor.execute("SELECT * FROM TrainTicket WHERE TicketID = %s", (ticket_id,))
            result = cursor.fetchone()
            if result:
                vehicle_features["Type"] = "Train"
                vehicle_features.update(result)

    # delete duplicate features from Ticket
    vehicle_features.pop("TicketID", None)
    ticket["Features"] = vehicle_features

    cursor.close()
    return ticket

#(API 7) Reserve a ticket for the current user.
@router.post("/reserve", response_model=ReservationResponse)
def reserve_ticket(reservation: ReservationCreate, current_user: dict = Depends(get_current_user),
                   db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor(dictionary=True)
    try:
        # FIX: Removed db.start_transaction(). The transaction starts implicitly.
        cursor.execute(
            "SELECT Origin, Destination, DepartureDate FROM Ticket WHERE TicketID = %s AND RemainingCapacity > 0 FOR UPDATE",
            (reservation.TicketID,))
        ticket = cursor.fetchone()
        if not ticket:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket is not available or sold out")

        cursor.execute("UPDATE Ticket SET RemainingCapacity = RemainingCapacity - 1 WHERE TicketID = %s",
                       (reservation.TicketID,))

        expiry_time = datetime.utcnow() + timedelta(minutes=10)
        insert_query = "INSERT INTO Reservation (UserID, TicketID, ReservationStatus, ReservationTime, ReservationExpiryTime) VALUES (%s, %s, %s, %s, %s)"
        cursor.execute(insert_query, (
        current_user['UserID'], reservation.TicketID, "Reserved", datetime.utcnow(), expiry_time))
        reservation_id = cursor.lastrowid
        db.commit()

        # --- CACHE INVALIDATION (update redis cache)---
        cache_key = f"search:{ticket['Origin']}:{ticket['Destination']}:{ticket['DepartureDate']}"
        if cashed_result := redis_client.get(cache_key):
             redis_ticket_list = json.loads(cashed_result)
        for t in redis_ticket_list:
            if t['TicketID'] == reservation.TicketID:
                if t['RemainingCapacity'] > 0:
                    t['RemainingCapacity'] -= 1
                    redis_client.delete(cache_key)
                    redis_client.set(cache_key, json.dumps(redis_ticket_list), ex=600)
                    break

        # --------------------------

        cursor.execute("SELECT * FROM Reservation WHERE ReservationID = %s", (reservation_id,))
        new_reservation = cursor.fetchone()
        return new_reservation
    except mysql.connector.Error as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail=f"Database transaction failed: {e}")
    finally:
        cursor.close()

#(API 8) Pay for a reserved ticket
@router.post("/pay")
def pay_for_ticket(payment: PaymentRequest, current_user: dict = Depends(get_current_user), db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor()
    try:
        # FIX: Removed db.start_transaction(). The transaction starts implicitly.
        query = "SELECT ReservationID FROM Reservation WHERE ReservationID = %s AND UserID = %s AND ReservationStatus = 'Reserved' AND ReservationExpiryTime > NOW()"
        cursor.execute(query, (payment.ReservationID, current_user['UserID']))
        if not cursor.fetchone():
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Reservation is invalid, expired, or does not exist")

        cursor.execute("UPDATE Reservation SET ReservationStatus = 'Paid' WHERE ReservationID = %s", (payment.ReservationID,))
        insert_payment = "INSERT INTO Payment (UserID, ReservationID, PaymentMethod, PaymentStatus, PaymentTime) VALUES (%s, %s, %s, %s, %s)"
        cursor.execute(insert_payment, (current_user['UserID'], payment.ReservationID, payment.PaymentMethod, "Successful", datetime.utcnow()))
        db.commit()
        return {"message": "Payment successful. Ticket confirmed."}
    except mysql.connector.Error as e:
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
    
    departure_datetime = datetime.combine(ticket['DepartureDate'], datetime.min.time())
    now = datetime.now()
    time_to_departure = departure_datetime - now

    # penalty ratio
    if time_to_departure < timedelta(days=1):
        penalty_percent = 90
    elif time_to_departure < timedelta(days=3):
        penalty_percent = 50
    else:
        penalty_percent = 20

    penalty_amount = ticket['Price'] * (penalty_percent / 100)
    refund_amount = ticket['Price'] - penalty_amount

    return {
        "penalty_percent": penalty_percent,
        "penalty_amount": round(penalty_amount, 2),
        "refund_amount": round(refund_amount, 2)
    }

#(API 12) Cancel a confirmed reservation and get a refund
@router.post("/reservations/{reservation_id}/cancel")
def cancel_ticket(reservation_id: int, current_user: dict = Depends(get_current_user),
                  db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):

    cursor = db.cursor(dictionary=True)
    try:
        query = """
            SELECT t.`TicketID`, t.`Origin`, t.`Destination`, t.`DepartureDate`, t.`Price`
            FROM `Reservation` r JOIN `Ticket` t ON r.TicketID = t.TicketID
            WHERE r.`ReservationID` = %s AND r.`UserID` = %s AND r.`ReservationStatus` = %s
        """
        cursor.execute(query, (reservation_id, current_user['UserID'], 'Paid'))

        reservation_info = cursor.fetchone()
        cursor.fetchall()
        if not reservation_info:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Confirmed reservation not found")

        cursor.execute("UPDATE Reservation SET ReservationStatus = 'Cancelled' WHERE ReservationID = %s",
                       (reservation_id,))
        cursor.execute("UPDATE Ticket SET RemainingCapacity = RemainingCapacity + 1 WHERE TicketID = %s",
                       (reservation_info['TicketID'],))
        db.commit()

        # --- CACHE INVALIDATION ---
        cache_key = f"search:{reservation_info['Origin']}:{reservation_info['Destination']}:{reservation_info['DepartureDate']}"
        redis_client.delete(cache_key)
        # --------------------------

        # Use the dedicated function to ensure consistent logic
        penalty_info = check_cancellation_penalty(reservation_info['TicketID'], db=db)

        return {"message": "Ticket cancelled successfully", "refund_amount": penalty_info['refund_amount']}
    except mysql.connector.Error as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail=f"Database error during cancellation: {e}")
    finally:
        cursor.close()

#(API 13) Report an issue with a ticket
@router.post("/report")
def report_issue(report: ReportCreate, current_user: dict = Depends(get_current_user), db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor()
    cursor.execute("SELECT ReportSubjectID FROM Reportsubject WHERE SubjectName = %s", (report.ReportSubject,))
    r_subject = cursor.fetchone()
    t = r_subject[0]
    cursor.fetchall()
    query = "INSERT INTO Reports (ReportingUserID, ReservationID, ReportSubject, HandledBy, ReportText, ReportStatus) VALUES (%s, %s, %s, %s, %s, %s)"
    data = (current_user['UserID'], report.ReservationID, r_subject[0], None,report.ReportText, "Pending")
    cursor.execute(query, data)
    db.commit()
    cursor.close()
    return {"message": "Your report has been submitted."}