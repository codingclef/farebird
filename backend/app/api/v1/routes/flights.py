from fastapi import APIRouter
from app.schemas.flight import FlightSearchRequest, FlightSearchResponse
from app.services.flight_service import search_flights

router = APIRouter(prefix="/flights", tags=["flights"])


@router.post("/search", response_model=FlightSearchResponse)
async def search(req: FlightSearchRequest):
    return search_flights(req)
