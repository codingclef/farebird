from pydantic import BaseModel
from typing import Optional


class WatchRouteRequest(BaseModel):
    user_id: int
    origin: str
    destination: str
    depart_month: str          # 예: "2026-05"
    alert_threshold: float = 10.0  # 알림 기준 할인율 (%)


class WatchRouteResponse(BaseModel):
    id: int
    user_id: int
    origin: str
    destination: str
    depart_month: str
    alert_threshold: float
    is_active: bool

    class Config:
        from_attributes = True
