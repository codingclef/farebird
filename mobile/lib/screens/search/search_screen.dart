import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/flight.dart';
import '../../services/api_service.dart';

final _apiService = ApiService();

class Airport {
  final String iata;
  final String name;
  final String city;

  const Airport(this.iata, this.name, this.city);
}

const _airports = [
  // 국내
  Airport('ICN', '인천국제공항', '인천'),
  Airport('GMP', '김포국제공항', '서울'),
  Airport('PUS', '김해국제공항', '부산'),
  Airport('CJU', '제주국제공항', '제주'),
  Airport('TAE', '대구국제공항', '대구'),
  Airport('CJJ', '청주국제공항', '청주'),
  Airport('MWX', '무안국제공항', '무안'),
  Airport('KWJ', '광주공항', '광주'),
  Airport('RSU', '여수공항', '여수'),
  Airport('YNY', '양양국제공항', '양양'),
  // 일본
  Airport('NRT', '나리타국제공항', '도쿄'),
  Airport('HND', '하네다공항', '도쿄'),
  Airport('KIX', '간사이국제공항', '오사카'),
  Airport('ITM', '이타미공항', '오사카'),
  Airport('FUK', '후쿠오카공항', '후쿠오카'),
  Airport('OKA', '나하공항', '오키나와'),
  Airport('NGO', '주부국제공항', '나고야'),
  Airport('CTS', '신치토세공항', '삿포로'),
  Airport('HIJ', '히로시마공항', '히로시마'),
  Airport('SDJ', '센다이공항', '센다이'),
  // 중화권
  Airport('PEK', '베이징수도국제공항', '베이징'),
  Airport('PKX', '베이징다싱국제공항', '베이징'),
  Airport('PVG', '상하이푸동국제공항', '상하이'),
  Airport('SHA', '상하이홍차오공항', '상하이'),
  Airport('CAN', '광저우바이윈국제공항', '광저우'),
  Airport('HKG', '홍콩국제공항', '홍콩'),
  Airport('TPE', '타오위안국제공항', '타이베이'),
  Airport('TSA', '쑹산공항', '타이베이'),
  // 동남아
  Airport('BKK', '수완나품국제공항', '방콕'),
  Airport('DMK', '돈므앙국제공항', '방콕'),
  Airport('SIN', '창이국제공항', '싱가포르'),
  Airport('KUL', '쿠알라룸푸르국제공항', '쿠알라룸푸르'),
  Airport('MNL', '마닐라국제공항', '마닐라'),
  Airport('CEB', '막탄세부국제공항', '세부'),
  Airport('DPS', '응우라라이국제공항', '발리'),
  Airport('CGK', '수카르노하타국제공항', '자카르타'),
  Airport('HAN', '노이바이국제공항', '하노이'),
  Airport('SGN', '탄손녓국제공항', '호치민'),
  Airport('DAD', '다낭국제공항', '다낭'),
  // 유럽
  Airport('LHR', '런던히드로공항', '런던'),
  Airport('CDG', '파리샤를드골공항', '파리'),
  Airport('FRA', '프랑크푸르트공항', '프랑크푸르트'),
  Airport('AMS', '암스테르담스키폴공항', '암스테르담'),
  Airport('VIE', '빈국제공항', '빈'),
  Airport('ZRH', '취리히공항', '취리히'),
  Airport('FCO', '로마피우미치노공항', '로마'),
  Airport('BCN', '바르셀로나공항', '바르셀로나'),
  Airport('MAD', '마드리드바라하스공항', '마드리드'),
  Airport('IST', '이스탄불공항', '이스탄불'),
  // 미주
  Airport('JFK', '존F케네디국제공항', '뉴욕'),
  Airport('EWR', '뉴어크공항', '뉴욕'),
  Airport('LAX', '로스앤젤레스국제공항', '로스앤젤레스'),
  Airport('SFO', '샌프란시스코국제공항', '샌프란시스코'),
  Airport('ORD', '시카고오헤어국제공항', '시카고'),
  Airport('SEA', '시애틀타코마국제공항', '시애틀'),
  Airport('YVR', '밴쿠버국제공항', '밴쿠버'),
  Airport('YYZ', '토론토피어슨국제공항', '토론토'),
  // 오세아니아·기타
  Airport('SYD', '시드니국제공항', '시드니'),
  Airport('MEL', '멜버른공항', '멜버른'),
  Airport('AKL', '오클랜드국제공항', '오클랜드'),
  Airport('DXB', '두바이국제공항', '두바이'),
];

/// 출발일-귀국일 쌍
class DatePair {
  final DateTime depart;
  final DateTime ret;

  const DatePair({required this.depart, required this.ret});
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String? _origin;
  String? _destination;

  /// 확정된 날짜 쌍 목록
  final List<DatePair> _datePairs = [];

  /// 현재 입력 중인 출발일 (귀국일 선택 대기 중)
  DateTime? _pendingDepart;

  List<FlightItinerary> _results = [];
  bool _loading = false;
  String? _error;

