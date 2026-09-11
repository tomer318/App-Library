import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/comic_chapter_editor_dialog.dart';

class CreatorStudioScreen extends StatelessWidget {
  const CreatorStudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = globalAppState;
    final myStories = state.myCreatedStories;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 950),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Creator Studio', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('Không gian sáng tác dành riêng cho Tác giả / Dịch giả', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Đăng Truyện Mới'),
                    onPressed: () => _showCreateStoryDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: myStories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_stories_outlined, size: 60, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text('Bạn chưa có tác phẩm nào. Hãy bấm "Đăng Truyện Mới" để bắt đầu!'),
                            const SizedBox(height: 16),
                            FilledButton.tonal(
                              onPressed: () => _showCreateStoryDialog(context),
                              child: const Text('Đăng Tác Phẩm Đầu Tay'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: myStories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final story = myStories[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(story.coverUrl, width: 55, height: 75, fit: BoxFit.cover),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(story.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            const SizedBox(width: 8),
                                            Chip(
                                              label: Text(story.type == 'comic' ? 'Truyện Tranh' : 'Truyện Chữ', style: const TextStyle(fontSize: 10)),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text('${story.genre} • ${story.chapters.length} chương • 👁️ ${story.viewCount} lượt xem', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    icon: const Icon(Icons.post_add),
                                    tooltip: 'Đăng chương mới',
                                    onPressed: () => _showAddChapterDialog(context, story),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateStoryDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final genreCtrl = TextEditingController(text: 'Hành động');
    final coverCtrl = TextEditingController(text: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=400&q=80');
    final descCtrl = TextEditingController();
    String storyType = 'novel';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Đăng Tác Phẩm Mới'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Tên tác phẩm', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  const Text('Loại tác phẩm:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'novel', label: Text('Truyện Chữ')),
                      ButtonSegment(value: 'comic', label: Text('Truyện Tranh (Comic/Manga)')),
                    ],
                    selected: {storyType},
                    onSelectionChanged: (val) => setModalState(() => storyType = val.first),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: genreCtrl, decoration: const InputDecoration(labelText: 'Thể loại', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: coverCtrl, decoration: const InputDecoration(labelText: 'URL Ảnh bìa', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Mô tả tác phẩm', border: OutlineInputBorder())),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.isNotEmpty) {
                  globalAppState.addStory(
                    Story(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleCtrl.text.trim(),
                      author: globalAppState.currentUser?.username ?? 'Ẩn danh',
                      tags: [genreCtrl.text.trim().isEmpty ? 'Tâm linh' : genreCtrl.text.trim()],
                      coverUrl: coverCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      type: storyType,
                      creatorId: globalAppState.currentUser?.id ?? 'u_admin',
                      chapters: [],
                    ),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Khởi Tạo'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChapterDialog(BuildContext context, Story story) {
    if (story.type == 'comic') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ComicChapterEditorDialog(story: story),
      );
      return;
    }

    final titleCtrl = TextEditingController(text: 'Chương ${story.chapters.length + 1}: ');
    final contentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Thêm chương cho: ${story.title}'),
        content: SizedBox(
          width: 550,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Tiêu đề chương', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: contentCtrl, maxLines: 6, decoration: const InputDecoration(labelText: 'Nội dung văn bản chương', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && contentCtrl.text.isNotEmpty) {
                globalAppState.addChapterToStory(
                  story.id,
                  titleCtrl.text.trim(),
                  content: contentCtrl.text.trim(),
                );
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