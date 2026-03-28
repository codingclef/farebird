from datetime import date

from fastapi import HTTPException
from serpapi import GoogleSearch

from app.core.config import settings
from app.schemas.flight import FlightItinerary, FlightSearchRequest, FlightSearchResponse


def _search_one(origin: str, destination: str, depart_date: str, return_date: str,
                adults: int, currency: str) -> list[FlightItinerary]:
    params = {
        "engine": "google_flights",
        "departure_id": origin,
        "arrival_id": destination,
        "outbound_date": depart_date,
        "return_date": return_date,
        "adults": adults,
        "currency": currency,
        "hl": "ko",
        "api_key": settings.SERPAPI_KEY,
    }

    search = GoogleSearch(params)
    results = search.get_dict()

    if results.get("error"):
        raise HTTPException(status_code=400, detail=results["error"])

    itineraries = []
    for flight in results.get("best_flights", []) + results.get("other_flights", []):
        legs = flight.get("flights", [])
        if not legs:
            continue

        return_flights = flight.get("return_flights", [])
        return_legs = return_flights[0].get("flights", []) if return_flights else []
        return_airline = return_legs[0].get("airline") if return_legs else None

        # SerpAPI time format: "2026-05-01 09:30" → "09:30"
        def _time(raw: str | None) -> str | None:
            if not raw:
                return None
            parts = raw.split(" ")
            return parts[1] if len(parts) == 2 else None

        depart_time = _time(legs[0].get("departure_airport", {}).get("time"))
        arrive_time = _time(legs[-1].get("arrival_airport", {}).get("time"))

        total_duration = flight.get("total_duration", 0)
        itineraries.append(FlightItinerary(
            depart_date=depart_date,
            return_date=return_date,
            airline=legs[0].get("airline", "Unknown"),
            airline_return=return_airline,
            depart_time=depart_time,
            arrive_time=arrive_time,
            price=flight.get("price", 0),
            currency=currency,
            duration_outbound=f"{total_duration // 60}h {total_duration % 60}m" if total_duration else None,
            stops_outbound=len(legs) - 1,
            booking_url=flight.get("booking_token"),
        ))

    return itineraries


def search_flights(req: FlightSearchRequest) -> FlightSearchResponse:
    today = date.today().isoformat()

    all_results = []
    for pair in req.date_pairs:
        if pair.depart_date < today:
            raise HTTPException(status_code=400, detail=f"Date {pair.depart_date} is in the past.")
        if pair.return_date < today:
            raise HTTPException(status_code=400, detail=f"Date {pair.return_date} is in the past.")
        if pair.return_date <= pair.depart_date:
            raise HTTPException(status_code=400, detail=f"Return date {pair.return_date} must be after depart date {pair.depart_date}.")
        itineraries = _search_one(
            origin=req.origin,
            destination=req.destination,
            depart_date=pair.depart_date,
            return_date=pair.return_date,
            adults=req.adults,
            currency=req.currency,
        )
        all_results.extend(itineraries)

    all_results.sort(key=lambda x: x.price)

    return FlightSearchResponse(
        origin=req.origin,
        destination=req.destination,
        results=all_results,
        total_combinations=len(req.date_pairs),
    )