  bool get _isSelectingReturn => _pendingDepart != null;

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      if (!_isSelectingReturn) {
        // 1단계: 출발일 선택
        _pendingDepart = selected;
      } else {
        // 2단계: 귀국일 선택
        if (selected.isAfter(_pendingDepart!)) {
          _datePairs.add(DatePair(depart: _pendingDepart!, ret: selected));
          _pendingDepart = null;
        } else {
          _error = '귀국일은 출발일보다 이후여야 합니다.';
        }
      }
    });
  }

  void _removePair(int index) {
    setState(() => _datePairs.removeAt(index));
  }

  void _cancelPending() {
    setState(() => _pendingDepart = null);
  }

  Future<void> _search() async {
    if (_origin == null || _destination == null || _datePairs.isEmpty) {
      setState(() => _error = '출발지, 도착지, 날짜를 모두 선택해주세요.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final fmt = DateFormat('yyyy-MM-dd');
      final pairs = _datePairs
          .map((p) => {
                'depart_date': fmt.format(p.depart),
                'return_date': fmt.format(p.ret),
              })
          .toList();

      final data = await _apiService.searchFlights(
        origin: _origin!,
        destination: _destination!,
        datePairs: pairs,
      );
      setState(() {
        _results = (data['results'] as List)
            .map((e) => FlightItinerary.fromJson(e))
            .toList();
      });
    } catch (e) {
      setState(() => _error = '검색 중 오류가 발생했습니다.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('항공권 검색')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _AirportAutocomplete(
                        label: '출발',
                        onSelected: (iata) => setState(() => _origin = iata),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AirportAutocomplete(
                        label: '도착',
                        onSelected: (iata) =>
                            setState(() => _destination = iata),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 달력 안내 문구
                _buildCalendarGuide(),

                TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _pendingDepart ?? DateTime.now(),
                  selectedDayPredicate: (day) {
                    if (_pendingDepart != null && isSameDay(day, _pendingDepart!)) {
                      return true;
                    }
                    return _datePairs.any(
                        (p) => isSameDay(day, p.depart) || isSameDay(day, p.ret));
                  },
                  calendarBuilders: CalendarBuilders(
                    selectedBuilder: (context, day, focusedDay) {
                      // 출발일: 파란색, 귀국일: 초록색, pendingDepart: 주황색
                      Color color = const Color(0xFF1A73E8);
                      if (_pendingDepart != null && isSameDay(day, _pendingDepart!)) {
                        color = Colors.orange;
                      } else {
                        final isReturn = _datePairs.any((p) => isSameDay(day, p.ret));
                        if (isReturn) color = Colors.green;
                      }
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                  onDaySelected: _onDaySelected,
                  calendarFormat: CalendarFormat.month,
                  headerStyle: const HeaderStyle(formatButtonVisible: false),
                ),

                // 선택된 날짜 쌍 목록
                if (_datePairs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (int i = 0; i < _datePairs.length; i++)
                        _DatePairChip(
                          pair: _datePairs[i],
                          onRemove: () => _removePair(i),
                        ),
                    ],
                  ),
                ],

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _search,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('검색'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildCalendarGuide() {
    if (!_isSelectingReturn) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A73E8).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.flight_takeoff, size: 16, color: Color(0xFF1A73E8)),
            SizedBox(width: 8),
            Text('출발일을 선택하세요',
                style: TextStyle(
                    color: Color(0xFF1A73E8), fontWeight: FontWeight.w500)),
          ],
        ),
      );
    } else {
      final fmt = DateFormat('M/d');
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.flight_land, size: 16, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '귀국일을 선택하세요  (출발: ${fmt.format(_pendingDepart!)})',
                style: const TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.w500),
              ),
            ),
            GestureDetector(
              onTap: _cancelPending,
              child: const Icon(Icons.close, size: 16, color: Colors.orange),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return const Center(child: Text('검색 결과가 여기에 표시됩니다.'));
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final f = _results[index];
        final hasUrl = f.bookingUrl != null && f.bookingUrl!.isNotEmpty;
        return ListTile(
          leading: const Icon(Icons.flight),
          title: Text(
              '${f.airline}  ·  ${NumberFormat('#,###').format(f.price)}원'),
          subtitle: Text('${f.departDate} → ${f.returnDate}'
              '${f.durationOutbound != null ? '  ·  ${f.durationOutbound}' : ''}'
              '${f.stopsOutbound > 0 ? '  ·  경유 ${f.stopsOutbound}회' : '  ·  직항'}'),
          trailing: hasUrl
              ? const Icon(Icons.open_in_new, color: Color(0xFF1A73E8))
              : const Icon(Icons.chevron_right),
          onTap: hasUrl
              ? () async {
                  final uri = Uri.parse(f.bookingUrl!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  }
                }
              : null,
        );
      },
    );
  }
}

class _DatePairChip extends StatelessWidget {
  final DatePair pair;
  final VoidCallback onRemove;

  const _DatePairChip({required this.pair, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('M/d');
    return Chip(
      label: Text(
        '${fmt.format(pair.depart)} 출발 → ${fmt.format(pair.ret)} 귀국',
        style: const TextStyle(fontSize: 13),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: const Color(0xFF1A73E8).withOpacity(0.1),
      side: const BorderSide(color: Color(0xFF1A73E8), width: 0.5),
    );
  }
}

class _AirportAutocomplete extends StatelessWidget {
  final String label;
  final ValueChanged<String> onSelected;

  const _AirportAutocomplete({
    required this.label,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Airport>(
      optionsBuilder: (TextEditingValue value) {
        if (value.text.isEmpty) return const [];
        final query = value.text.toLowerCase();
        return _airports.where((a) =>
            a.name.contains(query) ||
            a.city.contains(query) ||
            a.iata.toLowerCase().contains(query));
      },
      displayStringForOption: (a) => '${a.iata} · ${a.name}',
      onSelected: (a) => onSelected(a.iata),
      optionsViewBuilder: (context, onSelected, options) {
        final count = min(options.length, 5);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: count * 60.0,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final airport = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(airport),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text(
                              airport.iata,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A73E8),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(airport.name,
                                    style: const TextStyle(fontSize: 14)),
                                Text(airport.city,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder:
          (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            hintText: '도시 또는 공항명',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.flight_takeoff, size: 18),
          ),
        );
      },
    );
  }
}
