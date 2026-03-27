"""어드민 웹 페이지 테스트"""
from unittest.mock import patch


def _create_admin(db):
    from app.core.auth import hash_password
    from app.models.user import User
    user = User(
        email="admin@farebird.app",
        hashed_password=hash_password("Admin1234!"),
        is_active=True,
        is_admin=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def _create_normal_user(db):
    from app.core.auth import hash_password
    from app.models.user import User
    user = User(
        email="user@example.com",
        hashed_password=hash_password("Password1"),
        is_active=True,
        is_admin=False,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


class TestAdminLogin:
    def test_login_page_returns_200(self, client):
        res = client.get("/admin/login")
        assert res.status_code == 200
        assert "어드민" in res.text

    def test_login_success_redirects(self, client, db):
        _create_admin(db)
        res = client.post("/admin/login", data={
            "email": "admin@farebird.app",
            "password": "Admin1234!",
        }, follow_redirects=False)
        assert res.status_code == 302
        assert res.headers["location"] == "/admin"
        assert "admin_session" in res.cookies

    def test_login_wrong_password(self, client, db):
        _create_admin(db)
        res = client.post("/admin/login", data={
            "email": "admin@farebird.app",
            "password": "wrongpassword",
        })
        assert res.status_code == 200
        assert "올바르지 않거나" in res.text

    def test_login_non_admin_user_blocked(self, client, db):
        _create_normal_user(db)
        res = client.post("/admin/login", data={
            "email": "user@example.com",
            "password": "Password1",
        })
        assert res.status_code == 200
        assert "올바르지 않거나" in res.text


class TestAdminPages:
    def _login(self, client, db):
        _create_admin(db)
        res = client.post("/admin/login", data={
            "email": "admin@farebird.app",
            "password": "Admin1234!",
        }, follow_redirects=False)
        return res.cookies["admin_session"]

    def test_dashboard_requires_session(self, client):
        res = client.get("/admin", follow_redirects=False)
        assert res.status_code == 302

    def test_dashboard_accessible_with_session(self, client, db):
        session = self._login(client, db)
        res = client.get("/admin", cookies={"admin_session": session})
        assert res.status_code == 200
        assert "대시보드" in res.text

    def test_users_page(self, client, db):
        session = self._login(client, db)
        res = client.get("/admin/users", cookies={"admin_session": session})
        assert res.status_code == 200
        assert "유저 관리" in res.text

    def test_routes_page(self, client, db):
        session = self._login(client, db)
        res = client.get("/admin/routes", cookies={"admin_session": session})
        assert res.status_code == 200
        assert "모니터링 노선" in res.text

    def test_logout_clears_session(self, client, db):
        session = self._login(client, db)
        res = client.get("/admin/logout", cookies={"admin_session": session}, follow_redirects=False)
        assert res.status_code == 302
        assert res.headers["location"] == "/admin/login"
