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

    itineraries = []

    best_flights = results.get("best_flights", [])
    other_flights = results.get("other_flights", [])

    for flight in best_flights + other_flights:
        legs = flight.get("flights", [])
        if not legs:
            continue

        airline = legs[0].get("airline", "Unknown")
        price = flight.get("price", 0)
        total_duration = flight.get("total_duration", 0)

        itineraries.append(FlightItinerary(
            depart_date=depart_date,
            return_date=return_date,
            airline=airline,
            price=price,
            currency=currency,
            duration_outbound=f"{total_duration // 60}h {total_duration % 60}m" if total_duration else None,
            stops_outbound=len(legs) - 1,
            booking_url=flight.get("booking_token"),
        ))

    return itineraries


def search_flights(req: FlightSearchRequest) -> FlightSearchResponse:
    all_results = []

    for depart_date in req.depart_dates:
        for return_date in req.return_dates:
            itineraries = _search_one(
                origin=req.origin,
                destination=req.destination,
                depart_date=depart_date,
                return_date=return_date,
                adults=req.adults,
                currency=req.currency,
            )
            all_results.extend(itineraries)

    all_results.sort(key=lambda x: x.price)

    return FlightSearchResponse(
        origin=req.origin,
        destination=req.destination,
        results=all_results,
        total_combinations=len(req.depart_dates) * len(req.return_dates),
    )
