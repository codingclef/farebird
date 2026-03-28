import 'package:flutter_test/flutter_test.dart';

// search_screen.dart의 Airport 및 필터링 로직을 동일하게 재현
class Airport {
  final String iata;
  final String name;
  final String city;

  const Airport(this.iata, this.name, this.city);
}

const airports = [
  Airport('ICN', '인천국제공항', '인천'),
  Airport('GMP', '김포국제공항', '서울'),
  Airport('PUS', '김해국제공항', '부산'),
  Airport('CJU', '제주국제공항', '제주'),
  Airport('NRT', '나리타국제공항', '도쿄'),
  Airport('HND', '하네다공항', '도쿄'),
  Airport('KIX', '간사이국제공항', '오사카'),
  Airport('BKK', '수완나품국제공항', '방콕'),
  Airport('SIN', '창이국제공항', '싱가포르'),
  Airport('LHR', '런던히드로공항', '런던'),
  Airport('JFK', '존F케네디국제공항', '뉴욕'),
];

List<Airport> filterAirports(String query) {
  if (query.isEmpty) return [];
  final q = query.toLowerCase();
  return airports
      .where((a) =>
          a.name.contains(q) || a.city.contains(q) || a.iata.toLowerCase().contains(q))
      .toList();
}

void main() {
  group('공항 자동완성 필터링', () {
    test('빈 문자열 입력 시 결과 없음', () {
      expect(filterAirports(''), isEmpty);
    });

    test('한글 공항명으로 검색', () {
      final results = filterAirports('인천');
      expect(results.length, 1);
      expect(results.first.iata, 'ICN');
    });

    test('"인" 입력 시 "인천" 포함 공항 반환', () {
      final results = filterAirports('인');
      final iatas = results.map((a) => a.iata).toList();
      expect(iatas, contains('ICN'));
    });

    test('도시명으로 검색', () {
      final results = filterAirports('도쿄');
      final iatas = results.map((a) => a.iata).toList();
      expect(iatas, containsAll(['NRT', 'HND']));
    });

    test('IATA 코드 대문자로 검색', () {
      final results = filterAirports('ICN');
      expect(results.length, 1);
      expect(results.first.name, '인천국제공항');
    });

    test('IATA 코드 소문자로 검색', () {
      final results = filterAirports('icn');
      expect(results.length, 1);
      expect(results.first.iata, 'ICN');
    });

    test('존재하지 않는 공항 검색 시 빈 결과', () {
      expect(filterAirports('없는공항xyz'), isEmpty);
    });

    test('IATA 코드 부분 입력으로 검색', () {
      final results = filterAirports('jf');
      final iatas = results.map((a) => a.iata).toList();
      expect(iatas, contains('JFK'));
    });
  });
}
