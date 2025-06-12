import json
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
import mysql.connector
import random
import string

from app.database import get_db_connection, redis_client
from app.schemas import UserCreate, Token, OTPRequest, OTPLoginRequest
from app.Security import get_password_hash, generate_access_token, ACCESS_TOKEN_EXPIRE_MINUTES

router = APIRouter(prefix="/auth", tags=["Authentication"])

#(API 2) sign in with email or phone number
@router.post("/signup", response_model=Token, status_code=status.HTTP_201_CREATED)
def signup(user: UserCreate, db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor(dictionary=True)

    try:
        # Check is user already exist or not
        cursor.execute("SELECT UserID FROM User WHERE Email = %s OR PhoneNumber = %s", (user.Email, user.PhoneNumber))
        if cursor.fetchone():
            cursor.fetchall()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email or phone number already registered"
            )

        # find cityID from it's Name
        cursor.execute("SELECT CityID FROM City WHERE CityName = %s", (user.City,))
        city_record = cursor.fetchone()
        cursor.fetchall()

        # if city not found return error
        if not city_record:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"City '{user.City}' not found. Please use a valid city name."
            )
        city_id = city_record['CityID']

        # hash password
        hashed_password = get_password_hash(user.Password)

        # insert in database
        insert_query = """
            INSERT INTO User 
            (FirstName, LastName, Email, PhoneNumber, Password, RegistrationDate, AccountStatus, CityID, Role) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        registration_time = datetime.now().replace(microsecond=0)

        user_data = (
            user.FirstName,
            user.LastName,
            user.Email,
            user.PhoneNumber,
            hashed_password,
            registration_time,
            'active',
            city_id,
            'normalUser'
        )

        cursor.execute(insert_query, user_data)
        db.commit()

    except mysql.connector.Error as err:
        # db.rollback()
        # print(f"Database error during signup: {err}")
        db.rollback()
        import traceback
        traceback.print_exc()
        print(f"Database error during signup: {err}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An error occurred while creating the user."
        )
    finally:
        cursor.close()

    access_token = generate_access_token(data={"sub": user.Email})
    return {"access_token": access_token, "token_type": "bearer"}

#(API dependent to API1) send OTP
@router.post("/otp/send")
def send_otp(otp_request: OTPRequest, db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cursor = db.cursor()
    query = "SELECT UserID FROM User WHERE Email = %s OR PhoneNumber = %s"
    cursor.execute(query, (otp_request.phone_or_email, otp_request.phone_or_email))
    if not cursor.fetchone():
        cursor.close()
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    cursor.close()
    otp = ''.join(random.choices(string.digits, k=6))
    redis_client.set(f"OTP:{otp_request.phone_or_email}", otp, ex=300)
    print(f"--- MOCK OTP for {otp_request.phone_or_email}: {otp} ---")
    return {"message": "OTP sent successfully."}

#(API 1) login with email or phone number
@router.post("/otp/login", response_model=Token)
def otp_login(otp_request: OTPLoginRequest, db: mysql.connector.connection.MySQLConnection = Depends(get_db_connection)):
    cache_key = f"login:{otp_request.phone_or_email}"
    if cashed_result := redis_client.get(cache_key):
        return json.loads(cashed_result)
    cursor = db.cursor(dictionary=True)
    query = "SELECT UserID, Email FROM User WHERE Email = %s OR PhoneNumber = %s"
    cursor.execute(query, (otp_request.phone_or_email, otp_request.phone_or_email))
    user = cursor.fetchone()
    cursor.close()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    stored_otp = redis_client.get(f"OTP:{otp_request.phone_or_email}")
    if not stored_otp or stored_otp != otp_request.otp:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired OTP")

    access_token = generate_access_token(data={"sub": user["Email"]})
    redis_client.delete(f"OTP:{otp_request.phone_or_email}")
    return {"access_token": access_token, "token_type": "bearer"}
