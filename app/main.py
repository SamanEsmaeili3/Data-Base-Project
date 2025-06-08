from fastapi import FastAPI
from app.routers import auth, users, tickets, admin

app = FastAPI(
    title="Ticketing Service API",
    description="API for searching, reserving, and managing travel tickets.",
    version="1.0.0"
)

# Include all routers
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(tickets.router)
app.include_router(admin.router)

@app.get("/", tags=["Root"])
def read_root():
    """A simple endpoint to check if the API is running."""
    return {"status": "ok", "message": "Welcome to the Ticketing Service API"}