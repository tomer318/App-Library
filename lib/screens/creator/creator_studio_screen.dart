import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../services/supabase_service.dart';
import '../../utils/novel_parser.dart';
import '../../widgets/comic_chapter_editor_dialog.dart';
import '../../widgets/chapter_manager_dialog.dart';
import '../../widgets/safe_network_image.dart';

class CreatorStudioScreen extends StatelessWidget {
  const CreatorStudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = globalAppState;
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        // 1. CHẶN TRUY CẬP TRÊN ĐIỆN THOẠI - YÊU CẦU MÁY TÍNH
        if (!isDesktop) {
          return Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.laptop_chromebook, size: 70, color: Colors.deepPurpleAccent),
                    const SizedBox(height: 16),
                    Text(
                      state.language == 'vi' ? 'Yêu Cầu Máy Tính' : 'Desktop Required',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      state.language == 'vi'
                          ? 'Để đảm bảo trải nghiệm quản lý, tải ảnh và biên tập nội dung tốt nhất, tính năng Creator Studio chỉ khả dụng trên màn hình máy tính (Desktop/Laptop).'
                          : 'To ensure the best experience for content creation, image uploads, and chapter management, Creator Studio is only available on desktop browsers.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, height: 1.5, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 2. GIAO DIỆN SÁNG TÁC TRÊN MÁY TÍNH
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(state.t('studio_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            Text(state.t('studio_subtitle'), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(state.t('add_new_story')),
                        onPressed: () => _showAddOrEditStoryDialog(context),
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
                                Text(
                                  state.language == 'vi'
                                      ? 'Bạn chưa có tác phẩm nào. Hãy bấm "Thêm Truyện Mới" để bắt đầu!'
                                      : 'You have no published stories yet. Click "Add New Story" to start!',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.tonal(
                                  onPressed: () => _showAddOrEditStoryDialog(context),
                                  child: Text(state.t('add_new_story')),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: myStories.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final story = myStories[index];
                              final mainTag = story.tags.isNotEmpty ? story.tags.first : 'Khác';

                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: SafeNetworkImage(
                                          imageUrl: story.coverUrl,
                                          width: 55,
                                          height: 75,
                                          fit: BoxFit.cover,
                                        ),
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
                                                  label: Text(story.type == 'comic' ? state.t('manga') : state.t('novel'), style: const TextStyle(fontSize: 10)),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                                const SizedBox(width: 6),
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
                                            const SizedBox(height: 4),
                                            Text(
                                              '${state.tGenre(mainTag)} • ${story.chapters.length} ${state.t('chaps_count_suffix')} • 👁️ ${story.viewCount}',
                                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // NÚT CHỈNH SỬA THÔNG TIN TRUYỆN
                                      IconButton.filledTonal(
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.amber.withValues(alpha: 0.2),
                                          foregroundColor: Colors.amber,
                                        ),
                                        icon: const Icon(Icons.edit_note),
                                        tooltip: state.t('edit_story'),
                                        onPressed: () => _showAddOrEditStoryDialog(context, existingStory: story),
                                      ),
                                      const SizedBox(width: 6),

                                      // NÚT QUẢN LÝ CÁC CHƯƠNG
                                      IconButton.filledTonal(
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.teal.withValues(alpha: 0.2),
                                          foregroundColor: Colors.tealAccent,
                                        ),
                                        icon: const Icon(Icons.format_list_bulleted),
                                        tooltip: state.t('manage_chapters'),
                                        onPressed: () => showDialog(
                                          context: context,
                                          builder: (_) => ChapterManagerDialog(story: story),
                                        ),
                                      ),
                                      const SizedBox(width: 6),

                                      // NÚT THÊM CHƯƠNG MỚI
                                      IconButton.filledTonal(
                                        icon: const Icon(Icons.post_add),
                                        tooltip: state.t('add_chapter'),
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
      },
    );
  }

  // HỘP THOẠI TẠO HOẶC CHỈNH SỬA THÔNG TIN TRUYỆN (KÈM BỘ CHỌN NGÔN NGỮ VI/EN)
  void _showAddOrEditStoryDialog(BuildContext context, {Story? existingStory}) {
    final state = globalAppState;
    final assignedStoryId = existingStory?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final titleCtrl = TextEditingController(text: existingStory?.title ?? '');
    final coverCtrl = TextEditingController(text: existingStory?.coverUrl ?? '');
    final descCtrl = TextEditingController(text: existingStory?.description ?? '');
    final yearCtrl = TextEditingController(text: (existingStory?.releaseYear ?? 2024).toString());

    String storyType = existingStory?.type ?? 'novel';
    String storyLang = existingStory?.language ?? 'vi'; // 'vi' hoặc 'en'
    List<String> selectedTags = List<String>.from(existingStory?.tags ?? ['Tâm linh']);
    bool isUploadingCover = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E26),
          title: Text(existingStory == null ? state.t('add_new_story') : state.t('edit_story')),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: titleCtrl,
                          decoration: InputDecoration(labelText: state.t('story_title'), border: const OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 140,
                        child: TextField(
                          controller: yearCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: state.t('release_year'), border: const OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // CHỌN LOẠI TRUYỆN: NOVEL HOẶC MANGA
                  Text(
                    state.language == 'vi' ? 'Phân loại tác phẩm:' : 'Story Type:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'novel', label: Text(state.t('novel')), icon: const Icon(Icons.menu_book, size: 16)),
                        ButtonSegment(value: 'comic', label: Text(state.t('manga')), icon: const Icon(Icons.photo_library, size: 16)),
                      ],
                      selected: {storyType},
                      onSelectionChanged: (val) => setModalState(() => storyType = val.first),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // BỘ CHỌN NGÔN NGỮ GỐC CỦA BỘ TRUYỆN (HIỂN THỊ CỜ TRÊN ẢNH)
                  Text(
                    state.language == 'vi' ? 'Ngôn ngữ hiển thị của truyện:' : 'Story Language:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
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
                  const SizedBox(height: 12),

                  // TẢI ẢNH BÌA HOẶC DÁN URL
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: coverCtrl,
                          readOnly: isUploadingCover,
                          decoration: InputDecoration(
                            labelText: state.t('cover_url'),
                            border: const OutlineInputBorder(),
                            hintText: isUploadingCover ? 'Đang tải lên...' : 'https://...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: isUploadingCover
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.upload_file),
                        label: const Text('Browse'),
                        onPressed: isUploadingCover
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final picker = ImagePicker();
                                final file = await picker.pickImage(source: ImageSource.gallery);
                                if (file == null) return;

                                setModalState(() => isUploadingCover = true);

                                final bytes = await file.readAsBytes();
                                final ext = file.name.split('.').last.toLowerCase();

                                final rawTitle = titleCtrl.text.trim();
                                final curTitle = rawTitle.isNotEmpty ? rawTitle : 'new_story';
                                final storyId = assignedStoryId;
                                    DateTime.now().millisecondsSinceEpoch.toString();

                                final uploadedUrl = await SupabaseService.uploadCoverImage(
                                  bytes,
                                  ext,
                                  storyTitle: curTitle,
                                  storyId: storyId,
                                );

                                setModalState(() {
                                  isUploadingCover = false;
                                  if (uploadedUrl != null) {
                                    coverCtrl.text = uploadedUrl;
                                  } else {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Lỗi tải ảnh lên Supabase! Vui lòng thử lại.'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                });
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // CHỌN CÁC TAGS THỂ LOẠI
                  Text(
                    state.language == 'vi' ? 'Chọn các Tag thể loại:' : 'Select Genre Tags:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: state.masterTags.map((tag) {
                      final isSel = selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(state.tGenre(tag), style: const TextStyle(fontSize: 11)),
                        selected: isSel,
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
                      labelText: state.t('description'),
                      hintText: state.language == 'vi' ? 'Nhập tóm tắt truyện (tối đa 750 chữ)...' : 'Enter synopsis (max 750 chars)...',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(state.t('cancel'))),
            FilledButton(
              onPressed: isUploadingCover
                  ? null
                  : () {
                      final title = titleCtrl.text.trim();
                      if (title.isNotEmpty) {
                        final year = int.tryParse(yearCtrl.text.trim()) ?? 2024;
                        final cover = coverCtrl.text.trim().isEmpty
                            ? 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400&q=80'
                            : coverCtrl.text.trim();
                        final desc = descCtrl.text.trim();
                        final tags = selectedTags.isEmpty ? ['Khác'] : selectedTags;

                        if (existingStory == null) {
                          state.addStory(
                            Story(
                              id: assignedStoryId, // DÙNG CHUNG ID VỚI FOLDER STORAGE
                              title: title,
                              author: state.currentUser?.username ?? 'Ẩn danh',
                              tags: tags,
                              releaseYear: year,
                              language: storyLang,
                              coverUrl: cover,
                              description: desc,
                              type: storyType,
                              creatorId: state.currentUser?.id ?? 'u_author',
                              chapters: [],
                            ),
                          );
                        } else {
                          existingStory.type = storyType;
                          existingStory.language = storyLang;
                          state.updateStory(
                            existingStory.id,
                            title,
                            existingStory.author,
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
              child: Text(state.t('save_changes')),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChapterDialog(BuildContext context, Story story) {
    final state = globalAppState;
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

          // HÀM CHỌN VÀ NHẬP TỰ ĐỘNG TỪ FILE TXT
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
                    await state.addChapterToStory(story.id, ch.title, content: ch.content);
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
                              '${state.t('add_chapter')}: ${story.title}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              state.language == 'vi'
                                  ? 'Soạn thảo nội dung chương tiểu thuyết'
                                  : 'Novel Chapter Studio Editor',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
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
                      labelText: state.t('chapter_title'),
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
                      decoration: InputDecoration(
                        hintText: state.language == 'vi'
                            ? 'Nhập hoặc dán nội dung văn bản của chương vào đây, hoặc nhấn nút "Nhập tự động từ file .txt" ở trên...'
                            : 'Enter or paste chapter content here, or click "Import from .txt" above...',
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                        contentPadding: const EdgeInsets.all(16),
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
                        child: Text(state.t('cancel')),
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
                                    await state.addChapterToStory(
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
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Vui lòng nhập đầy đủ tiêu đề và nội dung chương!'),
                                    ),
                                  );
                                }
                              },
                        icon: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send, size: 16),
                        label: Text(isSaving ? 'Đang lưu...' : state.t('publish_chapter')),
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