import 'package:flutter_test/flutter_test.dart';
import 'package:farebird/models/flight.dart';

void main() {
  group('FlightItinerary - booking URL', () {
    test('booking_url이 있으면 정상적으로 파싱됨', () {
      final flight = FlightItinerary.fromJson({
        'depart_date': '2026-06-01',
        'return_date': '2026-06-10',
        'airline': '대한항공',
        'price': 350000,
        'currency': 'KRW',
        'stops_outbound': 0,
        'booking_url': 'https://www.google.com/flights',
      });

      expect(flight.bookingUrl, 'https://www.google.com/flights');
      expect(Uri.parse(flight.bookingUrl!).isAbsolute, isTrue);
    });

    test('booking_url이 없으면 null', () {
      final flight = FlightItinerary.fromJson({
        'depart_date': '2026-06-01',
        'return_date': '2026-06-10',
        'airline': '아시아나',
        'price': 300000,
        'currency': 'KRW',
        'stops_outbound': 0,
        'booking_url': null,
      });

      expect(flight.bookingUrl, isNull);
    });

    test('booking_url이 있는 경우 hasUrl 조건이 true', () {
      final flight = FlightItinerary(
        departDate: '2026-06-01',
        returnDate: '2026-06-10',
        airline: '제주항공',
        price: 200000,
        currency: 'KRW',
        bookingUrl: 'https://www.google.com/flights',
      );

      final hasUrl = flight.bookingUrl != null && flight.bookingUrl!.isNotEmpty;
      expect(hasUrl, isTrue);
    });

    test('booking_url이 없는 경우 hasUrl 조건이 false', () {
      final flight = FlightItinerary(
        departDate: '2026-06-01',
        returnDate: '2026-06-10',
        airline: '티웨이',
        price: 180000,
        currency: 'KRW',
        bookingUrl: null,
      );

      final hasUrl = flight.bookingUrl != null && flight.bookingUrl!.isNotEmpty;
      expect(hasUrl, isFalse);
    });

    test('booking_url이 유효한 URI로 파싱됨', () {
      const url = 'https://www.google.com/flights?hl=ko';
      final uri = Uri.parse(url);

      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.isAbsolute, isTrue);
    });
  });
}
