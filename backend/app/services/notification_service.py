import logging

from app.core.config import settings

logger = logging.getLogger(__name__)


def send_push(push_token: str, title: str, body: str) -> bool:
    try:
        import firebase_admin
        from firebase_admin import credentials, messaging

        if not firebase_admin._apps:
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
            firebase_admin.initialize_app(cred)

        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            token=push_token,
        )
        messaging.send(message)
        return True
    except Exception as e:
        logger.error(f"Push notification failed: {e}")
        return False


def send_email(to_email: str, subject: str, body: str) -> bool:
    try:
        import sendgrid
        from sendgrid.helpers.mail import Mail

        sg = sendgrid.SendGridAPIClient(api_key=settings.SENDGRID_API_KEY)
        mail = Mail(
            from_email=settings.EMAIL_FROM,
            to_emails=to_email,
            subject=subject,
            plain_text_content=body,
        )
        sg.send(mail)
        return True
    except Exception as e:
        logger.error(f"Email notification failed: {e}")
        return False


def send_price_alert(email: str, push_token: str | None,
                     notify_push: bool, notify_email: bool,
                     origin: str, destination: str,
                     airline: str, price: int, discount_pct: float,
                     depart_date: str, return_date: str):
    title = f"FareBird: {origin}→{destination} 항공권 특가!"
    body = (
        f"{airline} / {price:,}원\n"
        f"출발: {depart_date}  귀국: {return_date}\n"
        f"평소 대비 {discount_pct:.1f}% 할인"
    )

    if notify_push and push_token:
        send_push(push_token, title, body)

    if notify_email and email:
        send_email(email, title, body)
