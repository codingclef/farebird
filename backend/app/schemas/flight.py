from pydantic import BaseModel
from typing import Optional


class FlightSearchRequest(BaseModel):
    origin: str           # 출발 공항 코드 (예: ICN)
    destination: str      # 도착 공항 코드 (예: NRT)
    depart_dates: list[str]   # 출발 날짜 목록 (예: ["2025-06-01", "2025-06-08"])
    return_dates: list[str]   # 귀국 날짜 목록 (예: ["2025-06-10", "2025-06-15"])
    adults: int = 1
    currency: str = "KRW"


class FlightItinerary(BaseModel):
    depart_date: str
    return_date: str
    airline: str
    price: int
    currency: str
    duration_outbound: Optional[str] = None
    duration_return: Optional[str] = None
    stops_outbound: int = 0
    stops_return: int = 0
    booking_url: Optional[str] = None


class FlightSearchResponse(BaseModel):
    origin: str
    destination: str
    results: list[FlightItinerary]
    total_combinations: int
