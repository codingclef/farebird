from fastapi import APIRouter
from app.api.v1.routes import auth, flights, watch

router = APIRouter(prefix="/api/v1")
router.include_router(auth.router)
router.include_router(flights.router)
router.include_router(watch.router)
