import 'package:flutter/material.dart';
import '../state/app_state.dart';

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  bool isLoginMode = true;
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String? errorMessage;

  void _submit() {
    final u = userCtrl.text.trim();
    final p = passCtrl.text.trim();

    if (u.isEmpty || p.isEmpty) {
      setState(() => errorMessage = 'Vui lòng nhập đầy đủ tên và mật khẩu!');
      return;
    }

    String? err;
    if (isLoginMode) {
      err = globalAppState.login(u, p);
    } else {
      err = globalAppState.register(u, p);
    }

    if (err != null) {
      setState(() => errorMessage = err);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isLoginMode ? 'Đăng nhập thành công! Chào $u' : 'Tạo tài khoản thành công!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        isLoginMode ? 'Đăng Nhập Tài Khoản' : 'Đăng Ký Thành Viên Mới',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
                  ],
                ),
              ),
            ],
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên đăng nhập',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            if (isLoginMode)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tài khoản mẫu có sẵn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('• Admin: admin / 123 (Có toàn quyền quản trị)', style: TextStyle(fontSize: 12)),
                    Text('• Độc giả: docgia1 / 123', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    isLoginMode = !isLoginMode;
                    errorMessage = null;
                  });
                },
                child: Text(isLoginMode ? 'Chưa có tài khoản? Nhấn để Đăng Ký' : 'Đã có tài khoản? Nhấn để Đăng Nhập'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(
          onPressed: _submit,
          child: Text(isLoginMode ? 'Đăng Nhập' : 'Tạo Tài Khoản'),
        ),
      ],
    );
  }
}