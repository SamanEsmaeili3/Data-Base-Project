import os
import re
import httpx
from fastapi import Depends, HTTPException, status
import mysql.connector
from fastapi.params import Depends
from jose import JWTError, jwt

from app.database import get_db_connection
from app.Security import ALGORITHM, oauth2_scheme, SECRET_KEY

# ELASTIC_API_KEY = os.getenv("ELASTIC_API_KEY")
# SENDER_EMAIL = os.getenv("SENDER_EMAIL")

#decode jwt and fetch user data from db
def get_current_user(token: str = Depends(oauth2_scheme),
                    db: mysql.connector.connection.MySQLConnection =
                    Depends(get_db_connection)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"}
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception

    except JWTError:
        raise credentials_exception

    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT UserID, Email, FirstName, LastName, PhoneNumber, Role "
                   "FROM User WHERE Email = %s AND AccountStatus = 'active'", (email,))
    user = cursor.fetchone()
    cursor.close()

    if user is None:
        raise credentials_exception
    return user

def get_current_admin_user(current_user: dict = Depends(get_current_user)):
    if current_user.get("Role") != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin access required")
    return current_user

# def is_email(s: str) -> bool:
#     return re.match(r"[^@]+@[^@]+\.[^@]+", s) is not None
#
# async def send_email_otp(to_email: str, otp: str):
#     url = "https://api.elasticemail.com/v2/email/send"
#     payload = {
#         "apikey": ELASTIC_API_KEY,
#         "from": SENDER_EMAIL,
#         "to": to_email,
#         "subject": "Your OTP Code",
#         "bodyText": f"Your OTP code is: {otp}",
#         "isTransactional": True
#     }
#     async with httpx.AsyncClient() as client:
#         response = await client.post(url, data=payload)
#         if response.status_code != 200:
#             raise HTTPException(status_code=500, detail="Failed to send email OTP")