from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy.orm import Session

from app.core.auth import create_access_token, decode_token, hash_password, verify_password
from app.core.database import get_db
from app.core.email import generate_code, send_verification_email
from app.models.email_verification import EmailVerification
from app.models.user import User
from app.schemas.auth import LoginRequest, RegisterRequest, ResendVerificationRequest, TokenResponse, VerifyEmailRequest

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register")
def register(req: RegisterRequest, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == req.email).first()
    if existing:
        if existing.is_active:
            raise HTTPException(status_code=400, detail="이미 사용 중인 이메일입니다.")
        # 미인증 계정이면 비밀번호 업데이트 후 코드 재발송
        existing.hashed_password = hash_password(req.password)
        db.commit()
        user = existing
    else:
        user = User(email=req.email, hashed_password=hash_password(req.password), is_active=False)
        db.add(user)
        db.commit()
        db.refresh(user)

    # 기존 인증 코드 삭제 후 새로 발급
    db.query(EmailVerification).filter(EmailVerification.user_id == user.id).delete()
    code = generate_code()
    verification = EmailVerification(
        user_id=user.id,
        code=code,
        expires_at=datetime.now(timezone.utc) + timedelta(minutes=10),
    )
    db.add(verification)
    db.commit()

    send_verification_email(req.email, code)
    return {"message": "인증 코드를 이메일로 발송했습니다.", "email": req.email}


@router.post("/verify-email", response_model=TokenResponse)
def verify_email(req: VerifyEmailRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == req.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")

    verification = db.query(EmailVerification).filter(
        EmailVerification.user_id == user.id,
        EmailVerification.code == req.code,
    ).first()

    if not verification:
        raise HTTPException(status_code=400, detail="인증 코드가 올바르지 않습니다.")

    if verification.expires_at.replace(tzinfo=timezone.utc) < datetime.now(timezone.utc):
        raise HTTPException(status_code=400, detail="인증 코드가 만료되었습니다.")

    user.is_active = True
    db.delete(verification)
    db.commit()

    return TokenResponse(access_token=create_access_token(user.id), user_id=user.id)


@router.post("/resend-verification")
def resend_verification(req: ResendVerificationRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == req.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    if user.is_active:
        raise HTTPException(status_code=400, detail="이미 인증된 계정입니다.")

    db.query(EmailVerification).filter(EmailVerification.user_id == user.id).delete()
    code = generate_code()
    verification = EmailVerification(
        user_id=user.id,
        code=code,
        expires_at=datetime.now(timezone.utc) + timedelta(minutes=10),
    )
    db.add(verification)
    db.commit()

    send_verification_email(req.email, code)
    return {"message": "인증 코드를 재발송했습니다."}


@router.post("/login", response_model=TokenResponse)
def login(req: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == req.email).first()
    if not user or not verify_password(req.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="이메일 또는 비밀번호가 올바르지 않습니다.")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="이메일 인증이 완료되지 않았습니다.")
    return TokenResponse(access_token=create_access_token(user.id), user_id=user.id)


@router.delete("/me")
def delete_account(authorization: str = Header(...), password: str = "", db: Session = Depends(get_db)):
    try:
        user_id = decode_token(authorization.replace("Bearer ", ""))
    except Exception:
        raise HTTPException(status_code=401, detail="인증이 필요합니다.")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    if not verify_password(password, user.hashed_password):
        raise HTTPException(status_code=401, detail="비밀번호가 올바르지 않습니다.")
    db.delete(user)
    db.commit()
    return {"message": "계정이 삭제되었습니다."}
