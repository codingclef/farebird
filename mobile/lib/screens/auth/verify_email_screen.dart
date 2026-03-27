import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _authService = AuthService();
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _error;

  Future<void> _verify() async {
    if (_codeCtrl.text.length != 6) {
      setState(() => _error = '6자리 코드를 입력해주세요.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _authService.verifyEmail(widget.email, _codeCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 인증이 완료되었습니다. 환영합니다!')),
        );
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (_) {
      setState(() => _error = '인증 코드가 올바르지 않거나 만료되었습니다.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() { _resending = true; _error = null; });
    try {
      await _authService.resendVerification(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증 코드를 재발송했습니다.')),
        );
      }
    } catch (_) {
      setState(() => _error = '재발송에 실패했습니다. 잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('이메일 인증')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Icon(Icons.mark_email_unread_outlined, size: 64, color: Color(0xFF1A73E8)),
                const SizedBox(height: 16),
                const Text('인증 코드를 입력해주세요', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  '${widget.email}\n으로 6자리 인증 코드를 발송했습니다.\n(유효시간 10분)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    counterText: '',
                    hintText: '000000',
                  ),
                  onSubmitted: (_) => _verify(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _verify,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('인증 완료'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _resending ? null : _resend,
                  child: _resending
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('코드를 받지 못하셨나요? 재발송'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
