from fastapi import Cookie, HTTPException
from itsdangerous import BadSignature, URLSafeSerializer

from app.core.config import settings

_serializer = None


def _get_serializer() -> URLSafeSerializer:
    global _serializer
    if _serializer is None:
        _serializer = URLSafeSerializer(settings.SECRET_KEY, salt="admin-session")
    return _serializer


def create_session_token(user_id: int) -> str:
    return _get_serializer().dumps({"user_id": user_id})


def decode_session_token(token: str) -> int:
    try:
        data = _get_serializer().loads(token)
        return data["user_id"]
    except BadSignature:
        raise HTTPException(status_code=403, detail="Invalid session")


def require_admin_session(admin_session: str | None = Cookie(default=None)) -> int:
    if not admin_session:
        raise HTTPException(status_code=302, headers={"Location": "/admin/login"})
    return decode_session_token(admin_session)
