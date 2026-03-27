# FareBird

항공권 가격 추적 및 알림 서비스

## 주요 기능

- 출발/도착 날짜 복수 지정 후 항공권 가격 비교
- 항공사, 예매처, 가격, 항공편 정보 조회
- 정기적인 가격 모니터링 및 할인 알림 (푸시 / 이메일)
- 항공사 특가 소식 알림

## 기술 스택

| 영역 | 기술 |
|------|------|
| Backend | Python, FastAPI, SQLAlchemy, APScheduler |
| Mobile | Flutter (iOS / Android / Web) |
| Database | PostgreSQL |
| 항공 데이터 | Amadeus for Developers API |
| 푸시 알림 | Firebase Cloud Messaging |
| 이메일 | SendGrid |
| 인프라 | Docker, Oracle Cloud Free Tier |

## 로컬 개발 환경

```bash
cd infra
docker-compose up -d
```

API 서버: http://localhost:8000
API 문서: http://localhost:8000/docs
