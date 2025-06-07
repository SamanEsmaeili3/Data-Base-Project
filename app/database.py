import mysql.connector
from mysql.connector import pooling
import redis
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# --- MySQL Connection Pool ---
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASSWORD'),
    'database': os.getenv('DB_NAME')
}

if not all([DB_CONFIG['user'], DB_CONFIG['password'], DB_CONFIG['database']]):
    print("FATAL ERROR: Database environment variables (DB_USER, DB_PASSWORD, DB_NAME) are not set.")
    exit()

try:
    db_pool = pooling.MySQLConnectionPool(
        pool_name="api_pool",
        pool_size=10,
        **DB_CONFIG
    )
    print("MySQL Connection Pool created successfully.")
except mysql.connector.Error as err:
    print(f"FATAL ERROR: Could not create MySQL connection pool: {err}")
    exit()

# --- Redis Connection ---
try:
    redis_client = redis.Redis(
        host=os.getenv('REDIS_HOST', 'localhost'),
        port=int(os.getenv('REDIS_PORT', 6379)),
        db=0,
        decode_responses=True
    )
    redis_client.ping()
    print("Redis connection successful.")
except redis.exceptions.ConnectionError as err:
    print(f"FATAL ERROR: Could not connect to Redis: {err}")
    exit()

# --- Dependency Function ---
def get_db_connection():
    """Dependency to get a DB connection from the pool and ensure it's returned."""
    try:
        connection = db_pool.get_connection()
        yield connection
    finally:
        if 'connection' in locals() and connection.is_connected():
            connection.close()