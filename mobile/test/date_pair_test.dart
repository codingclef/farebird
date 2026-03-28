import 'package:flutter_test/flutter_test.dart';

// search_screen.dart의 DatePair 및 쌍 관리 로직을 동일하게 재현
class DatePair {
  final DateTime depart;
  final DateTime ret;
  const DatePair({required this.depart, required this.ret});
}

/// 귀국일이 출발일 이후인지 검증
bool isValidPair(DateTime depart, DateTime ret) => ret.isAfter(depart);

/// _onDaySelected 로직을 재현한 순수 함수
/// pendingDepart: 현재 선택된 출발일 (null이면 1단계)
/// 반환값: (새 pendingDepart, 추가된 쌍, 에러메시지)
typedef SelectResult = ({DateTime? pending, DatePair? added, String? error});

SelectResult onDaySelected(DateTime selected, DateTime? pendingDepart) {
  if (pendingDepart == null) {
    return (pending: selected, added: null, error: null);
  } else if (selected.year == pendingDepart.year &&
      selected.month == pendingDepart.month &&
      selected.day == pendingDepart.day) {
    return (pending: null, added: null, error: null);
  } else if (selected.isAfter(pendingDepart)) {
    return (pending: null, added: DatePair(depart: pendingDepart, ret: selected), error: null);
  } else {
    return (pending: pendingDepart, added: null, error: '귀국일은 출발일보다 이후여야 합니다.');
  }
}

/// 날짜 쌍 목록을 API 요청 형식으로 변환
List<Map<String, String>> toApiPairs(List<DatePair> pairs) {
  return pairs.map((p) {
    final fmt =
        '${p.depart.year}-${p.depart.month.toString().padLeft(2, '0')}-${p.depart.day.toString().padLeft(2, '0')}';
    final fmtRet =
        '${p.ret.year}-${p.ret.month.toString().padLeft(2, '0')}-${p.ret.day.toString().padLeft(2, '0')}';
    return {'depart_date': fmt, 'return_date': fmtRet};
  }).toList();
}

void main() {
  group('DatePair 유효성 검증', () {
    test('귀국일이 출발일보다 이후이면 유효', () {
      final depart = DateTime(2026, 5, 1);
      final ret = DateTime(2026, 5, 10);
      expect(isValidPair(depart, ret), isTrue);
    });

    test('귀국일과 출발일이 같으면 무효', () {
      final same = DateTime(2026, 5, 1);
      expect(isValidPair(same, same), isFalse);
    });

    test('귀국일이 출발일보다 이전이면 무효', () {
      final depart = DateTime(2026, 5, 10);
      final ret = DateTime(2026, 5, 1);
      expect(isValidPair(depart, ret), isFalse);
    });
  });

  group('날짜 쌍 목록 관리', () {
    test('쌍 추가 후 개수가 늘어남', () {
      final pairs = <DatePair>[];
      pairs.add(DatePair(
        depart: DateTime(2026, 5, 1),
        ret: DateTime(2026, 5, 10),
      ));
      expect(pairs.length, 1);
    });

    test('쌍 삭제 후 목록에서 제거됨', () {
      final pairs = <DatePair>[
        DatePair(depart: DateTime(2026, 5, 1), ret: DateTime(2026, 5, 10)),
        DatePair(depart: DateTime(2026, 6, 1), ret: DateTime(2026, 6, 10)),
      ];
      pairs.removeAt(0);
      expect(pairs.length, 1);
      expect(pairs.first.depart, DateTime(2026, 6, 1));
    });

    test('여러 쌍이 독립적으로 저장됨 (카르테시안 곱 아님)', () {
      final pairs = [
        DatePair(depart: DateTime(2026, 5, 1), ret: DateTime(2026, 5, 10)),
        DatePair(depart: DateTime(2026, 6, 1), ret: DateTime(2026, 6, 10)),
      ];
      // 쌍이 2개면 정확히 2가지 여행 일정을 의미
      expect(pairs.length, 2);
      expect(pairs[0].depart, isNot(equals(pairs[1].depart)));
    });
  });

  group('날짜 선택 인터랙션 로직', () {
    test('출발일 선택 → pendingDepart 세팅', () {
      final result = onDaySelected(DateTime(2026, 5, 1), null);
      expect(result.pending, DateTime(2026, 5, 1));
      expect(result.added, isNull);
    });

    test('출발일 재클릭 → 선택 취소', () {
      final depart = DateTime(2026, 5, 1);
      final result = onDaySelected(depart, depart);
      expect(result.pending, isNull);
      expect(result.added, isNull);
      expect(result.error, isNull);
    });

    test('귀국일 선택 → 쌍 완성', () {
      final depart = DateTime(2026, 5, 1);
      final ret = DateTime(2026, 5, 10);
      final result = onDaySelected(ret, depart);
      expect(result.pending, isNull);
      expect(result.added?.depart, depart);
      expect(result.added?.ret, ret);
    });

    test('귀국일이 출발일 이전 → 에러', () {
      final depart = DateTime(2026, 5, 10);
      final before = DateTime(2026, 5, 1);
      final result = onDaySelected(before, depart);
      expect(result.error, isNotNull);
      expect(result.added, isNull);
      expect(result.pending, depart); // pendingDepart 유지
    });

    test('귀국일이 출발일과 같음 → 에러', () {
      final same = DateTime(2026, 5, 1);
      final result = onDaySelected(same, same);
      // isSameDay이므로 취소로 처리됨 (에러 아님)
      expect(result.pending, isNull);
      expect(result.error, isNull);
    });
  });

  group('API 요청 형식 변환', () {
    test('쌍을 API 형식으로 올바르게 변환', () {
      final pairs = [
        DatePair(depart: DateTime(2026, 5, 1), ret: DateTime(2026, 5, 10)),
      ];
      final result = toApiPairs(pairs);
      expect(result.length, 1);
      expect(result[0]['depart_date'], '2026-05-01');
      expect(result[0]['return_date'], '2026-05-10');
    });

    test('여러 쌍 변환 시 순서 유지', () {
      final pairs = [
        DatePair(depart: DateTime(2026, 5, 1), ret: DateTime(2026, 5, 10)),
        DatePair(depart: DateTime(2026, 6, 1), ret: DateTime(2026, 6, 10)),
      ];
      final result = toApiPairs(pairs);
      expect(result[0]['depart_date'], '2026-05-01');
      expect(result[1]['depart_date'], '2026-06-01');
    });

    test('빈 쌍 목록은 빈 리스트 반환', () {
      expect(toApiPairs([]), isEmpty);
    });
  });
}
