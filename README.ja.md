# FareBird

> **Language / 언어 / 言語**
> [English](README.md) · [한국어](README.ko.md) · [日本語](#farebird)

---

航空券の価格追跡・アラートサービス。

## 主な機能

- 出発日・帰国日を複数指定して航空券の価格を比較
- 航空会社、予約サイト、価格、フライト詳細を表示
- 定期的な価格モニタリングと値下がりアラート（プッシュ通知 / メール）
- 航空会社のセール情報のお知らせ

## 技術スタック

| 領域 | 技術 |
|------|------|
| バックエンド | Python, FastAPI, SQLAlchemy, APScheduler |
| モバイル | Flutter (iOS / Android / Web) |
| データベース | PostgreSQL |
| フライトデータ | SerpApi (Google Flights) |
| プッシュ通知 | Firebase Cloud Messaging |
| メール | SendGrid |
| インフラ | Docker, Oracle Cloud Free Tier |

## ローカル開発環境

```bash
cd infra
docker-compose up -d
```

APIサーバー: http://localhost:8000
APIドキュメント: http://localhost:8000/docs
