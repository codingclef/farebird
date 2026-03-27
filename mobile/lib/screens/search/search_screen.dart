import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/flight.dart';
import '../../services/api_service.dart';

final _apiService = ApiService();

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();

  final Set<DateTime> _selectedDepartDates = {};
  final Set<DateTime> _selectedReturnDates = {};
  bool _selectingDepart = true;

  List<FlightItinerary> _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _search() async {
    if (_originController.text.isEmpty ||
        _destinationController.text.isEmpty ||
        _selectedDepartDates.isEmpty ||
        _selectedReturnDates.isEmpty) {
      setState(() => _error = '출발지, 도착지, 날짜를 모두 선택해주세요.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final fmt = DateFormat('yyyy-MM-dd');
      final data = await _apiService.searchFlights(
        origin: _originController.text.toUpperCase(),
        destination: _destinationController.text.toUpperCase(),
        departDates: _selectedDepartDates.map((d) => fmt.format(d)).toList(),
        returnDates: _selectedReturnDates.map((d) => fmt.format(d)).toList(),
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
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _originController,
                        decoration: const InputDecoration(
                          labelText: '출발 (예: ICN)',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _destinationController,
                        decoration: const InputDecoration(
                          labelText: '도착 (예: NRT)',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('출발일 선택')),
                    ButtonSegment(value: false, label: Text('귀국일 선택')),
                  ],
                  selected: {_selectingDepart},
                  onSelectionChanged: (v) =>
                      setState(() => _selectingDepart = v.first),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectingDepart
                      ? '출발일 선택됨: ${_selectedDepartDates.length}개'
                      : '귀국일 선택됨: ${_selectedReturnDates.length}개',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: DateTime.now(),
                  selectedDayPredicate: (day) => _selectingDepart
                      ? _selectedDepartDates.any((d) => isSameDay(d, day))
                      : _selectedReturnDates.any((d) => isSameDay(d, day)),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      final set = _selectingDepart
                          ? _selectedDepartDates
                          : _selectedReturnDates;
                      if (set.any((d) => isSameDay(d, selected))) {
                        set.removeWhere((d) => isSameDay(d, selected));
                      } else {
                        set.add(selected);
                      }
                    });
                  },
                  calendarFormat: CalendarFormat.month,
                  headerStyle: const HeaderStyle(formatButtonVisible: false),
                ),
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
          title: Text('${f.airline}  ·  ${NumberFormat('#,###').format(f.price)}원'),
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
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              : null,
        );
      },
    );
  }
}
