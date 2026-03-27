"""app/schemas/auth.py 유닛 테스트 — 비밀번호 검증"""
import pytest
from pydantic import ValidationError

from app.schemas.auth import RegisterRequest


class TestPasswordValidation:
    def test_valid_password(self):
        req = RegisterRequest(email="test@example.com", password="Password1")
        assert req.password == "Password1"

    def test_too_short(self):
        with pytest.raises(ValidationError, match="8자 이상"):
            RegisterRequest(email="test@example.com", password="Pass1")

    def test_no_letter(self):
        with pytest.raises(ValidationError, match="영문자"):
            RegisterRequest(email="test@example.com", password="12345678")

    def test_no_digit(self):
        with pytest.raises(ValidationError, match="숫자"):
            RegisterRequest(email="test@example.com", password="PasswordOnly")

    def test_invalid_email(self):
        with pytest.raises(ValidationError):
            RegisterRequest(email="not-an-email", password="Password1")
