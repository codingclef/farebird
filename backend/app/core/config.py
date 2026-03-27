from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    APP_ENV: str = "development"
    SECRET_KEY: str = "change-me-in-production"

    SERPAPI_KEY: str = ""

    DATABASE_URL: str = ""

    FIREBASE_CREDENTIALS_PATH: str = "./firebase-credentials.json"

    SENDGRID_API_KEY: str = ""
    EMAIL_FROM: str = "noreply@farebird.app"

    class Config:
        env_file = ".env"


settings = Settings()
