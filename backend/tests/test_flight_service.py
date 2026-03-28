"""flight_service.py 유닛 테스트 — SerpAPI 호출은 mock 처리"""
from datetime import date, timedelta
from unittest.mock import patch

import pytest
from fastapi import HTTPException

from app.schemas.flight import DatePair, FlightSearchRequest
from app.services.flight_service import search_flights


def _future(days: int) -> str:
    return (date.today() + timedelta(days=days)).isoformat()


def _make_req(**kwargs) -> FlightSearchRequest:
    defaults = dict(
        origin="ICN",
        destination="NRT",
        date_pairs=[DatePair(depart_date=_future(10), return_date=_future(15))],
    )
    defaults.update(kwargs)
    return FlightSearchRequest(**defaults)


MOCK_SERPAPI_RESULT = {
    "best_flights": [
        {
            "flights": [{"airline": "대한항공"}],
            "price": 300000,
            "total_duration": 90,
        }
    ],
    "other_flights": [],
}


class TestSearchFlights:
    def test_single_pair_returns_results(self):
        with patch("app.services.flight_service.GoogleSearch") as mock_gs:
            mock_gs.return_value.get_dict.return_value = MOCK_SERPAPI_RESULT
            req = _make_req()
            res = search_flights(req)

        assert res.total_combinations == 1
        assert len(res.results) == 1
        assert res.results[0].airline == "대한항공"
        assert res.results[0].price == 300000

    def test_multiple_pairs_each_searched_independently(self):
        """쌍이 2개면 SerpAPI를 정확히 2번 호출해야 함 (카르테시안 곱 아님)"""
        with patch("app.services.flight_service.GoogleSearch") as mock_gs:
            mock_gs.return_value.get_dict.return_value = MOCK_SERPAPI_RESULT
            req = _make_req(
                date_pairs=[
                    DatePair(depart_date=_future(10), return_date=_future(15)),
                    DatePair(depart_date=_future(20), return_date=_future(25)),
                ]
            )
            res = search_flights(req)

        assert mock_gs.call_count == 2
        assert res.total_combinations == 2

    def test_results_sorted_by_price(self):
        cheap = {
            "flights": [{"airline": "저가항공"}],
            "price": 100000,
            "total_duration": 90,
        }
        expensive = {
            "flights": [{"airline": "대한항공"}],
            "price": 500000,
            "total_duration": 90,
        }
        serpapi_result = {"best_flights": [expensive, cheap], "other_flights": []}

        with patch("app.services.flight_service.GoogleSearch") as mock_gs:
            mock_gs.return_value.get_dict.return_value = serpapi_result
            req = _make_req()
            res = search_flights(req)

        assert res.results[0].price == 100000
        assert res.results[1].price == 500000

    def test_return_date_before_depart_raises_400(self):
        req = _make_req(
            date_pairs=[
                DatePair(depart_date=_future(15), return_date=_future(10))
            ]
        )
        with pytest.raises(HTTPException) as exc:
            search_flights(req)
        assert exc.value.status_code == 400

    def test_past_depart_date_raises_400(self):
        past = (date.today() - timedelta(days=1)).isoformat()
        req = _make_req(
            date_pairs=[DatePair(depart_date=past, return_date=_future(5))]
        )
        with pytest.raises(HTTPException) as exc:
            search_flights(req)
        assert exc.value.status_code == 400

    def test_past_return_date_raises_400(self):
        past = (date.today() - timedelta(days=1)).isoformat()
        req = _make_req(
            date_pairs=[DatePair(depart_date=_future(5), return_date=past)]
        )
        with pytest.raises(HTTPException) as exc:
            search_flights(req)
        assert exc.value.status_code == 400

    def test_same_depart_and_return_date_raises_400(self):
        same = _future(10)
        req = _make_req(
            date_pairs=[DatePair(depart_date=same, return_date=same)]
        )
        with pytest.raises(HTTPException) as exc:
            search_flights(req)
        assert exc.value.status_code == 400
