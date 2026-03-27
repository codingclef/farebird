"""app/core/email.py 유닛 테스트"""
from unittest.mock import MagicMock, patch

from app.core.email import generate_code, send_verification_email


class TestGenerateCode:
    def test_code_is_six_digits(self):
        code = generate_code()
        assert len(code) == 6
        assert code.isdigit()

    def test_codes_are_random(self):
        codes = {generate_code() for _ in range(20)}
        assert len(codes) > 1


class TestSendVerificationEmail:
    def test_prints_code_when_no_api_key(self, capsys):
        with patch("app.core.email.settings") as mock_settings:
            mock_settings.SENDGRID_API_KEY = ""
            send_verification_email("test@example.com", "123456")
        output = capsys.readouterr().out
        assert "123456" in output
        assert "test@example.com" in output

    def test_calls_sendgrid_when_api_key_set(self):
        with patch("app.core.email.settings") as mock_settings:
            mock_settings.SENDGRID_API_KEY = "test-key"
            mock_settings.EMAIL_FROM = "noreply@farebird.app"
            with patch("sendgrid.SendGridAPIClient") as mock_sg:
                mock_sg.return_value.send = MagicMock()
                send_verification_email("test@example.com", "123456")
                mock_sg.return_value.send.assert_called_once()
