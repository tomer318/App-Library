import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/comic_chapter_editor_dialog.dart';
import '../../widgets/chapter_manager_dialog.dart';
import '../../services/supabase_service.dart';
import '../../widgets/safe_network_image.dart';
import '../../utils/novel_parser.dart';

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
                                      final isHidden = story.status == 'Tạm ẩn' || story.status == 'hidden';
                                      final isCompleted = story.status == 'Hoàn thành';

                                      return ListTile(
                                        leading: SafeNetworkImage(
                                          imageUrl: story.coverUrl,
                                          width: 40,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                story.title,
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Chip(
                                              label: Text(story.type == 'comic' ? state.t('manga') : state.t('novel'), style: const TextStyle(fontSize: 10)),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            const SizedBox(width: 4),
                                            // BADGE TRẠNG THÁI KIỂM DUYỆT
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isHidden
                                                    ? Colors.redAccent.withValues(alpha: 0.2)
                                                    : (isCompleted ? Colors.green.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2)),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: isHidden
                                                      ? Colors.redAccent
                                                      : (isCompleted ? Colors.green : Colors.blueAccent),
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Text(
                                                isHidden
                                                    ? '🔒 Tạm ẩn'
                                                    : (isCompleted ? '✅ Hoàn thành' : '⚡ Đang ra'),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isHidden
                                                      ? Colors.redAccent
                                                      : (isCompleted ? Colors.greenAccent : Colors.lightBlueAccent),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black45,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                story.language == 'en' ? '🇬🇧 EN' : '🇻🇳 VI',
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: Text('${story.author} • ${state.tGenre(mainTag)} • ${story.chapters.length} chap • 👁️ ${story.viewCount}'),
                                        trailing: MediaQuery.of(context).size.width < 650
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
                                                  } else if (val == 'status_ongoing') {
                                                    state.updateStoryStatus(story.id, 'Đang tiến hành');
                                                  } else if (val == 'status_completed') {
                                                    state.updateStoryStatus(story.id, 'Hoàn thành');
                                                  } else if (val == 'status_hidden') {
                                                    state.updateStoryStatus(story.id, 'Tạm ẩn');
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
                                                  const PopupMenuDivider(),
                                                  const PopupMenuItem(
                                                    value: 'status_ongoing',
                                                    child: Row(children: [Icon(Icons.bolt, color: Colors.blueAccent, size: 20), SizedBox(width: 8), Text('Đặt: Đang tiến hành')]),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'status_completed',
                                                    child: Row(children: [Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 20), SizedBox(width: 8), Text('Đặt: Đã hoàn thành')]),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'status_hidden',
                                                    child: Row(children: [Icon(Icons.visibility_off_outlined, color: Colors.redAccent, size: 20), SizedBox(width: 8), Text('Đặt: Tạm ẩn truyện')]),
                                                  ),
                                                  const PopupMenuDivider(),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(children: [const Icon(Icons.delete, color: Colors.redAccent, size: 20), const SizedBox(width: 8), Text(state.t('delete_story'))]),
                                                  ),
                                                ],
                                              )
                                            : Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // MENU KIỂM DUYỆT TRẠNG THÁI
                                                  PopupMenuButton<String>(
                                                    icon: const Icon(Icons.shield_outlined, color: Colors.purpleAccent),
                                                    tooltip: 'Kiểm duyệt trạng thái',
                                                    onSelected: (newStatus) => state.updateStoryStatus(story.id, newStatus),
                                                    itemBuilder: (_) => [
                                                      const PopupMenuItem(
                                                        value: 'Đang tiến hành',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.bolt, color: Colors.blueAccent, size: 18),
                                                            SizedBox(width: 8),
                                                            Text('Công khai (Đang tiến hành)'),
                                                          ],
                                                        ),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'Hoàn thành',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 18),
                                                            SizedBox(width: 8),
                                                            Text('Công khai (Đã hoàn thành)'),
                                                          ],
                                                        ),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'Tạm ẩn',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.visibility_off_outlined, color: Colors.redAccent, size: 18),
                                                            SizedBox(width: 8),
                                                            Text('Tạm ẩn (Khóa hiển thị)'),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
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
    final assignedStoryId = existingStory?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final titleCtrl = TextEditingController(text: existingStory?.title ?? '');
    final authorCtrl = TextEditingController(text: existingStory?.author ?? '');
    final coverCtrl = TextEditingController(text: existingStory?.coverUrl ?? '');
    final descCtrl = TextEditingController(text: existingStory?.description ?? '');
    final yearCtrl = TextEditingController(text: (existingStory?.releaseYear ?? 2024).toString());

    List<String> selectedTags = List<String>.from(existingStory?.tags ?? ['Tâm linh']);
    String storyType = existingStory?.type ?? 'novel';
    String storyLang = existingStory?.language ?? 'vi';
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E26),
            title: Text(existingStory == null ? globalAppState.t('add_new_story') : globalAppState.t('edit_story')),
            content: SizedBox(
              width: 650,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BỘ CHỌN LOẠI TRUYỆN: NOVEL HOẶC COMIC
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

                    // BỘ CHỌN NGÔN NGỮ HIỂN THỊ CỜ
                    const Text('Ngôn ngữ hiển thị của truyện:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'vi', label: Text('🇻🇳 Tiếng Việt (VI)')),
                          ButtonSegment(value: 'en', label: Text('🇬🇧 English (EN)')),
                        ],
                        selected: {storyLang},
                        onSelectionChanged: (val) => setModalState(() => storyLang = val.first),
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
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.file_upload),
                          label: Text(isUploading ? 'Đang tải...' : 'Browse'),
                          onPressed: isUploading
                              ? null
                              : () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final picker = ImagePicker();
                                  final file = await picker.pickImage(source: ImageSource.gallery);
                                  if (file == null) return;

                                  if (dialogCtx.mounted) {
                                    setModalState(() {
                                      isUploading = true;
                                      coverCtrl.text = 'Đang tải ảnh lên Cloud...';
                                    });
                                  }

                                  final bytes = await file.readAsBytes();
                                  final ext = file.name.split('.').last.toLowerCase();

                                  final rawTitle = titleCtrl.text.trim();
                                  final curTitle = rawTitle.isNotEmpty ? rawTitle : 'new_story';
                                  final storyId = assignedStoryId;

                                  final uploadedUrl = await SupabaseService.uploadCoverImage(
                                    bytes,
                                    ext,
                                    storyTitle: curTitle,
                                    storyId: storyId,
                                  );

                                  if (!dialogCtx.mounted) return;
                                  setModalState(() {
                                    isUploading = false;
                                    if (uploadedUrl != null) {
                                      coverCtrl.text = uploadedUrl;
                                    } else {
                                      coverCtrl.text = '';
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Lỗi tải ảnh lên Supabase! Vui lòng kiểm tra policy của bucket covers.'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  });
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

                    // MÔ TẢ GIỚI HẠN 750 KÝ TỰ
                    TextField(
                      controller: descCtrl,
                      maxLines: 4,
                      maxLength: 750,
                      decoration: InputDecoration(
                        labelText: globalAppState.t('description'),
                        hintText: 'Nhập tóm tắt truyện (tối đa 750 ký tự)...',
                        border: const OutlineInputBorder(),
                      ),
                    ),
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
                          final cover = coverCtrl.text.trim().isEmpty ? 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400&q=80' : coverCtrl.text.trim();
                          final desc = descCtrl.text.trim();
                          final tags = selectedTags.isEmpty ? ['Khác'] : selectedTags;

                          if (existingStory == null) {
                            globalAppState.addStory(
                              Story(
                                id: assignedStoryId,
                                title: titleCtrl.text.trim(),
                                author: authorCtrl.text.trim(),
                                tags: tags,
                                releaseYear: year,
                                type: storyType,
                                language: storyLang,
                                coverUrl: cover,
                                description: desc,
                                creatorId: globalAppState.currentUser?.id ?? 'u_admin',
                                chapters: [],
                              ),
                            );
                          } else {
                            existingStory.type = storyType;
                            existingStory.language = storyLang;
                            globalAppState.updateStory(
                              existingStory.id,
                              titleCtrl.text.trim(),
                              authorCtrl.text.trim(),
                              tags,
                              year,
                              existingStory.status,
                              cover,
                              desc,
                              type: storyType,
                              language: storyLang,
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

  // TRÌNH BIÊN TẬP VÀ NHẬP CHƯƠNG TỰ ĐỘNG CHUẨN STUDIO CHO ADMIN
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
    bool isSaving = false;
    bool isImporting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final wordsCount = contentCtrl.text.trim().isEmpty
              ? 0
              : contentCtrl.text.trim().split(RegExp(r'\s+')).length;
          final charsCount = contentCtrl.text.length;

          Future<void> importFromTxt() async {
            final picker = ImagePicker();
            final file = await picker.pickMedia();
            if (file == null) return;

            setDialogState(() => isImporting = true);
            try {
              final bytes = await file.readAsBytes();
              String rawText;
              try {
                rawText = utf8.decode(bytes);
              } catch (_) {
                rawText = latin1.decode(bytes);
              }

              final parsedChapters = NovelParser.parseTxtFile(rawText);

              if (parsedChapters.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không tìm thấy nội dung chương hợp lệ trong file!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }

              if (parsedChapters.length > 1) {
                if (!dialogCtx.mounted) return;
                final confirm = await showDialog<bool>(
                  context: dialogCtx,
                  builder: (confirmCtx) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1E26),
                    title: Text('Đã nhận diện được ${parsedChapters.length} chương!'),
                    content: SizedBox(
                      width: 500,
                      height: 320,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hệ thống sẽ tự động tạo và lưu danh sách các chương sau vào truyện:',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.separated(
                              itemCount: parsedChapters.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (_, idx) {
                                final item = parsedChapters[idx];
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 12,
                                    child: Text('${idx + 1}', style: const TextStyle(fontSize: 10)),
                                  ),
                                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  subtitle: Text('${item.content.length} ký tự', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(confirmCtx, false), child: const Text('Hủy')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
                        onPressed: () => Navigator.pop(confirmCtx, true),
                        child: const Text('Xác nhận nạp tất cả chương'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  setDialogState(() => isSaving = true);
                  for (final ch in parsedChapters) {
                    await globalAppState.addChapterToStory(story.id, ch.title, content: ch.content);
                  }
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã thêm thành công ${parsedChapters.length} chương vào truyện!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } else {
                titleCtrl.text = parsedChapters.first.title;
                contentCtrl.text = parsedChapters.first.content;
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi khi đọc file: $e'), backgroundColor: Colors.redAccent),
                );
              }
            } finally {
              if (dialogCtx.mounted) {
                setDialogState(() {
                  isImporting = false;
                  isSaving = false;
                });
              }
            }
          }

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            backgroundColor: const Color(0xFF1E1E26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: MediaQuery.of(context).size.width > 1200 ? 1150 : double.infinity,
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${globalAppState.t('add_chapter')}: ${story.title}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Admin Novel Chapter Studio Editor',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: (isSaving || isImporting) ? null : () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  TextField(
                    controller: titleCtrl,
                    enabled: !isSaving && !isImporting,
                    decoration: InputDecoration(
                      labelText: globalAppState.t('chapter_title'),
                      prefixIcon: const Icon(Icons.title),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.text_fields, size: 14, color: Colors.deepPurpleAccent),
                            const SizedBox(width: 6),
                            Text(
                              '$charsCount ký tự • $wordsCount từ',
                              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.tealAccent,
                          side: const BorderSide(color: Colors.tealAccent),
                        ),
                        onPressed: (isSaving || isImporting) ? null : importFromTxt,
                        icon: isImporting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.tealAccent),
                              )
                            : const Icon(Icons.upload_file, size: 16),
                        label: Text(isImporting ? 'Đang phân tích file...' : 'Nhập tự động từ file .txt'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: TextField(
                      controller: contentCtrl,
                      enabled: !isSaving && !isImporting,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(fontSize: 15, height: 1.6),
                      decoration: const InputDecoration(
                        hintText: 'Nhập hoặc dán nội dung văn bản của chương vào đây, hoặc nhấn nút "Nhập tự động từ file .txt" ở trên...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: (isSaving || isImporting) ? null : () => Navigator.pop(ctx),
                        child: Text(globalAppState.t('cancel')),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          backgroundColor: Colors.deepPurple,
                        ),
                        onPressed: (isSaving || isImporting)
                            ? null
                            : () async {
                                final title = titleCtrl.text.trim();
                                final content = contentCtrl.text.trim();

                                if (title.isNotEmpty && content.isNotEmpty) {
                                  setDialogState(() => isSaving = true);
                                  try {
                                    await globalAppState.addChapterToStory(
                                      story.id,
                                      title,
                                      content: content,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Đã đăng chương mới thành công!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Lỗi khi đăng chương: $e'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (dialogCtx.mounted) {
                                      setDialogState(() => isSaving = false);
                                    }
                                  }
                                }
                              },
                        icon: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send, size: 16),
                        label: Text(isSaving ? 'Đang lưu...' : globalAppState.t('publish_chapter')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}