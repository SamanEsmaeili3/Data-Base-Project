from elasticsearch import Elasticsearch
from fastapi import APIRouter, Depends, HTTPException, status
import mysql.connector
from typing import List
import json
from datetime import datetime, timedelta
from app.elastic_utils import sync_ticket_in_es


from app.database import get_db_connection, redis_client, get_es_client
from app.dependencies import get_current_user
from app.schemas import (CitySchema, TicketSearchResponse, TicketDetailsResponse, ReservationCreate, PaymentRequest,
                         ReportCreate, ReservationResponse, AdvancedTicketSearchResponse)

router = APIRouter(prefix="/tickets", tags=["Tickets & Reservations"])

#(API 4) Get list of all cities
@router.get("/cities", response_model=List[CitySchema])
def get_cities(db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT CityID, CityName FROM City")
    cities = cursor.fetchall()
    cursor.close()
    return cities

# (API 5) Search for available tickets - UPDATED FOR ELASTICSEARCH
@router.get("/search", response_model=List[TicketSearchResponse])
def search_tickets(origin_name: str, destination_name: str, date: str,
                   es: Elasticsearch = Depends(get_es_client)):
    query = {
        "bool": {
            "must": [
                {"term": {"Origin": origin_name}},
                {"term": {"Destination": destination_name}},
                # Search for all ticket in given date
                {"range": {
                    "DepartureDateTime": {
                        "gte": f"{date}T00:00:00",
                        "lte": f"{date}T23:59:59"
                    }
                }}
            ],
            "filter": [
                {"range": {"RemainingCapacity": {"gt": 0}}}
            ]
        }
    }
    try:
        response = es.search(index="tickets", query=query, size=100)
        tickets = [hit['_source'] for hit in response['hits']['hits']]
        # convert date format to API response model
        for ticket in tickets:
            ticket['DepartureDateTime'] = ticket['DepartureDateTime'].replace('T', ' ')
            ticket['ArrivalDateTime'] = ticket['ArrivalDateTime'].replace('T', ' ')
        return tickets
    except Exception as e:
        print(f"Elasticsearch search error: {e}")
        raise HTTPException(status_code=500, detail="Error searching for tickets.")


# Advanced search for available tickets - UPDATED FOR ELASTICSEARCH
@router.get("/search/advanced", response_model=List[AdvancedTicketSearchResponse])
def search_tickets_advanced(
        origin_city: str,
        destination_city: str,
        date: str,
        vehicle_type: str,
        es: Elasticsearch = Depends(get_es_client)
):
    valid_vehicles = ['airplane', 'bus', 'train']
    if vehicle_type.lower() not in valid_vehicles:
        raise HTTPException(status_code=400, detail="Invalid vehicle_type.")

    query = {
        "bool": {
            "must": [
                {"term": {"Origin": origin_city}},
                {"term": {"Destination": destination_city}},
                {"term": {"VehicleType": vehicle_type.lower()}},
                {"range": {
                    "DepartureDateTime": {
                        "gte": f"{date}T00:00:00",
                        "lte": f"{date}T23:59:59"
                    }
                }}
            ],
            "filter": [
                {"range": {"RemainingCapacity": {"gt": 0}}}
            ]
        }
    }
    try:
        response = es.search(index="tickets", query=query, size=100)
        tickets = [hit['_source'] for hit in response['hits']['hits']]
        for ticket in tickets:
            ticket['DepartureDateTime'] = ticket['DepartureDateTime'].replace('T', ' ')
            ticket['ArrivalDateTime'] = ticket['ArrivalDateTime'].replace('T', ' ')
        return tickets
    except Exception as e:
        print(f"Elasticsearch advanced search error: {e}")
        raise HTTPException(status_code=500, detail="Error searching for tickets.")

#(API 6) Get detailed information for a single ticket
@router.get("/tickets/{ticket_id}", response_model=TicketDetailsResponse)
def get_ticket_details(ticket_id: int,
                       db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor(dictionary=True)
    try:
        #check redis first
        cash_key = f"ticketDetail{ticket_id}"
        if cash_data := redis_client.get(cash_key):
            return json.loads(cash_data)

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
        #add to redis
        redis_client.set(cash_key, json.dumps(ticket), ex=600)
        return ticket
    except mysql.connector.Error as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail=f"Database transaction failed: {e}")
    finally:
        cursor.close()


#(API 7) Reserve a ticket for the current user.
@router.post("/reserve", response_model=ReservationResponse)
def reserve_ticket(reservation: ReservationCreate, current_user: dict = Depends(get_current_user),
                   db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor(dictionary=True)
    try:
        # FIX: Removed db.start_transaction(). The transaction starts implicitly.
        # qury been edited for ElasticSearch Synchronization
        cursor.execute(
            "SELECT Origin, Destination, DepartureDate, RemainingCapacity FROM Ticket WHERE TicketID = %s AND RemainingCapacity > 0 FOR UPDATE",
            (reservation.TicketID,))
        ticket = cursor.fetchone()
        #add for elasticSearch synchronization
        new_capacity = ticket['RemainingCapacity'] - 1

        if not ticket:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket is not available or sold out")

        cursor.execute("UPDATE Ticket SET RemainingCapacity = %s WHERE TicketID = %s",
                       (new_capacity,reservation.TicketID,))


        expiry_time = datetime.utcnow() + timedelta(minutes=10)
        insert_query = "INSERT INTO Reservation (UserID, TicketID, ReservationStatus, ReservationTime, ReservationExpiryTime) VALUES (%s, %s, %s, %s, %s)"
        cursor.execute(insert_query, (
        current_user['UserID'], reservation.TicketID, "Reserved", datetime.utcnow(), expiry_time))
        reservation_id = cursor.lastrowid
        db.commit()

        # --- ELASTICSEARCH SYNC ---
        sync_ticket_in_es(ticket_id=reservation.TicketID, doc_to_update={"RemainingCapacity": new_capacity})

        # --- CACHE INVALIDATION (update redis cache)---
        cache_key = f"searchTickets:{ticket['Origin']}:{ticket['Destination']}:{ticket['DepartureDate']}"
        cash_key2 = f"ticketDetail{reservation.TicketID}"
        if cach_data := redis_client.get(cash_key2):
            ticketDetail = json.loads(cach_data)
            ticketDetail['RemainingCapacity'] -= 1
            redis_client.delete(cash_key2)
            redis_client.set(cash_key2, json.dumps(ticketDetail), ex=600)

        if cashed_result := redis_client.get(cache_key):
            redis_ticket_list = json.loads(cashed_result)
            for t in redis_ticket_list:
                if t['TicketID'] == reservation.TicketID:
                    if t['RemainingCapacity'] > 0:
                        t['RemainingCapacity'] -= 1
                        redis_client.delete(cache_key)
                        redis_client.set(cache_key, json.dumps(redis_ticket_list), ex=600)
                        break

        #--------------------------

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
            SELECT t.`TicketID`, t.`Origin`, t.`Destination`, t.`DepartureDate`, t.`Price`, t.`RemainingCapacity`
            FROM `Reservation` r JOIN `Ticket` t ON r.TicketID = t.TicketID
            WHERE r.`ReservationID` = %s AND r.`UserID` = %s AND r.`ReservationStatus` = %s
        """
        cursor.execute(query, (reservation_id, current_user['UserID'], 'Paid'))

        reservation_info = cursor.fetchone()
        cursor.fetchall()

        #add for elasticSearch synchronization
        new_capacity = reservation_info['RemainingCapacity'] + 1

        if not reservation_info:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Confirmed reservation not found")

        cursor.execute("UPDATE Reservation SET ReservationStatus = 'Cancelled' WHERE ReservationID = %s",
                       (reservation_id,))
        cursor.execute("UPDATE Ticket SET RemainingCapacity = %s WHERE TicketID = %s",
                       (new_capacity,reservation_info['TicketID'],))
        db.commit()

        # --- ELASTICSEARCH SYNC ---
        sync_ticket_in_es(ticket_id=reservation_info['TicketID'], doc_to_update={"RemainingCapacity": new_capacity})

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