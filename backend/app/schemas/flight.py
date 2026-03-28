from pydantic import BaseModel
from typing import Optional


class DatePair(BaseModel):
    depart_date: str   # 출발 날짜 (예: "2025-06-01")
    return_date: str   # 귀국 날짜 (예: "2025-06-10")


class FlightSearchRequest(BaseModel):
    origin: str           # 출발 공항 코드 (예: ICN)
    destination: str      # 도착 공항 코드 (예: NRT)
    date_pairs: list[DatePair]   # 출발-귀국 날짜 쌍 목록
    adults: int = 1
    currency: str = "KRW"


class FlightItinerary(BaseModel):
    depart_date: str
    return_date: str
    airline: str
    airline_return: Optional[str] = None
    depart_time: Optional[str] = None         # 출발편 출발 시각 (예: "09:30")
    arrive_time: Optional[str] = None         # 출발편 도착 시각 (예: "11:45")
    return_depart_time: Optional[str] = None  # 귀국편 출발 시각
    return_arrive_time: Optional[str] = None  # 귀국편 도착 시각
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
