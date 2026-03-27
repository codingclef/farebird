import logging
from calendar import monthrange
from datetime import date, timedelta

from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.models import PriceHistory, WatchedRoute
from app.schemas.flight import FlightSearchRequest
from app.services.flight_service import search_flights
from app.services.notification_service import send_price_alert

logger = logging.getLogger(__name__)

# 한 달치 날짜를 생성할 때 샘플링 간격 (일)
DATE_STEP = 3


def _get_sample_dates(year_month: str) -> list[str]:
    """주어진 월에서 출발/귀국 날짜 샘플을 생성."""
    year, month = map(int, year_month.split("-"))
    _, last_day = monthrange(year, month)
    today = date.today()
    dates = []
    for day in range(1, last_day + 1, DATE_STEP):
        d = date(year, month, day)
        if d > today + timedelta(days=3):
            dates.append(d.isoformat())
    return dates or []


def _get_average_price(db: Session, route_id: int, limit: int = 10) -> float | None:
    """최근 가격 이력의 평균 최저가 반환."""
    records = (
        db.query(PriceHistory)
        .filter(PriceHistory.route_id == route_id)
        .order_by(PriceHistory.checked_at.desc())
        .limit(limit)
        .all()
    )
    if not records:
        return None
    return sum(r.price for r in records) / len(records)


def check_route(db: Session, route: WatchedRoute):
    dates = _get_sample_dates(route.depart_month)
    if not dates:
        return

    # 출발 3일 후를 최소 귀국일로 설정
    return_dates = [
        (date.fromisoformat(d) + timedelta(days=3)).isoformat()
        for d in dates
    ]

    req = FlightSearchRequest(
        origin=route.origin,
        destination=route.destination,
        depart_dates=dates[:3],    # API 호출 절약: 최대 3개 날짜 조합
        return_dates=return_dates[:3],
        currency="KRW",
    )

    try:
        resp = search_flights(req)
    except Exception as e:
        logger.error(f"Route {route.id} search failed: {e}")
        return

    if not resp.results:
        return

    best = resp.results[0]

    # 가격 이력 저장
    record = PriceHistory(
        route_id=route.id,
        price=best.price,
        airline=best.airline,
        depart_date=best.depart_date,
        return_date=best.return_date,
    )
    db.add(record)
    db.commit()

    # 평균 대비 할인율 계산
    avg = _get_average_price(db, route.id, limit=10)
    if avg is None:
        return  # 이력 부족 — 다음 사이클에 비교

    discount_pct = (avg - best.price) / avg * 100
    if discount_pct >= route.alert_threshold:
        user = route.user
        logger.info(f"Price alert: route {route.id}, {discount_pct:.1f}% off, {best.price:,}원")
        send_price_alert(
            email=user.email,
            push_token=user.push_token,
            notify_push=user.notify_push,
            notify_email=user.notify_email,
            origin=route.origin,
            destination=route.destination,
            airline=best.airline,
            price=best.price,
            discount_pct=discount_pct,
            depart_date=best.depart_date,
            return_date=best.return_date,
        )


def run_price_monitor():
    """모든 활성 노선의 가격을 체크. 스케줄러에 의해 주기적으로 호출."""
    logger.info("Price monitor started")
    db: Session = SessionLocal()
    try:
        routes = (
            db.query(WatchedRoute)
            .filter(WatchedRoute.is_active == True)
            .all()
        )
        logger.info(f"Checking {len(routes)} active routes")
        for route in routes:
            check_route(db, route)
    finally:
        db.close()
    logger.info("Price monitor finished")
