from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    APP_ENV: str = "development"
    SECRET_KEY: str = "change-me-in-production"

    AMADEUS_CLIENT_ID: str
    AMADEUS_CLIENT_SECRET: str
    AMADEUS_HOSTNAME: str = "test"

    DATABASE_URL: str

    REDIS_URL: str = ""

    FIREBASE_CREDENTIALS_PATH: str = "./firebase-credentials.json"

    SENDGRID_API_KEY: str = ""
    EMAIL_FROM: str = "noreply@farebird.app"

    class Config:
        env_file = ".env"


settings = Settings()
