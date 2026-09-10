import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = globalAppState;
    final totalViews = state.stories.fold<int>(0, (sum, item) => sum + item.viewCount);
    final totalChapters = state.stories.fold<int>(0, (sum, item) => sum + item.chapters.length);

    return DefaultTabController(
      length: 3,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStatCard('Tổng Truyện', '${state.stories.length}', Icons.menu_book, Colors.blue),
                    _buildStatCard('Tổng Chương', '$totalChapters', Icons.library_books, Colors.purple),
                    _buildStatCard('Lượt Xem', '$totalViews', Icons.remove_red_eye, Colors.orange),
                    _buildStatCard('Bình Luận', '${state.allComments.length}', Icons.chat, Colors.green),
                    _buildStatCard('Thành Viên', '${state.registeredUsers.length}', Icons.people, Colors.teal),
                  ],
                ),
                const SizedBox(height: 16),
                const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.library_books), text: 'Quản Lý Truyện'),
                    Tab(icon: Icon(Icons.chat), text: 'Kiểm Duyệt Bình Luận'),
                    Tab(icon: Icon(Icons.group), text: 'Danh Sách Người Dùng'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      // TAB 1: QUẢN LÝ TRUYỆN
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Danh Sách Đầu Truyện', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Thêm Truyện Mới'),
                                onPressed: () => _showAddOrEditStoryModal(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Card(
                              child: ListView.separated(
                                itemCount: state.stories.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final story = state.stories[index];
                                  return ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(story.coverUrl, width: 40, height: 50, fit: BoxFit.cover),
                                    ),
                                    title: Text(story.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('${story.author} • ${story.genre} • ${story.chapters.length} chap • 👁️ ${story.viewCount}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.post_add, color: Colors.blueAccent),
                                          tooltip: 'Thêm chương mới',
                                          onPressed: () => _showAddChapterDialog(context, story),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.amber),
                                          tooltip: 'Sửa thông tin',
                                          onPressed: () => _showAddOrEditStoryModal(context, existingStory: story),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: 'Xóa truyện',
                                          onPressed: () => state.removeStory(story.id),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      // TAB 2: BÌNH LUẬN
                      Card(
                        child: state.allComments.isEmpty
                            ? const Center(child: Text('Không có bình luận nào trên hệ thống.'))
                            : ListView.separated(
                                itemCount: state.allComments.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final comment = state.allComments[index];
                                  return ListTile(
                                    leading: CircleAvatar(child: Text(comment.username[0].toUpperCase())),
                                    title: Text('${comment.username} • Chap ${comment.chapterIndex + 1}'),
                                    subtitle: Text(comment.content),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      tooltip: 'Xóa bình luận này',
                                      onPressed: () => state.deleteComment(comment.id),
                                    ),
                                  );
                                },
                              ),
                      ),
                      // TAB 3: USER
                      Card(
                        child: ListView.separated(
                          itemCount: state.registeredUsers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final u = state.registeredUsers[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: u.role == 'admin' ? Colors.redAccent : Colors.deepPurple,
                                child: Text(u.username[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                              ),
                              title: Text(u.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Vai trò: ${u.role.toUpperCase()} • Mật khẩu: ${u.password}'),
                              trailing: u.role == 'admin'
                                  ? const Chip(label: Text('Admin', style: TextStyle(fontSize: 10)))
                                  : IconButton(
                                      icon: const Icon(Icons.person_remove, color: Colors.red),
                                      tooltip: 'Xóa tài khoản này',
                                      onPressed: () => state.deleteUser(u.id),
                                    ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddOrEditStoryModal(BuildContext context, {Story? existingStory}) {
    final titleCtrl = TextEditingController(text: existingStory?.title ?? '');
    final authorCtrl = TextEditingController(text: existingStory?.author ?? '');
    final genreCtrl = TextEditingController(text: existingStory?.genre ?? 'Kiếm hiệp');
    final coverCtrl = TextEditingController(text: existingStory?.coverUrl ?? 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=400&q=80');
    final descCtrl = TextEditingController(text: existingStory?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingStory == null ? 'Thêm Truyện Mới' : 'Sửa Thông Tin Truyện'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Tên truyện', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: authorCtrl, decoration: const InputDecoration(labelText: 'Tác giả', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: genreCtrl, decoration: const InputDecoration(labelText: 'Thể loại', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: coverCtrl, decoration: const InputDecoration(labelText: 'URL Ảnh bìa', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder())),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && authorCtrl.text.isNotEmpty) {
                if (existingStory == null) {
                  globalAppState.addStory(
                    Story(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleCtrl.text.trim(),
                      author: authorCtrl.text.trim(),
                      genre: genreCtrl.text.trim(),
                      coverUrl: coverCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      chapters: [Chapter(title: 'Chương 1: Mở đầu', content: 'Nội dung đang cập nhật...')],
                    ),
                  );
                } else {
                  globalAppState.updateStory(
                    existingStory.id,
                    titleCtrl.text.trim(),
                    authorCtrl.text.trim(),
                    genreCtrl.text.trim(),
                    coverCtrl.text.trim(),
                    descCtrl.text.trim(),
                  );
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showAddChapterDialog(BuildContext context, Story story) {
    final titleCtrl = TextEditingController(text: 'Chương ${story.chapters.length + 1}: ');
    final contentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Thêm chương mới cho: ${story.title}'),
        content: SizedBox(
          width: 550,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Tiêu đề chương', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: contentCtrl, maxLines: 6, decoration: const InputDecoration(labelText: 'Nội dung chương', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && contentCtrl.text.isNotEmpty) {
                globalAppState.addChapterToStory(story.id, titleCtrl.text.trim(), contentCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Đăng Chương'),
          ),
        ],
      ),
    );
  }
}