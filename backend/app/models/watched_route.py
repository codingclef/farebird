from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class WatchedRoute(Base):
    __tablename__ = "watched_routes"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    origin = Column(String(10), nullable=False)           # 출발 공항 코드 (예: ICN)
    destination = Column(String(10), nullable=False)      # 도착 공항 코드 (예: NRT)
    depart_month = Column(String(7), nullable=False)      # 모니터링 월 (예: 2026-05)
    alert_threshold = Column(Float, default=10.0)         # 알림 기준 할인율 (%)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="watched_routes")
    price_history = relationship("PriceHistory", back_populates="route")
