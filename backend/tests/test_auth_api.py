"""POST /auth/register, /auth/login, /auth/verify-email API 테스트"""
from unittest.mock import patch


class TestRegister:
    def test_register_success(self, client):
        with patch("app.api.v1.routes.auth.send_verification_email"):
            res = client.post("/api/v1/auth/register", json={
                "email": "user@example.com",
                "password": "Password1",
            })
        assert res.status_code == 200
        assert res.json()["email"] == "user@example.com"

    def test_register_duplicate_email(self, client):
        with patch("app.api.v1.routes.auth.send_verification_email"):
            client.post("/api/v1/auth/register", json={
                "email": "user@example.com",
                "password": "Password1",
            })
            res = client.post("/api/v1/auth/register", json={
                "email": "user@example.com",
                "password": "Password1",
            })
        assert res.status_code == 400

    def test_register_weak_password(self, client):
        res = client.post("/api/v1/auth/register", json={
            "email": "user@example.com",
            "password": "short",
        })
        assert res.status_code == 422


class TestVerifyEmail:
    def _register(self, client):
        with patch("app.api.v1.routes.auth.send_verification_email"):
            client.post("/api/v1/auth/register", json={
                "email": "user@example.com",
                "password": "Password1",
            })

    def test_verify_with_correct_code(self, client, db):
        self._register(client)

        from app.models.email_verification import EmailVerification
        verification = db.query(EmailVerification).first()

        res = client.post("/api/v1/auth/verify-email", json={
            "email": "user@example.com",
            "code": verification.code,
        })
        assert res.status_code == 200
        assert "access_token" in res.json()

    def test_verify_with_wrong_code(self, client):
        self._register(client)
        res = client.post("/api/v1/auth/verify-email", json={
            "email": "user@example.com",
            "code": "000000",
        })
        assert res.status_code == 400


class TestLogin:
    def _register_and_verify(self, client, db):
        with patch("app.api.v1.routes.auth.send_verification_email"):
            client.post("/api/v1/auth/register", json={
                "email": "user@example.com",
                "password": "Password1",
            })
        from app.models.email_verification import EmailVerification
        verification = db.query(EmailVerification).first()
        client.post("/api/v1/auth/verify-email", json={
            "email": "user@example.com",
            "code": verification.code,
        })

    def test_login_success(self, client, db):
        self._register_and_verify(client, db)
        res = client.post("/api/v1/auth/login", json={
            "email": "user@example.com",
            "password": "Password1",
        })
        assert res.status_code == 200
        assert "access_token" in res.json()

    def test_login_wrong_password(self, client, db):
        self._register_and_verify(client, db)
        res = client.post("/api/v1/auth/login", json={
            "email": "user@example.com",
            "password": "WrongPass1",
        })
        assert res.status_code == 401

    def test_login_before_verification(self, client):
        with patch("app.api.v1.routes.auth.send_verification_email"):
            client.post("/api/v1/auth/register", json={
                "email": "user@example.com",
                "password": "Password1",
            })
        res = client.post("/api/v1/auth/login", json={
            "email": "user@example.com",
            "password": "Password1",
        })
        assert res.status_code == 403


class TestDeleteAccount:
    def _get_token(self, client, db):
        with patch("app.api.v1.routes.auth.send_verification_email"):
            client.post("/api/v1/auth/register", json={
                "email": "user@example.com",
                "password": "Password1",
            })
        from app.models.email_verification import EmailVerification
        verification = db.query(EmailVerification).first()
        res = client.post("/api/v1/auth/verify-email", json={
            "email": "user@example.com",
            "code": verification.code,
        })
        return res.json()["access_token"]

    def test_delete_with_correct_password(self, client, db):
        token = self._get_token(client, db)
        res = client.delete(
            "/api/v1/auth/me",
            params={"password": "Password1"},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert res.status_code == 200

    def test_delete_with_wrong_password(self, client, db):
        token = self._get_token(client, db)
        res = client.delete(
            "/api/v1/auth/me",
            params={"password": "WrongPass1"},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert res.status_code == 401
