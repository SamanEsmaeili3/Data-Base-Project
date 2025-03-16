/* 2025-03-16 18:05:31 [101 ms] */ 
CREATE TABLE City (
    CityID INT PRIMARY KEY AUTO_INCREMENT,
    CityName VARCHAR(100) NOT NULL
);
/* 2025-03-16 18:05:35 [52 ms] */ 
CREATE TABLE User (
    UserID INT PRIMARY KEY AUTO_INCREMENT,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Email VARCHAR(100) UNIQUE,
    PhoneNumber VARCHAR(20) UNIQUE,
    Password VARCHAR(255),
    RegistrationDate DATETIME,
    AccountStatus VARCHAR(20),
    CityID INT,
    Role ENUM('admin', 'normalUser') NOT NULL,
    FOREIGN KEY (CityID) REFERENCES City(CityID)
);

CREATE TABLE TransportCompany (
    TransportCompanyID INT PRIMARY KEY AUTO_INCREMENT,
    CompanyName VARCHAR(100) NOT NULL
);

-- جدول بلیط‌ها
CREATE TABLE Ticket (
    TicketID INT PRIMARY KEY AUTO_INCREMENT,
    Origin INT,
    Destination INT,
    DepartureDate DATE,
    DepartureTime TIME,
    ArrivalDate DATE,
    ArrivalTime TIME,
    Price INT,
    RemainingCapacity INT,
    TransportCompanyID INT,
    FOREIGN KEY (Origin) REFERENCES City(CityID),
    FOREIGN KEY (Destination) REFERENCES City(CityID),
    FOREIGN KEY (TransportCompanyID) REFERENCES TransportCompany(TransportCompanyID)
);


CREATE TABLE AirplaneTicket (
    TicketID INT PRIMARY KEY,
    CompanyName VARCHAR(100),
    FlightClass VARCHAR(50),
    NumberOfStops INT,
    FlightNumber VARCHAR(50),
    OriginAirPort VARCHAR(100),
    DestinationAirPort VARCHAR(100),
    Features TEXT,
    FOREIGN KEY (TicketID) REFERENCES Ticket(TicketID)
);


CREATE TABLE BusTicket (
    TicketID INT PRIMARY KEY,
    CompanyName VARCHAR(100),
    BusType VARCHAR(50),
    ChairInRow INT,
    Feature TEXT,
    FOREIGN KEY (TicketID) REFERENCES Ticket(TicketID)
);


CREATE TABLE TrainTicket (
    TicketID INT PRIMARY KEY,
    NumberOfStars INT,
    Feature TEXT,
    ClosedCompartment BOOLEAN,
    FOREIGN KEY (TicketID) REFERENCES Ticket(TicketID)
);


CREATE TABLE Reservation (
    ReservationID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT,
    TicketID INT,
    ReservationStatus VARCHAR(50),
    ReservationTime DATETIME,
    ReservationExpiryTime DATETIME,
    FOREIGN KEY (UserID) REFERENCES User(UserID),
    FOREIGN KEY (TicketID) REFERENCES Ticket(TicketID)
);


CREATE TABLE Payment (
    PaymentID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT,
    ReservationID INT,
    PaymentMethod VARCHAR(50),
    PaymentStatus VARCHAR(50),
    PaymentTime DATETIME,
    FOREIGN KEY (UserID) REFERENCES User(UserID),
    FOREIGN KEY (ReservationID) REFERENCES Reservation(ReservationID)
);


CREATE TABLE Reports (
    ReportID INT PRIMARY KEY AUTO_INCREMENT,
    ReportingUserID INT,
    TicketID INT,
    ReservationID INT,
    ReportSubject VARCHAR(100),
    ReportText TEXT,
    ReportStatus VARCHAR(50),
    FOREIGN KEY (ReportingUserID) REFERENCES User(UserID),
    FOREIGN KEY (TicketID) REFERENCES Ticket(TicketID),
    FOREIGN KEY (ReservationID) REFERENCES Reservation(ReservationID)
);


CREATE TABLE ReservationIssue (
    IssueID INT PRIMARY KEY AUTO_INCREMENT,
    ReservationID INT,
    IssueDescription TEXT,
    IssueStatus VARCHAR(50),
    FOREIGN KEY (ReservationID) REFERENCES Reservation(ReservationID)
);


CREATE TABLE PaymentHistory (
    HistoryID INT PRIMARY KEY AUTO_INCREMENT,
    PaymentID INT,
    StatusChangeTime DATETIME,
    StatusDescription VARCHAR(255),
    FOREIGN KEY (PaymentID) REFERENCES Payment(PaymentID)
);