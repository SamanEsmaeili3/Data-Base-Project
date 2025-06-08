from fastapi import APIRouter, Depends, HTTPException, status
import mysql.connector
from typing import List

from app.database import get_db_connection
from app.dependencies import get_current_user
from app.schemas import UserProfileUpdate, UserResponse, ReservationResponse

router = APIRouter(prefix="/users", tags=["User Profile"])

#(API 3) Update profile of the current logged-in user
@router.put("/me")
def update_user_profile(profile: UserProfileUpdate, current_user: dict = Depends(get_current_user), db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    update_fields = {k: v for k, v in profile.dict().items() if v is not None}
    if not update_fields:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No update data provided")
        
    set_clause = ", ".join([f"{key} = %s" for key in update_fields.keys()])
    values = list(update_fields.values())
    values.append(current_user['UserID'])
    
    query = f"UPDATE User SET {set_clause} WHERE UserID = %s"
    
    cursor = db.cursor()
    cursor.execute(query, tuple(values))
    db.commit()
    cursor.close()
    
    return {"message": "Profile updated successfully."}

#(API 11) Get list of bookings for the current user
@router.get("/me/bookings", response_model= List[ReservationResponse])
def get_user_bookings(current_user: dict = Depends(get_current_user), 
                      db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor(dictionary=True)
    query = "SELECT * FROM Reservation WHERE UserID = %s ORDER BY ReservationTime DESC"
    cursor.execute(query, (current_user['UserID'],))
    bookings = cursor.fetchall()
    cursor.close()
    return bookings