"""app/core/auth.py 유닛 테스트"""
import pytest
from jose import JWTError

from app.core.auth import (
    create_access_token,
    decode_token,
    hash_password,
    verify_password,
)


class TestPasswordHashing:
    def test_hash_is_different_from_plain(self):
        hashed = hash_password("password123")
        assert hashed != "password123"

    def test_verify_correct_password(self):
        hashed = hash_password("mySecret1")
        assert verify_password("mySecret1", hashed) is True

    def test_verify_wrong_password(self):
        hashed = hash_password("mySecret1")
        assert verify_password("wrongPass", hashed) is False

    def test_same_password_different_hashes(self):
        # bcrypt는 매번 다른 salt를 사용
        h1 = hash_password("password123")
        h2 = hash_password("password123")
        assert h1 != h2


class TestJwtToken:
    def test_create_and_decode_token(self):
        token = create_access_token(user_id=42)
        assert decode_token(token) == 42

    def test_invalid_token_raises(self):
        with pytest.raises(Exception):
            decode_token("invalid.token.here")

    def test_different_users_different_tokens(self):
        token1 = create_access_token(user_id=1)
        token2 = create_access_token(user_id=2)
        assert token1 != token2
        assert decode_token(token1) == 1
        assert decode_token(token2) == 2
