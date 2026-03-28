[한국어](README.ko.md) | [日本語](README.ja.md) | **[English]**

---

# FareBird

A service that compares flight prices across multiple date combinations at once and sends alerts when prices drop.

> **Current status**: Development on hold. Suspended after identifying data quality limitations due to flight API access restrictions.
> See [Limitations & Reason for Hold](#limitations--reason-for-hold) for details.

---

## Motivation

Comparing flight prices across multiple dates on Skyscanner requires opening multiple tabs and checking each one manually. FareBird aims to show all combinations on a single screen and automatically notify users when prices drop.

---

## Implemented Features

### Backend (FastAPI)
- Sign up / Login (JWT authentication)
- Flight search API — multiple outbound-return date pairs, sorted by price
- Route monitoring — add / list / delete watched routes
- Price monitoring scheduler (APScheduler, periodic price checks)
- Notification service structure (Firebase push / SendGrid email) — API keys not configured

### Mobile (Flutter Web)
- Airport autocomplete search (major domestic and international airports)
- Date pair selection UX (select departure → select return → pair confirmed)
- Search results: airline name, departure/arrival times for both legs, price, stop count
- Tap result to open Kayak with matching route and dates
- Route monitoring management screen

---

## System Architecture

```
Flutter App
    │
    ▼ HTTP (Dio)
FastAPI Backend (Docker)
    │
    ├── SerpAPI ──► Google Flights scraping ──► flight prices / times
    ├── PostgreSQL ──► users, monitored routes
    └── APScheduler ──► periodic price check → send alerts
```

### API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/auth/signup` | Sign up |
| POST | `/api/v1/auth/login` | Login (issue JWT) |
| POST | `/api/v1/flights/search` | Search flights |
| POST | `/api/v1/watch/` | Add monitored route |
| GET | `/api/v1/watch/user/{user_id}` | List monitored routes |
| DELETE | `/api/v1/watch/{route_id}` | Delete monitored route |

### Search Request Structure

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

## Tech Stack

| Area | Technology |
|------|------------|
| Backend | Python 3.12, FastAPI, SQLAlchemy, Alembic, APScheduler |
| Mobile | Flutter (developed on Web, supports iOS/Android) |
| Database | PostgreSQL 16 |
| Flight Data | SerpAPI (Google Flights scraping) |
| Push Notifications | Firebase Cloud Messaging (structure only) |
| Email | SendGrid (structure only) |
| Infrastructure | Docker Compose |
| Planned Deployment | Oracle Cloud Free Tier |

---

## Local Development

### Prerequisites
- Docker Desktop
- Flutter SDK
- SerpAPI key (`backend/.env`)

### Run Backend

```bash
cd infra
docker compose up -d --build
```

API server: http://localhost:8000
API docs: http://localhost:8000/docs

### Run Flutter

```bash
cd mobile
flutter run -d chrome
```

---

## Directory Structure

```
farebird/
├── backend/
│   ├── app/
│   │   ├── api/v1/routes/   # auth, flights, watch
│   │   ├── core/            # config, DB connection
│   │   ├── models/          # SQLAlchemy models
│   │   ├── schemas/         # Pydantic schemas
│   │   └── services/        # flight_service, notification_service
│   ├── alembic/             # DB migrations
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

## Limitations & Reason for Hold

### Data Quality Issues
SerpAPI scrapes Google Flights rather than accessing real GDS data, resulting in notable gaps.

- **Lack of mixed-carrier combinations**: The cheapest fares often involve airline A outbound + airline B return, but SerpAPI primarily returns same-carrier round trips
- **Missing price data**: Some results return a price of 0 on the free plan (filtered out in current implementation)
- **Credit consumption**: Fetching return flight times requires 2 SerpAPI calls per search result

### No GDS Access
There is currently no realistic way for individual developers based in Japan or South Korea to access GDS data.

| Service | Status |
|---------|--------|
| Amadeus | No longer accepting new signups |
| Duffel | Does not support Japan / South Korea |
| Kiwi Tequila | No longer accepting new signups |
| Sabre / Travelport | Enterprise only |

Development will resume if an accessible GDS alternative becomes available.
