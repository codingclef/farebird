import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _emailController = TextEditingController();
  bool _notifyPush = true;
  bool _notifyEmail = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('email') ?? '';
      _notifyPush = prefs.getBool('notify_push') ?? true;
      _notifyEmail = prefs.getBool('notify_email') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', _emailController.text);
    await prefs.setBool('notify_push', _notifyPush);
    await prefs.setBool('notify_email', _notifyEmail);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설정이 저장되었습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('알림 설정', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: '이메일',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('푸시 알림'),
            subtitle: const Text('가격 변동 시 앱 알림'),
            value: _notifyPush,
            onChanged: (v) => setState(() => _notifyPush = v),
          ),
          SwitchListTile(
            title: const Text('이메일 알림'),
            subtitle: const Text('가격 변동 시 이메일 발송'),
            value: _notifyEmail,
            onChanged: (v) => setState(() => _notifyEmail = v),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saveSettings,
            child: const Text('저장'),
          ),
          const Divider(height: 48),
          const Text('앱 정보', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('버전'),
            trailing: Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}
