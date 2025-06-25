from pydantic import BaseModel, EmailStr
from typing import List, Optional, Dict
from datetime import datetime, date, time


#User
class UserCreate(BaseModel):
    FirstName: str
    LastName: str
    Email: EmailStr
    PhoneNumber: str
    Password: str
    City: str


class UserProfileUpdate(BaseModel):
    FirstName: Optional[str] = None
    LastName: Optional[str] = None
    PhoneNumber: Optional[str] = None
    Email : Optional[EmailStr] = None
    City : Optional[str] = None

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

class LoginWithPassword(BaseModel):
    phone_or_Email: str
    password: str

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

class AdvancedTicketSearchResponse(BaseModel):
    TicketID: int
    Origin: str
    Destination: str
    DepartureDateTime: str
    ArrivalDateTime: str
    Price: float
    RemainingCapacity: int
    CompanyName: str
    VehicleType: str

class TicketDetailsResponse(BaseModel):
    TicketID: int
    Origin: str
    Destination: str
    DepartureDate: str
    DepartureTime: str
    ArrivalDate: str
    ArrivalTime: str
    Price: int
    RemainingCapacity: int
    CompanyName: str
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
    ReservationID: int
    ReportSubject: str
    ReportText: str

class AdminReservationUpdate(BaseModel):
    NewStatus: str

class TicketInfoForBooking(BaseModel):
    Origin: str
    Destination: str
    DepartureDateTime: str
    Price: float
    CompanyName: str

class UserBookingDetailsResponse(BaseModel):
    ReservationStatus: str
    ReservationTime: datetime
    TicketDetails: TicketInfoForBooking

class ReportResponse(BaseModel):
    FirstName: str
    LastName: str
    Email: EmailStr
    OriginCity: Optional[str] = None
    DestinationCity: Optional[str] = None
    CompanyName: Optional[str] = None
    ReportSubject: str
    ReportText: str
    ReportStatus: str

class UncheckedReportResponse(BaseModel):
    ReportID: int
    FirstName: str
    LastName: str
    Email: EmailStr
    OriginCity: Optional[str] = None
    DestinationCity: Optional[str] = None
    CompanyName: Optional[str] = None
    ReportSubject: str
    ReportText: str


class CancelledTicketReportResponse(BaseModel):
    TicketID: int
    Origin: str
    Destination: str
    DepartureDate: str
    DepartureTime: str
    ArrivalDate: str
    ArrivalTime: str
    Price: int
    CompanyName: str

class PaymentResponse(BaseModel):
    FirstName: str
    LastName: str
    Origin: str
    Destination: str
    DepartureDate: str
    DepartureTime: str
    ArrivalDate: str
    ArrivalTime: str
    CompanyName: str
    Price: int
    PaymentTime : str
    PaymentMethod: str


