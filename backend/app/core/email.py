import logging
import random
import string

from app.core.config import settings

logger = logging.getLogger(__name__)


def generate_code() -> str:
    return "".join(random.choices(string.digits, k=6))


def send_verification_email(to_email: str, code: str) -> None:
    if not settings.SENDGRID_API_KEY:
        print(f"\n[DEV] 이메일 인증 코드 ({to_email}): {code}\n", flush=True)
        return

    try:
        import sendgrid
        from sendgrid.helpers.mail import Mail

        sg = sendgrid.SendGridAPIClient(api_key=settings.SENDGRID_API_KEY)
        mail = Mail(
            from_email=settings.EMAIL_FROM,
            to_emails=to_email,
            subject="[FareBird] 이메일 인증 코드",
            plain_text_content=f"인증 코드: {code}\n\n10분 내에 입력해주세요.",
        )
        sg.send(mail)
    except Exception as e:
        logger.error(f"이메일 발송 실패: {e}")
