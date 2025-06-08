from fastapi import APIRouter, Depends, HTTPException, status
import mysql.connector
from typing import List

from app.database import get_db_connection
from app.dependencies import get_current_admin_user
from app.schemas import AdminReservationUpdate

router = APIRouter(prefix="/admin", tags=["Admin Management"], dependencies=[Depends(get_current_admin_user)])

#(API 10,14) Get list of all submitted reports
@router.get("/reports")
def get_all_reports(db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT * FROM Report ORDER BY ReportID DESC")
    reports = cursor.fetchall()
    cursor.close()
    return reports

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