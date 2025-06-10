from fastapi import APIRouter, Depends, HTTPException, status
import mysql.connector
from typing import List

from app.database import get_db_connection
from app.dependencies import get_current_user
from app.schemas import UserProfileUpdate, UserResponse, ReservationResponse, UserBookingDetailsResponse

router = APIRouter(prefix="/users", tags=["User Profile"])

@router.get("/me", response_model=UserResponse)
def read_users_me(current_user: dict = Depends(get_current_user)):
    return current_user

#(API 3) Update profile of the current logged-in user
@router.put("/me")
def update_user_profile(profile: UserProfileUpdate, current_user: dict = Depends(get_current_user),
                        db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):

    # Get a dictionary of provided fields, excluding None values
    update_data = profile.dict(exclude_unset=True)
    if not update_data:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No update data provided")

    set_clauses = []
    values = []

    cursor = db.cursor(dictionary=True)

    try:
        # Check if the user wants to update their city
        if "City" in update_data:
            city_name = update_data.pop("City")  # Remove City from dict to handle it separately

            # Find the CityID from the database
            cursor.execute("SELECT CityID FROM City WHERE CityName = %s", (city_name,))
            city_record = cursor.fetchone()
            cursor.fetchall()
            if not city_record:
                raise HTTPException(status_code=400, detail=f"City '{city_name}' not found.")

            # Add CityID to the update query
            set_clauses.append("CityID = %s")
            values.append(city_record['CityID'])

        # Prepare other fields for the update query
        for key, value in update_data.items():
            # Ensure keys match the database column names (e.g., FirstName, LastName)
            set_clauses.append(f"{key} = %s")
            values.append(value)

        # If after processing there's nothing to update, return
        if not set_clauses:
            return {"message": "No valid fields to update."}

        # Append the UserID for the WHERE clause
        values.append(current_user['UserID'])

        # Build and execute the final UPDATE query
        query = f"UPDATE User SET {', '.join(set_clauses)} WHERE UserID = %s"

        cursor.execute(query, tuple(values))
        db.commit()

    except mysql.connector.Error as err:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {err}")
    finally:
        cursor.close()

    return {"message": "Profile updated successfully."}

#(API 11) Get list of bookings for the current user
@router.get("/me/bookings", response_model=List[UserBookingDetailsResponse])
def get_user_bookings(current_user: dict = Depends(get_current_user),
                      db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):

    query = """
        SELECT
            r.ReservationID,
            r.ReservationStatus,
            r.ReservationTime,
            c1.CityName AS Origin,
            c2.CityName AS Destination,
            CONCAT(t.DepartureDate, ' ', t.DepartureTime) AS DepartureDateTime,
            t.Price,
            tc.CompanyName
        FROM Reservation r
        JOIN Ticket t ON r.TicketID = t.TicketID
        JOIN City c1 ON t.Origin = c1.CityID
        JOIN City c2 ON t.Destination = c2.CityID
        JOIN TransportCompany tc ON t.TransportCompanyID = tc.TransportCompanyID
        WHERE r.UserID = %s
        ORDER BY r.ReservationTime DESC
    """
    cursor = db.cursor(dictionary=True)
    cursor.execute(query, (current_user['UserID'],))
    results = cursor.fetchall()
    cursor.close()
    bookings = []
    for row in results:
        booking_data = {
            "ReservationID": row['ReservationID'],
            "ReservationStatus": row['ReservationStatus'],
            "ReservationTime": row['ReservationTime'],
            "TicketDetails": {
                "Origin": row['Origin'],
                "Destination": row['Destination'],
                "DepartureDateTime": row['DepartureDateTime'],
                "Price": row['Price'],
                "CompanyName": row['CompanyName'],
            }
        }
        bookings.append(booking_data)

    return bookings