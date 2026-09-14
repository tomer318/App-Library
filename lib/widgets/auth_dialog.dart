import 'package:flutter/material.dart';
import '../state/app_state.dart';

class AuthDialog extends StatefulWidget {
  final bool initialIsLogin;
  const AuthDialog({super.key, this.initialIsLogin = true});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  // Login Controllers
  final _loginEmailOrUserCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  // Register Controllers
  final _regEmailCtrl = TextEditingController();
  final _regUserCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmPassCtrl = TextEditingController();

  bool _obscureLoginPass = true;
  bool _obscureRegPass = true;
  bool _obscureRegConfirmPass = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _loginEmailOrUserCtrl.dispose();
    _loginPassCtrl.dispose();
    _regEmailCtrl.dispose();
    _regUserCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final account = _loginEmailOrUserCtrl.text.trim();
    final pass = _loginPassCtrl.text.trim();

    if (account.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập đầy đủ Email và mật khẩu!');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final err = await globalAppState.login(account, pass);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (err != null) {
      setState(() => _errorMessage = err);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleRegister() async {
    final email = _regEmailCtrl.text.trim();
    final username = _regUserCtrl.text.trim();
    final pass = _regPassCtrl.text.trim();
    final confirmPass = _regConfirmPassCtrl.text.trim();

    if (email.isEmpty || username.isEmpty || pass.isEmpty || confirmPass.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng điền đầy đủ tất cả các trường!');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Địa chỉ Email không đúng định dạng!');
      return;
    }

    if (pass.length < 6) {
      setState(() => _errorMessage = 'Mật khẩu phải từ 6 ký tự trở lên!');
      return;
    }

    if (pass != confirmPass) {
      setState(() => _errorMessage = 'Mật khẩu xác nhận không trùng khớp!');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final err = await globalAppState.register(
      email: email,
      username: username,
      password: pass,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (err != null) {
      setState(() => _errorMessage = err);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký tài khoản thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialIsLogin ? 0 : 1,
      child: Builder(
        builder: (ctx) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: const Color(0xFF1E1E26),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440, maxHeight: 600),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tab Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TabBar(
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey,
                        onTap: (_) => setState(() => _errorMessage = null),
                        tabs: const [
                          Tab(icon: Icon(Icons.login, size: 18), text: 'Đăng Nhập'),
                          Tab(icon: Icon(Icons.person_add_alt_1, size: 18), text: 'Tạo Tài Khoản'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Thông báo lỗi
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Nội dung Tab có thể cuộn độc lập và có padding trên dưới đầy đủ
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildLoginForm(ctx),
                          _buildRegisterForm(ctx),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginForm(BuildContext tabContext) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _loginEmailOrUserCtrl,
            decoration: const InputDecoration(
              labelText: 'Email hoặc Tên đăng nhập',
              prefixIcon: Icon(Icons.alternate_email),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _loginPassCtrl,
            obscureText: _obscureLoginPass,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureLoginPass ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureLoginPass = !_obscureLoginPass),
              ),
            ),
            onSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isLoading ? null : _handleLogin,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.deepPurple,
            ),
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.arrow_forward),
            label: const Text('Đăng Nhập', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => DefaultTabController.of(tabContext).animateTo(1),
              child: const Text('Chưa có tài khoản? Nhấn để Đăng Ký', style: TextStyle(color: Colors.purpleAccent, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext tabContext) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _regEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Địa chỉ Email (Dùng đăng nhập)',
              hintText: 'vidu@gmail.com',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _regUserCtrl,
            decoration: const InputDecoration(
              labelText: 'Tên hiển thị (Username)',
              hintText: 'Tên hiển thị trên web',
              prefixIcon: Icon(Icons.badge_outlined),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _regPassCtrl,
            obscureText: _obscureRegPass,
            decoration: InputDecoration(
              labelText: 'Mật khẩu (từ 6 ký tự)',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              suffixIcon: IconButton(
                icon: Icon(_obscureRegPass ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureRegPass = !_obscureRegPass),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _regConfirmPassCtrl,
            obscureText: _obscureRegConfirmPass,
            decoration: InputDecoration(
              labelText: 'Xác nhận lại mật khẩu',
              prefixIcon: const Icon(Icons.verified_user_outlined),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              suffixIcon: IconButton(
                icon: Icon(_obscureRegConfirmPass ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureRegConfirmPass = !_obscureRegConfirmPass),
              ),
            ),
            onSubmitted: (_) => _handleRegister(),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _isLoading ? null : _handleRegister,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.deepPurple,
            ),
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline),
            label: const Text('Tạo Tài Khoản Ngay', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => DefaultTabController.of(tabContext).animateTo(0),
              child: const Text('Đã có tài khoản? Quay lại Đăng Nhập', style: TextStyle(color: Colors.purpleAccent, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}