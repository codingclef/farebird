from fastapi import APIRouter, Depends, Form, Request
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session

from app.core.admin_session import create_session_token, require_admin_session
from app.core.auth import verify_password
from app.core.database import get_db
from app.models.user import User
from app.models.watched_route import WatchedRoute

router = APIRouter(prefix="/admin")
templates = Jinja2Templates(directory="app/templates")


@router.get("/login", response_class=HTMLResponse)
def login_page(request: Request):
    return templates.TemplateResponse("admin/login.html", {"request": request})


@router.post("/login")
def login(request: Request, email: str = Form(...), password: str = Form(...), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == email).first()
    if not user or not user.is_admin or not verify_password(password, user.hashed_password):
        return templates.TemplateResponse("admin/login.html", {
            "request": request,
            "error": "이메일 또는 비밀번호가 올바르지 않거나 어드민 권한이 없습니다."
        })
    response = RedirectResponse(url="/admin", status_code=302)
    response.set_cookie("admin_session", create_session_token(user.id), httponly=True)
    return response


@router.get("/logout")
def logout():
    response = RedirectResponse(url="/admin/login", status_code=302)
    response.delete_cookie("admin_session")
    return response


@router.get("", response_class=HTMLResponse)
def dashboard(request: Request, db: Session = Depends(get_db), _: int = Depends(require_admin_session)):
    total_users = db.query(User).count()
    active_users = db.query(User).filter(User.is_active == True).count()
    total_routes = db.query(WatchedRoute).count()
    recent_users = db.query(User).order_by(User.created_at.desc()).limit(10).all()

    return templates.TemplateResponse("admin/dashboard.html", {
        "request": request,
        "title": "대시보드",
        "active": "dashboard",
        "total_users": total_users,
        "active_users": active_users,
        "total_routes": total_routes,
        "recent_users": recent_users,
    })


@router.get("/users", response_class=HTMLResponse)
def users(request: Request, db: Session = Depends(get_db), _: int = Depends(require_admin_session)):
    all_users = db.query(User).order_by(User.created_at.desc()).all()
    return templates.TemplateResponse("admin/users.html", {
        "request": request,
        "title": "유저 관리",
        "active": "users",
        "users": all_users,
    })


@router.get("/routes", response_class=HTMLResponse)
def routes(request: Request, db: Session = Depends(get_db), _: int = Depends(require_admin_session)):
    all_routes = db.query(WatchedRoute).order_by(WatchedRoute.created_at.desc()).all()
    return templates.TemplateResponse("admin/routes.html", {
        "request": request,
        "title": "모니터링 노선",
        "active": "routes",
        "routes": all_routes,
    })
