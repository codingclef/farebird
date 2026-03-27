import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';

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

  Future<void> _showDeleteAccountDialog() async {
    final passwordCtrl = TextEditingController();
    bool obscure = true;
    String? error;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('회원 탈퇴'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('탈퇴하면 모든 데이터가 삭제되며 복구할 수 없습니다.\n비밀번호를 입력해 확인해주세요.'),
              const SizedBox(height: 16),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await AuthService().deleteAccount(passwordCtrl.text);
                  if (context.mounted) Navigator.pop(context, true);
                } catch (_) {
                  setDialogState(() => error = '비밀번호가 올바르지 않습니다.');
                }
              },
              child: const Text('탈퇴', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    ).then((result) {
      if (result == true && mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
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
          const Divider(height: 48),
          OutlinedButton.icon(
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/auth');
              }
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showDeleteAccountDialog(),
            child: const Text('회원 탈퇴', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
