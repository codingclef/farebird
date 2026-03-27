[한국어](README.ko.md) | [日本語](README.ja.md) | **[English]**

---

# FareBird

Flight price tracking and alert service.

## Features

- Search round-trip flights with multiple departure and return dates
- View airline, booking source, price, and flight details
- Periodic price monitoring with alerts when prices drop (push / email)
- Airline special fare announcements

## Tech Stack

| Area | Technology |
|------|------------|
| Backend | Python, FastAPI, SQLAlchemy, APScheduler |
| Mobile | Flutter (iOS / Android / Web) |
| Database | PostgreSQL |
| Flight Data | SerpApi (Google Flights) |
| Push Notifications | Firebase Cloud Messaging |
| Email | SendGrid |
| Infrastructure | Docker, Oracle Cloud Free Tier |

## Local Development

```bash
cd infra
docker-compose up -d
```

API server: http://localhost:8000
API docs: http://localhost:8000/docs
