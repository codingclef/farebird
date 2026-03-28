# FareBird — Claude 작업 가이드

## 프로젝트 요약

여러 날짜 조합의 항공권 가격을 한 번에 비교하고, 가격 변동 시 알림을 보내는 서비스.
**현재 개발 보류 중** — GDS 접근 불가로 인한 데이터 품질 한계. 자세한 내용은 README.ko.md 참고.

---

## 브랜치 / 커밋 / PR 규칙

- 항상 feature 브랜치에서 작업 → PR → main 머지
- 브랜치 네이밍: `feat/xxx`, `fix/xxx`, `docs/xxx`
- 커밋은 작업 단위마다 그때그때 (모아서 한 번에 X)
- main 브랜치는 보호되어 있어 직접 push 불가, PR 필수
- 툴 실행 전 한국어로 무엇을 하려는지 설명할 것

---

## 로컬 실행

### 백엔드

```bash
cd infra
docker compose up -d --build   # 코드 변경 후 반드시 --build
docker compose down            # 종료
docker compose logs api --tail=30  # 로그 확인
```

- docker-compose.yml 위치: `infra/docker-compose.yml` (루트 아님)
- API 서버: http://localhost:8000
- API 문서: http://localhost:8000/docs

### Flutter

```bash
cd mobile
flutter run -d chrome
# 실행 중 r → 핫리로드
# 실행 중 q → 종료
```

### 테스트

```bash
# 백엔드
cd backend && pytest

# Flutter
cd mobile && flutter test test/date_pair_test.dart
```

---

## 환경 변수

`backend/.env` 파일 필요:

```
DATABASE_URL=postgresql://...
SERPAPI_KEY=...
SECRET_KEY=...
```

Firebase, SendGrid는 API 키 미설정 상태 (구조만 구현됨).

---

## 디렉터리 구조 핵심

```
farebird/
├── backend/app/
│   ├── api/v1/routes/     # auth.py, flights.py, watch.py
│   ├── services/          # flight_service.py (SerpAPI 호출)
│   │                      # notification_service.py
│   ├── models/            # SQLAlchemy (user, watched_route)
│   └── schemas/           # flight.py (FlightItinerary 등)
├── mobile/lib/
│   ├── screens/search/    # search_screen.dart (검색 UI 핵심)
│   ├── models/            # flight.dart
│   └── services/          # api_service.dart, auth_service.dart
└── infra/
    └── docker-compose.yml
```

---

## 현재 구현 상태

### 완료
- 회원가입/로그인 (JWT)
- 항공권 검색 (날짜 쌍 방식, SerpAPI)
- 검색 결과: 가는편/오는편 항공사·시각·가격 표시
- 결과 탭 → Kayak 연결
- 모니터링 노선 등록/목록/삭제
- 가격 모니터링 스케줄러 구조
- 알림 서비스 구조 (Firebase, SendGrid)
- DB 마이그레이션 (Alembic)

### 미완료 (보류 사유와 관계없이)
- Firebase 실제 푸시 알림 (FCM credentials 미설정)
- SendGrid 실제 이메일 발송 (API 키 미설정)
- 배포 (Oracle Cloud Free Tier)

### 보류 사유
- SerpAPI는 혼합 항공사(A출발+B귀국) 조합을 잘 반환하지 않음
- 개인/소규모가 한국·일본에서 접근 가능한 GDS 대안 없음
  - Amadeus: 신규 가입 종료
  - Duffel: 한국/일본 미지원
  - Kiwi Tequila: 신규 가입 종료

---

## 재개 시작점

GDS 접근 가능한 API가 생겼을 때:
1. `flight_service.py` 교체 (SerpAPI → 새 API)
2. `FlightItinerary` 스키마 조정 필요 시 수정
3. 출발편 선택 → 귀국편 선택 UX 구현 (현재는 쌍을 미리 지정)

그 외 이어서 할 작업:
1. Firebase/SendGrid API 키 설정 후 실제 알림 테스트
2. Oracle Cloud 배포

---

## 주의사항

- 백엔드 코드 변경 후 반드시 `docker compose up -d --build` (--build 없으면 반영 안 됨)
- SerpAPI 무료 플랜 250크레딧/월 — 귀국편 시각 조회 시 결과 수 × 2크레딧 소모
- 기능 추가/수정 시 유닛테스트 필수 작성
