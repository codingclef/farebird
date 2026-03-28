[한국어](README.ko.md) | **[日本語]** | [English](README.md)

---

# FareBird

複数の日程の組み合わせで航空券の価格を一度に比較し、価格変動を通知するサービス。

> **現在の状態**: 開発保留中。航空データAPIのアクセス制限によるデータ品質の限界を確認後、中断。
> 詳細は[限界と保留理由](#限界と保留理由)を参照。

---

## 作ろうとした理由

Skyscannerで複数の日程の航空券価格を比較するには、タブを複数開いて一つずつ確認する必要がある。これを一画面で表示し、価格が下がったら自動で通知するサービスを作りたかった。

---

## 実装済み機能

### バックエンド (FastAPI)
- 会員登録 / ログイン (JWT認証)
- 航空券検索API — 出発・帰国日ペアの複数指定、価格順ソート
- モニタリング路線の登録 / 一覧 / 削除
- 価格モニタリングスケジューラー (APScheduler、定期的な価格チェック)
- 通知サービス構造 (Firebase プッシュ / SendGrid メール) — APIキー未設定

### モバイル (Flutter Web)
- 空港オートコンプリート検索 (国内外の主要空港)
- 日程ペア選択カレンダーUX (出発日選択 → 帰国日選択 → ペア確定)
- 検索結果: 往路/復路の航空会社名・出発/到着時刻・価格・乗り継ぎ有無
- 結果タップでKayakに遷移 (該当路線・日程で検索)
- モニタリング路線管理画面

---

## システム構成

```
Flutter アプリ
    │
    ▼ HTTP (Dio)
FastAPI バックエンド (Docker)
    │
    ├── SerpAPI ──► Google Flights スクレイピング ──► 航空券価格・時刻
    ├── PostgreSQL ──► ユーザー、モニタリング路線の保存
    └── APScheduler ──► 定期的な価格チェック → 通知送信
```

### APIエンドポイント

| メソッド | パス | 説明 |
|---------|------|------|
| POST | `/api/v1/auth/signup` | 会員登録 |
| POST | `/api/v1/auth/login` | ログイン (JWT発行) |
| POST | `/api/v1/flights/search` | 航空券検索 |
| POST | `/api/v1/watch/` | モニタリング路線登録 |
| GET | `/api/v1/watch/user/{user_id}` | モニタリング路線一覧 |
| DELETE | `/api/v1/watch/{route_id}` | モニタリング路線削除 |

### 検索リクエスト構造

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

## 技術スタック

| 領域 | 技術 |
|------|------|
| バックエンド | Python 3.12, FastAPI, SQLAlchemy, Alembic, APScheduler |
| モバイル | Flutter (Web基準で開発、iOS/Android対応可能) |
| データベース | PostgreSQL 16 |
| フライトデータ | SerpAPI (Google Flights スクレイピング) |
| プッシュ通知 | Firebase Cloud Messaging (構造のみ実装) |
| メール | SendGrid (構造のみ実装) |
| インフラ | Docker Compose |
| 予定デプロイ | Oracle Cloud Free Tier |

---

## ローカル開発環境

### 必要なもの
- Docker Desktop
- Flutter SDK
- SerpAPI キー (`backend/.env`)

### バックエンド起動

```bash
cd infra
docker compose up -d --build
```

APIサーバー: http://localhost:8000
APIドキュメント: http://localhost:8000/docs

### Flutter起動

```bash
cd mobile
flutter run -d chrome
```

---

## ディレクトリ構成

```
farebird/
├── backend/
│   ├── app/
│   │   ├── api/v1/routes/   # auth, flights, watch
│   │   ├── core/            # 設定、DB接続
│   │   ├── models/          # SQLAlchemyモデル
│   │   ├── schemas/         # Pydanticスキーマ
│   │   └── services/        # flight_service, notification_service
│   ├── alembic/             # DBマイグレーション
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

## 限界と保留理由

### データ品質の問題
SerpAPIはGDSデータに直接アクセスするのではなく、Google Flightsをスクレイピングする方式のため、実際のデータとの差異がある。

- **混合航空会社の組み合わせ不足**: 最安値はA航空会社往路＋B航空会社復路の組み合わせが多いが、SerpAPIは同一航空会社の往復を中心に返す
- **価格データの欠落**: 無料プランでは一部の結果が0円で返される（現在はフィルタリング処理済み）
- **クレジット消費**: 復路の時刻取得のため、検索1回につきSerpAPI2回の呼び出しが必要

### GDSアクセス不可
日本・韓国を拠点とする個人・小規模開発者がGDSデータにアクセスできる現実的な方法がない。

| サービス | 状況 |
|---------|------|
| Amadeus | 新規登録終了 |
| Duffel | 日本・韓国非対応 |
| Kiwi Tequila | 新規登録終了 |
| Sabre / Travelport | エンタープライズ専用 |

アクセス可能なGDS代替手段が登場した場合、開発を再開予定。
