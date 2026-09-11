import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/auth_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = globalAppState;
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final user = state.currentUser;

        // 1. NẾU CHƯA ĐĂNG NHẬP: HIỂN THỊ YÊU CẦU ĐĂNG NHẬP
        if (user == null) {
          return Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_person_outlined, size: 70, color: Colors.deepPurpleAccent),
                    const SizedBox(height: 16),
                    Text(state.t('not_logged_in_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      state.t('not_logged_in_desc'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => showDialog(context: context, builder: (_) => const AuthDialog()),
                      icon: const Icon(Icons.login),
                      label: Text(state.t('login_now')),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 2. KHI ĐÃ ĐĂNG NHẬP: HIỂN THỊ HỒ SƠ CHI TIẾT
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: user.role == 'admin'
                                  ? Colors.redAccent
                                  : (user.role == 'author' ? Colors.teal : Colors.deepPurple),
                              child: Text(
                                user.username[0].toUpperCase(),
                                style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: user.role == 'admin'
                                          ? Colors.red.withValues(alpha: 0.2)
                                          : (user.role == 'author'
                                              ? Colors.teal.withValues(alpha: 0.2)
                                              : Colors.blue.withValues(alpha: 0.2)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      user.role.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: user.role == 'admin'
                                            ? Colors.redAccent
                                            : (user.role == 'author' ? Colors.tealAccent : Colors.blueAccent),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(user.bio, style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: state.t('edit_profile_title'),
                              onPressed: () => _showEditProfileDialog(context, user),
                            ),
                          ],
                        ),

                        // NÚT ĐĂNG KÝ LÀM TÁC GIẢ (CHỈ HIỆN KHI LÀ ĐỘC GIẢ)
                        if (user.role == 'reader') ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: () {
                                state.becomeAuthor();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(state.language == 'vi'
                                        ? 'Chúc mừng! Bạn đã trở thành Tác giả và mở khóa Creator Studio.'
                                        : 'Congratulations! You are now an Author with Studio access.'),
                                    backgroundColor: Colors.teal,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit_note, color: Colors.tealAccent),
                              label: Text(state.t('register_author')),
                            ),
                          ),
                        ],

                        // THÔNG BÁO DÀNH CHO ADMIN KHI DÙNG TRÊN ĐIỆN THOẠI
                        if (user.role == 'admin' && !isDesktop) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.desktop_windows_outlined, color: Colors.amber),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        state.language == 'vi' ? 'Cổng Quản Trị Hệ Thống' : 'Admin Management Portal',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        state.language == 'vi'
                                            ? 'Để quản trị và biên tập tốt nhất, vui lòng mở ứng dụng trên trình duyệt máy tính.'
                                            : 'For best management experience, please access via a desktop browser.',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // THỐNG KÊ TỦ SÁCH VÀ TIẾN ĐỘ ĐỌC
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              Text('${state.currentFavorites.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
                              const SizedBox(height: 4),
                              Text(state.t('saved_stories'), style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              Text('${state.currentHistory.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
                              const SizedBox(height: 4),
                              Text(state.t('reading_stories'), style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // TÙY CHỌN HỆ THỐNG
                Text(state.t('system_options'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text(state.t('dark_mode')),
                        secondary: const Icon(Icons.dark_mode_outlined),
                        value: state.themeMode == ThemeMode.dark,
                        onChanged: (_) => state.toggleTheme(),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.language_outlined),
                        title: Text(state.t('lang_label')),
                        trailing: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'vi', label: Text('VI')),
                            ButtonSegment(value: 'en', label: Text('EN')),
                          ],
                          selected: {state.language},
                          onSelectionChanged: (_) => state.toggleLanguage(),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.redAccent),
                        title: Text(state.t('logout_account'), style: const TextStyle(color: Colors.redAccent)),
                        onTap: state.logout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, AppUser user) {
    final nameCtrl = TextEditingController(text: user.username);
    final bioCtrl = TextEditingController(text: user.bio);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(globalAppState.t('edit_profile_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: globalAppState.t('display_name'))),
            const SizedBox(height: 12),
            TextField(controller: bioCtrl, decoration: InputDecoration(labelText: globalAppState.t('bio_label'))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(globalAppState.t('cancel'))),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                globalAppState.updateProfile(nameCtrl.text.trim(), bioCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text(globalAppState.t('save')),
          ),
        ],
      ),
    );
  }
}