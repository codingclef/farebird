from datetime import date

from fastapi import HTTPException
from serpapi import GoogleSearch

from app.core.config import settings
from app.schemas.flight import FlightItinerary, FlightSearchRequest, FlightSearchResponse


def _time(raw: str | None) -> str | None:
    """SerpAPI 시각 포맷 "2026-05-01 09:30" → "09:30""""
    if not raw:
        return None
    parts = raw.split(" ")
    return parts[1] if len(parts) == 2 else None


def _fetch_return_legs(departure_token: str, currency: str) -> list:
    """departure_token으로 귀국편 legs 반환. 실패 시 빈 리스트."""
    try:
        results = GoogleSearch({
            "engine": "google_flights",
            "departure_token": departure_token,
            "currency": currency,
            "hl": "ko",
            "api_key": settings.SERPAPI_KEY,
        }).get_dict()
        flights = results.get("best_flights", []) or results.get("other_flights", [])
        return flights[0].get("flights", []) if flights else []
    except Exception:
        return []


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

        price = flight.get("price", 0)
        if not price:
            continue  # 0원 결과 제외

        # 귀국편: departure_token으로 2번째 호출
        departure_token = flight.get("departure_token") or flight.get("booking_token")
        return_legs = _fetch_return_legs(departure_token, currency) if departure_token else []
        return_airline = return_legs[0].get("airline") if return_legs else None

        total_duration = flight.get("total_duration", 0)
        itineraries.append(FlightItinerary(
            depart_date=depart_date,
            return_date=return_date,
            airline=legs[0].get("airline", "Unknown"),
            airline_return=return_airline,
            depart_time=_time(legs[0].get("departure_airport", {}).get("time")),
            arrive_time=_time(legs[-1].get("arrival_airport", {}).get("time")),
            return_depart_time=_time(return_legs[0].get("departure_airport", {}).get("time")) if return_legs else None,
            return_arrive_time=_time(return_legs[-1].get("arrival_airport", {}).get("time")) if return_legs else None,
            price=price,
            currency=currency,
            duration_outbound=f"{total_duration // 60}h {total_duration % 60}m" if total_duration else None,
            stops_outbound=len(legs) - 1,
            booking_url=departure_token,
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
