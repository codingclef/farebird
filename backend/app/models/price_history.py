from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class PriceHistory(Base):
    __tablename__ = "price_history"

    id = Column(Integer, primary_key=True, index=True)
    route_id = Column(Integer, ForeignKey("watched_routes.id"), nullable=False)
    price = Column(Integer, nullable=False)           # 최저가 (원)
    airline = Column(String, nullable=False)
    depart_date = Column(String(10), nullable=False)  # 실제 출발일
    return_date = Column(String(10), nullable=False)  # 실제 귀국일
    checked_at = Column(DateTime(timezone=True), server_default=func.now())

    route = relationship("WatchedRoute", back_populates="price_history")
