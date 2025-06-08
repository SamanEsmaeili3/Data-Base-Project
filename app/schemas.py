from pydantic import BaseModel, EmailStr
from typing import List, Optional, Dict
from datetime import datetime

#User
class UserCreate(BaseModel):
    FirstName: str
    LastName: str
    PhoneNumber: str
    Email: EmailStr
    City: str
    Password: str

class UserProfileUpdate(BaseModel):
    FirstName: Optional[str] = None
    LastName: Optional[str] = None
    PhoneNumber: Optional[str] = None
    Email : Optional[EmailStr] = None
    City : Optional[str]

class UserResponse(BaseModel):
    UserID: int
    FirstName: str
    LastName: str
    Email: EmailStr
    PhoneNumber: str
    Role: str

#Auth
class Token(BaseModel):
    access_token: str
    token_type: str


class OTPRequest(BaseModel):
    phone_or_email: str


class OTPLoginRequest(OTPRequest):
    otp: str


#Ticket And City
class CitySchema(BaseModel):
    CityID: int
    CityName: str

class TicketSearchResponse(BaseModel):
    TicketID: int
    Origin: str
    Destination: str
    DepartureDateTime: str
    ArrivalDateTime: str
    Price: float
    RemainingCapacity: int
    CompanyName: str

class TicketDetailsResponse(BaseModel):
    TicketID: int
    Origin: int
    Destination: int
    DepartureDate: str
    DepartureTime: str
    Price: float
    RemainingCapacity: int
    Features: Optional[Dict] = None

#Reservation, Payment, Report
class ReservationCreate(BaseModel):
    TicketID: int

class ReservationResponse(BaseModel):
    ReservationID: int
    TicketID: int
    UserID: int
    ReservationStatus: str
    ReservationTime: datetime
    ReservationExpiryTime: datetime

class PaymentRequest(BaseModel):
    ReservationID: int
    PaymentMethod: str

class ReportCreate(BaseModel):
    TicketID: int
    ReservationID: int
    ReportSubject: str
    ReportText: str

class AdminReservationUpdate(BaseModel):
    NewStatus: str
