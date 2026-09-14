import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/comic_chapter_editor_dialog.dart';
import '../../widgets/chapter_manager_dialog.dart';
import '../../services/supabase_service.dart';
import '../../widgets/safe_network_image.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = globalAppState;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final totalViews = state.stories.fold<int>(0, (sum, item) => sum + item.viewCount);
        final totalChapters = state.stories.fold<int>(0, (sum, item) => sum + item.chapters.length);

        return DefaultTabController(
          length: 3,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatCard(state.t('total_stories'), '${state.stories.length}', Icons.menu_book, Colors.blue),
                          _buildStatCard(state.t('total_chapters'), '$totalChapters', Icons.library_books, Colors.purple),
                          _buildStatCard(state.t('total_views'), '$totalViews', Icons.remove_red_eye, Colors.orange),
                          _buildStatCard(state.t('total_comments'), '${state.allComments.length}', Icons.chat, Colors.green),
                          _buildStatCard(state.t('total_members'), '${state.registeredUsers.length}', Icons.people, Colors.teal),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TabBar(
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      tabs: [
                        Tab(icon: const Icon(Icons.library_books, size: 20), text: state.t('tab_stories')),
                        Tab(icon: const Icon(Icons.chat, size: 20), text: state.t('tab_comments')),
                        Tab(icon: const Icon(Icons.group, size: 20), text: state.t('tab_users')),
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
                                  Text(state.t('story_list'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: Text(state.t('add_new_story')),
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
                                      final mainTag = story.tags.isNotEmpty ? story.tags.first : 'Khác';

                                      return ListTile(
                                        leading: SafeNetworkImage(
                                          imageUrl: story.coverUrl,
                                          width: 40,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        title: Text(story.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text('${story.author} • ${state.tGenre(mainTag)} • ${story.chapters.length} chap • 👁️ ${story.viewCount}'),
                                        trailing: MediaQuery.of(context).size.width < 600
                                            ? PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_vert),
                                                onSelected: (val) {
                                                  if (val == 'chapters') {
                                                    showDialog(
                                                      context: context,
                                                      builder: (_) => ChapterManagerDialog(story: story),
                                                    );
                                                  } else if (val == 'add_chap') {
                                                    _showAddChapterDialog(context, story);
                                                  } else if (val == 'edit') {
                                                    _showAddOrEditStoryModal(context, existingStory: story);
                                                  } else if (val == 'delete') {
                                                    state.removeStory(story.id);
                                                  }
                                                },
                                                itemBuilder: (_) => [
                                                  PopupMenuItem(
                                                    value: 'chapters',
                                                    child: Row(children: [const Icon(Icons.format_list_bulleted, color: Colors.tealAccent, size: 20), const SizedBox(width: 8), Text(state.t('manage_chapters'))]),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'add_chap',
                                                    child: Row(children: [const Icon(Icons.post_add, color: Colors.blueAccent, size: 20), const SizedBox(width: 8), Text(state.t('add_chapter'))]),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(children: [const Icon(Icons.edit, color: Colors.amber, size: 20), const SizedBox(width: 8), Text(state.t('edit_story'))]),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(children: [const Icon(Icons.delete, color: Colors.redAccent, size: 20), const SizedBox(width: 8), Text(state.t('delete_story'))]),
                                                  ),
                                                ],
                                              )
                                            : Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.format_list_bulleted, color: Colors.tealAccent),
                                                    tooltip: state.t('manage_chapters'),
                                                    onPressed: () => showDialog(context: context, builder: (_) => ChapterManagerDialog(story: story)),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.post_add, color: Colors.blueAccent),
                                                    tooltip: state.t('add_chapter'),
                                                    onPressed: () => _showAddChapterDialog(context, story),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, color: Colors.amber),
                                                    tooltip: state.t('edit_story'),
                                                    onPressed: () => _showAddOrEditStoryModal(context, existingStory: story),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    tooltip: state.t('delete_story'),
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
                                ? Center(child: Text(state.t('no_chapters_yet')))
                                : ListView.separated(
                                    itemCount: state.allComments.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final comment = state.allComments[index];
                                      return ListTile(
                                        leading: CircleAvatar(child: Text(comment.username.isNotEmpty ? comment.username[0].toUpperCase() : '?')),
                                        title: Row(
                                          children: [
                                            Text('${comment.username} • Chap ${comment.chapterIndex + 1}'),
                                            const SizedBox(width: 8),
                                            if (comment.reportCount > 0)
                                              Chip(
                                                avatar: const Icon(Icons.warning, color: Colors.white, size: 14),
                                                label: Text('${comment.reportCount} Báo cáo', style: const TextStyle(color: Colors.white, fontSize: 10)),
                                                backgroundColor: Colors.redAccent,
                                              ),
                                          ],
                                        ),
                                        subtitle: Text('${comment.content}\n👍 ${comment.likedUsernames.length} lượt thích'),
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
                                    child: Text(u.username.isNotEmpty ? u.username[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
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
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 140,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddOrEditStoryModal(BuildContext context, {Story? existingStory}) {
    final titleCtrl = TextEditingController(text: existingStory?.title ?? '');
    final authorCtrl = TextEditingController(text: existingStory?.author ?? '');
    final coverCtrl = TextEditingController(text: existingStory?.coverUrl ?? '');
    final descCtrl = TextEditingController(text: existingStory?.description ?? '');
    final yearCtrl = TextEditingController(text: (existingStory?.releaseYear ?? 2024).toString());

    List<String> selectedTags = List<String>.from(existingStory?.tags ?? ['Tâm linh']);
    // Cho phép chọn và giữ trạng thái type giữa 'novel' và 'comic'
    String storyType = existingStory?.type ?? 'novel';
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: Text(existingStory == null ? globalAppState.t('add_new_story') : globalAppState.t('edit_story')),
            content: SizedBox(
              width: 650,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BỘ CHỌN LOẠI TRUYỆN: NOVEL (TRUYỆN CHỮ) HOẶC COMIC (TRUYỆN TRANH)
                    const Text('Phân loại tác phẩm:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'novel',
                            label: Text('Truyện Chữ (Novel)'),
                            icon: Icon(Icons.menu_book, size: 16),
                          ),
                          ButtonSegment(
                            value: 'comic',
                            label: Text('Truyện Tranh (Manga / Comic)'),
                            icon: Icon(Icons.photo_library, size: 16),
                          ),
                        ],
                        selected: {storyType},
                        onSelectionChanged: (val) {
                          setModalState(() {
                            storyType = val.first;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(child: TextField(controller: titleCtrl, decoration: InputDecoration(labelText: globalAppState.t('story_title'), border: const OutlineInputBorder()))),
                        const SizedBox(width: 12),
                        SizedBox(width: 140, child: TextField(controller: yearCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Năm phát hành', border: OutlineInputBorder()))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: authorCtrl, decoration: InputDecoration(labelText: globalAppState.t('author'), border: const OutlineInputBorder())),
                    const SizedBox(height: 12),

                    // CHỌN ẢNH BÌA: BROWSE TẢI LÊN SUPABASE STORAGE
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: coverCtrl,
                            readOnly: isUploading,
                            decoration: InputDecoration(
                              labelText: globalAppState.t('cover_url'),
                              border: const OutlineInputBorder(),
                              hintText: isUploading ? 'Đang tải ảnh lên Cloud...' : 'https://...',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: isUploading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.file_upload),
                          label: Text(isUploading ? 'Đang tải...' : 'Browse'),
                          onPressed: isUploading
                              ? null
                              : () async {
                                  final picker = ImagePicker();
                                  final file = await picker.pickImage(source: ImageSource.gallery);
                                  if (file != null) {
                                    setModalState(() {
                                      isUploading = true;
                                      coverCtrl.text = 'Đang tải ảnh lên Cloud...';
                                    });

                                    final bytes = await file.readAsBytes();
                                    final ext = file.name.split('.').last.toLowerCase();

                                    final uploadedUrl = await SupabaseService.uploadCoverImage(bytes, ext);

                                    setModalState(() {
                                      isUploading = false;
                                      if (uploadedUrl != null) {
                                        coverCtrl.text = uploadedUrl;
                                      } else {
                                        coverCtrl.text = '';
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Lỗi tải ảnh lên Supabase! Vui lòng kiểm tra policy của bucket covers.'),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    });
                                  }
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // CHỌN ĐA THỂ LOẠI (TAGS)
                    const Text('Chọn các Tag thể loại:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: globalAppState.masterTags.map((tag) {
                        final isChecked = selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag, style: const TextStyle(fontSize: 11)),
                          selected: isChecked,
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                selectedTags.add(tag);
                              } else {
                                selectedTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    TextField(controller: descCtrl, maxLines: 3, decoration: InputDecoration(labelText: globalAppState.t('description'), border: const OutlineInputBorder())),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(globalAppState.t('cancel'))),
              FilledButton(
                onPressed: isUploading
                    ? null
                    : () {
                        if (titleCtrl.text.isNotEmpty && authorCtrl.text.isNotEmpty) {
                          final year = int.tryParse(yearCtrl.text.trim()) ?? 2024;
                          if (existingStory == null) {
                            globalAppState.addStory(
                              Story(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                title: titleCtrl.text.trim(),
                                author: authorCtrl.text.trim(),
                                tags: selectedTags.isEmpty ? ['Khác'] : selectedTags,
                                releaseYear: year,
                                type: storyType, // Lưu đúng type được chọn ('novel' hoặc 'comic')
                                coverUrl: coverCtrl.text.trim().isEmpty ? 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400&q=80' : coverCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                chapters: [
                                  Chapter(
                                    title: 'Chương 1: Mở đầu',
                                    content: storyType == 'novel' ? 'Nội dung đang cập nhật...' : '',
                                    imageUrls: storyType == 'comic' ? [] : [],
                                  ),
                                ],
                              ),
                            );
                          } else {
                            existingStory.type = storyType; // Đồng bộ type khi sửa
                            globalAppState.updateStory(
                              existingStory.id,
                              titleCtrl.text.trim(),
                              authorCtrl.text.trim(),
                              selectedTags.isEmpty ? ['Khác'] : selectedTags,
                              year,
                              existingStory.status,
                              coverCtrl.text.trim(),
                              descCtrl.text.trim(),
                            );
                          }
                          Navigator.pop(ctx);
                        }
                      },
                child: Text(globalAppState.t('save_changes')),
              ),
            ],
          );
        },
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
        title: Text('${globalAppState.t('add_chapter')}: ${story.title}'),
        content: SizedBox(
          width: 550,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: InputDecoration(labelText: globalAppState.t('chapter_title'), border: const OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: contentCtrl, maxLines: 6, decoration: InputDecoration(labelText: globalAppState.t('chapter_content'), border: const OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(globalAppState.t('cancel'))),
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
            child: Text(globalAppState.t('publish_chapter')),
          ),
        ],
      ),
    );
  }
}