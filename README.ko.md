**[한국어]** | [日本語](README.ja.md) | [English](README.md)

---

# FareBird

여러 날짜 조합의 항공권 가격을 한 번에 비교하고, 가격 변동을 모니터링해서 알림을 보내는 서비스.

> **현재 상태**: 개발 보류 중. 항공 데이터 API 접근 제한으로 인해 데이터 품질 한계 확인 후 중단.
> 상세 내용은 [한계 및 보류 사유](#한계-및-보류-사유) 참고.

---

## 만들려고 했던 이유

스카이스캐너에서 여러 날짜의 항공권 가격을 비교하려면 탭을 여러 개 열어서 일일이 확인해야 한다. 이걸 한 화면에서 보여주고, 가격이 떨어지면 자동으로 알려주는 서비스를 만들고자 했다.

---

## 구현된 기능

### 백엔드 (FastAPI)
- 회원가입 / 로그인 (JWT 인증)
- 항공권 검색 API — 출발-귀국 날짜 쌍 복수 지정, 가격순 정렬
- 모니터링 노선 등록 / 목록 조회 / 삭제
- 가격 모니터링 스케줄러 (APScheduler, 주기적 가격 체크)
- 알림 서비스 구조 (Firebase 푸시 / SendGrid 이메일) — API 키 미설정

### 모바일 (Flutter Web)
- 공항 자동완성 검색 (국내외 주요 공항)
- 날짜 쌍 선택 달력 UX (출발일 선택 → 귀국일 선택 → 쌍 완성)
- 검색 결과: 가는편/오는편 항공사명, 출발/도착 시각, 가격, 직항 여부
- 결과 탭 시 Kayak으로 이동 (해당 노선/날짜 검색)
- 모니터링 노선 관리 화면

---

## 시스템 구조

```
Flutter 앱
    │
    ▼ HTTP (Dio)
FastAPI 백엔드 (Docker)
    │
    ├── SerpAPI ──► Google Flights 스크래핑 ──► 항공권 가격/시각
    ├── PostgreSQL ──► 사용자, 모니터링 노선 저장
    └── APScheduler ──► 주기적 가격 체크 → 알림 전송
```

### API 엔드포인트

| 메서드 | 경로 | 설명 |
|--------|------|------|
| POST | `/api/v1/auth/signup` | 회원가입 |
| POST | `/api/v1/auth/login` | 로그인 (JWT 발급) |
| POST | `/api/v1/flights/search` | 항공권 검색 |
| POST | `/api/v1/watch/` | 모니터링 노선 등록 |
| GET | `/api/v1/watch/user/{user_id}` | 모니터링 노선 목록 |
| DELETE | `/api/v1/watch/{route_id}` | 모니터링 노선 삭제 |

### 검색 요청 구조

```json
{
  "origin": "ICN",
  "destination": "NRT",
  "date_pairs": [
    { "depart_date": "2026-05-01", "return_date": "2026-05-10" },
    { "depart_date": "2026-05-08", "return_date": "2026-05-15" }
  ],
  "adults": 1,
  "currency": "KRW"
}
```

---

## 기술 스택

| 영역 | 기술 |
|------|------|
| 백엔드 | Python 3.12, FastAPI, SQLAlchemy, Alembic, APScheduler |
| 모바일 | Flutter (Web 기준 개발, iOS/Android 대응 가능) |
| 데이터베이스 | PostgreSQL 16 |
| 항공 데이터 | SerpAPI (Google Flights 스크래핑) |
| 푸시 알림 | Firebase Cloud Messaging (구조만 구현) |
| 이메일 | SendGrid (구조만 구현) |
| 인프라 | Docker Compose |
| 예정 배포 | Oracle Cloud Free Tier |

---

## 로컬 개발 환경

### 필요 사항
- Docker Desktop
- Flutter SDK
- SerpAPI 키 (`backend/.env`)

### 백엔드 실행

```bash
cd infra
docker compose up -d --build
```

API 서버: http://localhost:8000
API 문서: http://localhost:8000/docs

### Flutter 실행

```bash
cd mobile
flutter run -d chrome
```

---

## 디렉터리 구조

```
farebird/
├── backend/
│   ├── app/
│   │   ├── api/v1/routes/   # auth, flights, watch
│   │   ├── core/            # 설정, DB 연결
│   │   ├── models/          # SQLAlchemy 모델
│   │   ├── schemas/         # Pydantic 스키마
│   │   └── services/        # flight_service, notification_service
│   ├── alembic/             # DB 마이그레이션
│   └── tests/
├── mobile/
│   ├── lib/
│   │   ├── models/          # FlightItinerary, WatchedRoute
│   │   ├── screens/         # search, monitor, settings
│   │   └── services/        # api_service, auth_service
│   └── test/
└── infra/
    └── docker-compose.yml
```

---

## 한계 및 보류 사유

### 데이터 품질 문제
SerpAPI는 Google Flights를 스크래핑하는 방식으로, 실제 GDS(Global Distribution System) 데이터와 차이가 있다.

- **혼합 항공사 조합 부족**: 실제 최저가는 A항공사 출발 + B항공사 귀국 조합인 경우가 많은데, SerpAPI는 같은 항공사 왕복 위주로 반환함
- **가격 데이터 누락**: 무료 플랜에서 일부 결과 가격이 0원으로 반환됨 (필터링 처리)
- **크레딧 소모**: 오는편 시각 조회를 위해 검색 1회당 SerpAPI 2회 호출 필요

### GDS 접근 불가
개인/소규모 개발자가 한국/일본에서 GDS 데이터에 접근할 수 있는 현실적인 방법이 없음.

| 서비스 | 상태 |
|--------|------|
| Amadeus | 신규 가입 종료 |
| Duffel | 한국/일본 미지원 |
| Kiwi Tequila | 신규 가입 종료 |
| Sabre/Travelport | 엔터프라이즈 전용 |

접근 가능한 GDS 대안이 생기면 재개 예정.
