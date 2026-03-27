import 'package:flutter/material.dart';
import '../../models/flight.dart';
import '../../services/api_service.dart';

final _apiService = ApiService();
const _tempUserId = 1; // 로그인 기능 추가 전 임시 사용자 ID

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  List<WatchedRoute> _routes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() => _loading = true);
    try {
      final data = await _apiService.getWatches(_tempUserId);
      setState(() {
        _routes = data.map((e) => WatchedRoute.fromJson(e)).toList();
      });
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteRoute(int id) async {
    await _apiService.deleteWatch(id);
    _loadRoutes();
  }

  void _showAddDialog() {
    final originCtrl = TextEditingController();
    final destCtrl = TextEditingController();
    final monthCtrl = TextEditingController(
        text: DateTime.now().toString().substring(0, 7));
    double threshold = 10.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('모니터링 노선 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: originCtrl,
                decoration: const InputDecoration(labelText: '출발 공항 (예: ICN)'),
                textCapitalization: TextCapitalization.characters,
              ),
              TextField(
                controller: destCtrl,
                decoration: const InputDecoration(labelText: '도착 공항 (예: NRT)'),
                textCapitalization: TextCapitalization.characters,
              ),
              TextField(
                controller: monthCtrl,
                decoration: const InputDecoration(labelText: '여행 월 (예: 2026-06)'),
              ),
              const SizedBox(height: 12),
              Text('알림 기준: ${threshold.toInt()}% 이상 할인 시'),
              Slider(
                value: threshold,
                min: 5,
                max: 30,
                divisions: 5,
                label: '${threshold.toInt()}%',
                onChanged: (v) => setDialogState(() => threshold = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () async {
                await _apiService.addWatch(
                  userId: _tempUserId,
                  origin: originCtrl.text.toUpperCase(),
                  destination: destCtrl.text.toUpperCase(),
                  departMonth: monthCtrl.text,
                  alertThreshold: threshold,
                );
                if (context.mounted) Navigator.pop(context);
                _loadRoutes();
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('가격 모니터링')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _routes.isEmpty
              ? const Center(child: Text('모니터링 중인 노선이 없습니다.\n+ 버튼으로 추가해보세요.'))
              : ListView.builder(
                  itemCount: _routes.length,
                  itemBuilder: (context, index) {
                    final r = _routes[index];
                    return ListTile(
                      leading: const Icon(Icons.flight_takeoff),
                      title: Text('${r.origin} → ${r.destination}'),
                      subtitle: Text(
                          '${r.departMonth}  ·  ${r.alertThreshold.toInt()}% 이상 할인 시 알림'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteRoute(r.id),
                      ),
                    );
                  },
                ),
    );
  }
}
