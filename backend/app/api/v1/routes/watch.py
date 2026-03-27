from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models import WatchedRoute
from app.schemas.watch import WatchRouteRequest, WatchRouteResponse

router = APIRouter(prefix="/watch", tags=["watch"])


@router.post("/", response_model=WatchRouteResponse)
def add_watch(req: WatchRouteRequest, db: Session = Depends(get_db)):
    route = WatchedRoute(**req.model_dump())
    db.add(route)
    db.commit()
    db.refresh(route)
    return route


@router.get("/user/{user_id}", response_model=list[WatchRouteResponse])
def get_user_watches(user_id: int, db: Session = Depends(get_db)):
    return db.query(WatchedRoute).filter(
        WatchedRoute.user_id == user_id,
        WatchedRoute.is_active == True,
    ).all()


@router.delete("/{route_id}")
def delete_watch(route_id: int, db: Session = Depends(get_db)):
    route = db.query(WatchedRoute).filter(WatchedRoute.id == route_id).first()
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")
    route.is_active = False
    db.commit()
    return {"message": "Watch deleted"}
