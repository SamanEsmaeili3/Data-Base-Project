import time
from database import es_client as es_sync_client

def sync_ticket_in_es(ticket_id: int, doc_to_update: dict):
    for attempt in range(3): # Try 3 times at max
        try:
            es_sync_client.update(
                index="tickets", 
                id=ticket_id, 
                body={"doc": doc_to_update}
            )
            print(f"✅ ES Sync Successful for TicketID {ticket_id} on attempt {attempt + 1}")
            return #Exit if successful
        except Exception as e:
            print(f"ES Sync FAILED (Attempt {attempt + 1}/3) for TicketID {ticket_id}: {e}")
            if attempt == 2: #if last attempt was unsuccessful
                print(f" CRITICAL: Could not sync TicketID {ticket_id}. Manual check required.")
            time.sleep(1) # wait 1 sec before next try