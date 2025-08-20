# Ticketing Service API Project

This project is a powerful, RESTful API for a ticketing system (airline, train, and bus), implemented using the **FastAPI** framework and a **MySQL** database. This project utilizes **Redis** for caching and OTP management to optimize the application's performance and speed.

## 🚀 Core Features

* **Secure Authentication:** User registration and login with hashed passwords or via One-Time Passwords (OTP).
* **Complete Ticket Management:** Advanced search, view details, reserve, pay for, and cancel tickets.
* **Performance Optimization:** Use of Redis for caching search results and user profile information.
* **Admin Panel:** Ability for administrators to view reports and manage reservations.
* **Automatic Documentation:** Interactive and complete documentation via Swagger UI and ReDoc.
* **Modular Architecture:** Clean and decoupled code for easy maintenance and scalability.

## 🛠️ Prerequisites

To run this project, you will need the following tools:

* **Python 3.10+**
* **MySQL Server**
* **Redis Server**
* **Postman** (Optional, for API testing)

## ⚙️ Setup and Execution

Follow the steps below to set up and run the server.

### 1. Clone the Project and Install Dependencies

First, clone the project from its repository and then navigate into its directory.

```bash
# Create a virtual environment to isolate dependencies
python -m venv venv

# Activate the virtual environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

# Install all required libraries from the requirements.txt file
pip install -r requirements.txt
```

### 2. Database and Redis Configuration

1.  **MySQL Database:**
    * Ensure your MySQL server is running.
    * Create a new database with a name of your choice (e.g., `ticketing_db`).
    * Import the `InitialData.sql` file into this database to create the tables and initial data.

2.  **Redis Server:**
    * Ensure your Redis server is running (usually on port `6379`).

3.  **Set Up Environment Variables:**
    * In the project root, create a file named `.env`.
    * Copy the content below into it and replace the values with your actual information:

    ```env
    # Database Credentials
    DB_HOST=localhost
    DB_USER=your_mysql_user
    DB_PASSWORD=your_mysql_password
    DB_NAME=ticketing_db

    # Redis Credentials
    REDIS_HOST=localhost
    REDIS_PORT=6379

    # Application Secret Key (Generate a new one for production)
    SECRET_KEY=your_very_strong_and_random_secret_string
    ```

### 3. Run the Server

Everything is now ready to run the server. Use the following command:

```bash
uvicorn app.main:app --reload
```

* `--reload`: This option automatically restarts the server every time you save a code change.

After running this command, your server will be available at **`http://127.0.0.1:8000`**.

## 🧪 Testing the APIs

You can test the APIs in two ways:

### Method 1: Interactive Documentation (Swagger UI)

The easiest way to test is by using FastAPI's automatic documentation. Open your web browser and navigate to:

[http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

On this page, you can view all APIs, enter their parameters, and see the JSON output live.

### Method 2: Using Postman

For more advanced testing, you can use Postman. The list below provides all the necessary details for testing each endpoint.

**Important Note for Authentication:**
For APIs that require login, first obtain a JWT by using the `signup` or `otp/login` endpoints. Then, in Postman, go to the **Authorization** tab, select **`Bearer Token`** as the type, and paste the received token.

## 📄 API List

Here is a complete list of all API endpoints for testing in Postman.
*Base URL for all requests: `http://127.0.0.1:8000`*

---

### **Part 1: Authentication**

* **Path Prefix:** `/auth`

| #    | Action (API)      | Method | Full URL         | Sample Request Body                                                                                                                        |
| :--- | :---------------- | :----- | :--------------- | :----------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | **User Signup** | `POST` | `/auth/signup`   | `{ "FirstName": "Sara", "LastName": "Rezai", "Email": "sara.r@example.com", "PhoneNumber": "09121112233", "Password": "strongPassword123", "City": "Tehran" }` |
| 2    | **Send OTP** | `POST` | `/auth/otp/send` | `{ "phone_or_email": "sara.r@example.com" }`                                                                                                 |
| 3    | **Login with OTP**| `POST` | `/auth/otp/login`| `{ "phone_or_email": "sara.r@example.com", "otp": "123456" }`                                                                                 |

### **Part 2: User Management**

* **Path Prefix:** `/users`
* **Authentication:** Required (Bearer Token)

| #    | Action (API)          | Method | Full URL          | Sample Request Body                                        |
| :--- | :-------------------- | :----- | :---------------- | :--------------------------------------------------------- |
| 4    | **Get User Profile** | `GET`  | `/users/me`       | *(Empty)* |
| 5    | **Update User Profile**| `PUT`  | `/users/me`       | `{ "FirstName": "Sarina", "PhoneNumber": "09129998877" }` |
| 6    | **Get User Bookings** | `GET`  | `/users/me/bookings`| *(Empty)* |

### **Part 3: Tickets & Reservations**

* **Path Prefix:** `/tickets`

| #    | Action (API)                 | Method | Full URL & Parameters                                            | Sample Request Body                                                                                                                     |
| :--- | :--------------------------- | :----- | :--------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------- |
| 7    | **Get Cities List** | `GET`  | `/tickets/cities`                                                | *(Empty)* |
| 8    | **Search Tickets** | `GET`  | `/tickets/search?origin_id=1&destination_id=2&date=2025-06-01`    | *(Empty)* |
| 9    | **Get Ticket Details** | `GET`  | `/tickets/1`                                                     | *(Empty)* |
| 10   | **Reserve Ticket** | `POST` | `/tickets/reserve`                                               | `{ "TicketID": 1 }` **(Auth Required)** |
| 11   | **Pay for Ticket** | `POST` | `/tickets/pay`                                                   | `{ "ReservationID": 1, "PaymentMethod": "Bank Card" }` **(Auth Required)** |
| 12   | **Check Cancellation Penalty**| `GET`  | `/tickets/1/cancellation-penalty`                                | *(Empty)* |
| 13   | **Cancel Ticket & Refund** | `POST` | `/tickets/reservations/1/cancel`                                 | *(Empty)* **(Auth Required)** |
| 14   | **Report Ticket Issue** | `POST` | `/tickets/report`                                                | `{ "TicketID": 1, "ReservationID": 1, "ReportSubject": "Flight Delay", "ReportText": "The flight was delayed by two hours." }` **(Auth Required)** |

### **Part 4: Admin Management**

* **Path Prefix:** `/admin`
* **Authentication:** Required (Admin user with a valid token)

| #    | Action (API)                 | Method | Full URL                | Sample Request Body               |
| :--- | :--------------------------- | :----- | :---------------------- | :-------------------------------- |
| 15   | **Get All Reports** | `GET`  | `/admin/reports`        | *(Empty)* |
| 16   | **Change Reservation Status**| `PUT`  | `/admin/reservations/1` | `{ "NewStatus": "Cancelled" }`      |
