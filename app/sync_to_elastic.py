import os
import mysql.connector
from dotenv import load_dotenv
from elasticsearch import Elasticsearch
from elasticsearch.helpers import bulk

#Index name in ElasticSearch
INDEX_NAME = "tickets"

# Define schema index for Tickets
INDEX_MAPPING = {
    "mappings": {
        "properties": {
            "TicketID": {"type": "integer"},
            "Origin": {"type": "keyword"},
            "Destination": {"type": "keyword"},
            "DepartureDateTime": {"type": "date"},
            "ArrivalDateTime": {"type": "date"},
            "Price": {"type": "float"},
            "RemainingCapacity": {"type": "integer"},
            "CompanyName": {"type": "text", "fields": {"keyword": {"type": "keyword"}}},
            "VehicleType": {"type": "keyword"},
            "Features": {"type": "object", "enabled": False}
        }
    }
}

def create_es_client():
    load_dotenv()
    es_host = os.getenv("ELASTICSEARCH_HOST", "http://localhost:9200")
    print(f"Connecting to ElasticSearch with this address: {es_host}")
    return Elasticsearch(hosts=[es_host])

def create_mysql_connection():
    load_dotenv()
    print("Connecting to MySQL database ...")
    return mysql.connector.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        user=os.getenv('DB_USER'),
        password=os.getenv('DB_PASSWORD'),
        database=os.getenv('DB_NAME')
    )

def fetch_tickets_from_mysql(db_conn):
    print("Reading information from MySQL...")
    cursor = db_conn.cursor(dictionary=True)
    query = """
        SELECT
            t.TicketID,
            c1.CityName AS Origin,
            c2.CityName AS Destination,
            CONCAT(t.DepartureDate, 'T', t.DepartureTime) as DepartureDateTime,
            CONCAT(t.ArrivalDate, 'T', t.ArrivalTime) as ArrivalDateTime,
            t.Price,
            t.RemainingCapacity,
            tc.CompanyName,
            CASE
                WHEN at.TicketID IS NOT NULL THEN 'airplane'
                WHEN bt.TicketID IS NOT NULL THEN 'bus'
                WHEN tt.TicketID IS NOT NULL THEN 'train'
                ELSE 'unknown'
            END AS VehicleType,
            at.FlightClass, at.NumberOfStops, at.FlightNumber,
            bt.BusType,
            tt.NumberOfStars, tt.ClosedCompartment
        FROM Ticket t
        JOIN City c1 ON t.Origin = c1.CityID
        JOIN City c2 ON t.Destination = c2.CityID
        JOIN TransportCompany tc ON t.TransportCompanyID = tc.TransportCompanyID
        LEFT JOIN AirplaneTicket at ON t.TicketID = at.TicketID
        LEFT JOIN BusTicket bt ON t.TicketID = bt.TicketID
        LEFT JOIN TrainTicket tt ON t.TicketID = tt.TicketID
    """
    cursor.execute(query)
    tickets = cursor.fetchall()
    cursor.close()
    print(f"{len(tickets)} tickets reads from MySQL")
    return tickets

def generate_actions(tickets):
    for ticket in tickets:
        features = {}
        if ticket['VehicleType'] == 'airplane':
            features = {'FlightClass': ticket.get('FlightClass'), 'NumberOfStops': ticket.get('NumberOfStops'), 'FlightNumber': ticket.get('FlightNumber')}
        elif ticket['VehicleType'] == 'bus':
            features = {'BusType': ticket.get('BusType')}
        elif ticket['VehicleType'] == 'train':
            features = {'NumberOfStars': ticket.get('NumberOfStars'), 'ClosedCompartment': ticket.get('ClosedCompartment')}

        doc = {
            "TicketID": ticket["TicketID"], "Origin": ticket["Origin"], "Destination": ticket["Destination"],
            "DepartureDateTime": ticket["DepartureDateTime"], "ArrivalDateTime": ticket["ArrivalDateTime"],
            "Price": ticket["Price"], "RemainingCapacity": ticket["RemainingCapacity"],
            "CompanyName": ticket["CompanyName"], "VehicleType": ticket["VehicleType"], "Features": features
        }
        yield {"_index": INDEX_NAME, "_id": ticket["TicketID"], "_source": doc}

def main():
    es_client = create_es_client()
    db_conn = create_mysql_connection()
    try:
        if not es_client.indices.exists(index=INDEX_NAME):
            print(f"Creating index {INDEX_NAME} ....")
            es_client.indices.create(index=INDEX_NAME, body=INDEX_MAPPING)
        else:
            print(f"Index {INDEX_NAME} already existed")
        tickets_data = fetch_tickets_from_mysql(db_conn)
        if tickets_data:
            print("Indexing data in ElasticSearch...")
            success, errors = bulk(es_client, generate_actions(tickets_data))
            print(f"Operation done successfully: {success}")
            if errors: print(f"Number of errors: {len(errors)}")
        else:
            print("No ticket found for indexing!")
    except Exception as e:
        print(f"Unexpected error : {e}")
    finally:
        if db_conn.is_connected():
            db_conn.close()
            print("Closed connection to MySQL")
        es_client.close()

if __name__ == "__main__":
    main()