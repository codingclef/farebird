from sqlalchemy import Boolean, Column, DateTime, Integer, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    push_token = Column(String, nullable=True)       # FCM 토큰
    notify_push = Column(Boolean, default=True)      # 푸시 알림 여부
    notify_email = Column(Boolean, default=True)     # 이메일 알림 여부
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    watched_routes = relationship("WatchedRoute", back_populates="user")
