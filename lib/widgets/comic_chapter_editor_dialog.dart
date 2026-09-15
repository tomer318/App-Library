import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../services/supabase_service.dart';
import 'safe_network_image.dart';

class ComicChapterEditorDialog extends StatefulWidget {
  final Story story;
  final int? editChapterIndex;

  const ComicChapterEditorDialog({
    super.key,
    required this.story,
    this.editChapterIndex,
  });

  @override
  State<ComicChapterEditorDialog> createState() => _ComicChapterEditorDialogState();
}

class _ComicChapterEditorDialogState extends State<ComicChapterEditorDialog> {
  late TextEditingController titleCtrl;
  final TextEditingController urlInputCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<String> pages = [];
  bool isLoadingFiles = false;
  bool isSaving = false;
  String loadingProgress = '';

  @override
  void initState() {
    super.initState();
    if (widget.editChapterIndex != null) {
      final chap = widget.story.chapters[widget.editChapterIndex!];
      titleCtrl = TextEditingController(text: chap.title);
      pages = List<String>.from(chap.imageUrls);
    } else {
      titleCtrl = TextEditingController(text: 'Chương ${widget.story.chapters.length + 1}: ');
      pages = [];
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    urlInputCtrl.dispose();
    super.dispose();
  }

  // CHỌN NHIỀU ẢNH TỪ MÁY VÀ ĐẨY TRỰC TIẾP LÊN SUPABASE STORAGE BUCKET 'comic_pages'
  Future<void> _pickImagesFromDevice() async {
    setState(() {
      isLoadingFiles = true;
      loadingProgress = 'Đang chọn ảnh...';
    });

    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        final sortedList = pickedFiles.toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        setState(() {
          loadingProgress = 'Đang tải lên Supabase Storage (0/${sortedList.length})...';
        });

        int completed = 0;
        // Xác định thứ tự chương (nếu là tạo mới thì lấy tổng số chương hiện tại)
        final chapOrder = widget.editChapterIndex ?? widget.story.chapters.length;
        final chapTitle = titleCtrl.text.trim().isNotEmpty
            ? titleCtrl.text.trim()
            : 'Chap_${chapOrder + 1}';

        final uploadFutures = sortedList.map((file) async {
          final bytes = await file.readAsBytes();
          final url = await SupabaseService.uploadChapterImage(
            storyId: widget.story.id,
            storyTitle: widget.story.title,
            chapterOrder: chapOrder,
            chapterTitle: chapTitle,
            bytes: bytes,
            fileName: file.name,
          );
          completed++;
          if (mounted) {
            setState(() {
              loadingProgress = 'Đang tải lên Supabase Storage ($completed/${sortedList.length})...';
            });
          }
          return url;
        }).toList();

        final results = await Future.wait(uploadFutures);
        final validUrls = results.whereType<String>().toList();

        if (mounted) {
          setState(() {
            pages.addAll(validUrls);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải ảnh lên Storage: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingFiles = false;
          loadingProgress = '';
        });
      }
    }
  }

  void _addPagesFromUrl() {
    final rawText = urlInputCtrl.text.trim();
    if (rawText.isEmpty) return;

    final urls = rawText
        .split(RegExp(r'[\n,]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    setState(() {
      pages.addAll(urls);
      urlInputCtrl.clear();
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = pages.removeAt(oldIndex);
      pages.insert(newIndex, item);
    });
  }

  Widget _buildImageWidget(String pathOrUrl, {double? width, double? height, BoxFit fit = BoxFit.contain}) {
    if (pathOrUrl.startsWith('data:image')) {
      final base64Content = pathOrUrl.split(',').last;
      return Image.memory(
        base64Decode(base64Content),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 24),
      );
    }

    // Nếu ở cột Preview cuộn dọc (không có height cố định)
    if (height == null) {
      return Image.network(
        pathOrUrl,
        width: width ?? double.infinity,
        fit: BoxFit.fitWidth,
        gaplessPlayback: true,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 250,
            color: Colors.black12,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurpleAccent),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          height: 120,
          color: Colors.black26,
          child: const Center(
            child: Icon(Icons.broken_image, size: 28, color: Colors.grey),
          ),
        ),
      );
    }

    // Thumbnail nhỏ ở danh sách trang bên trái (có height và width xác định)
    return SafeNetworkImage(
      imageUrl: pathOrUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        width: MediaQuery.of(context).size.width > 900 ? 1150 : double.infinity,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.editChapterIndex == null
                            ? globalAppState.t('comic_studio_title')
                            : '${globalAppState.t('edit_comic_prefix')} ${widget.story.chapters[widget.editChapterIndex!].title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.story.title} • ${globalAppState.t('drag_drop_hint')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: isSaving ? null : () => Navigator.pop(context)),
              ],
            ),
            const Divider(height: 16),

            TextField(
              controller: titleCtrl,
              enabled: !isSaving,
              decoration: InputDecoration(
                labelText: globalAppState.t('chapter_title'),
                prefixIcon: const Icon(Icons.title),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Flex(
                direction: MediaQuery.of(context).size.width < 750 ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CỘT TRÁI: CHỌN ẢNH & KÉO THẢ
                  Expanded(
                    flex: 5,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: (isLoadingFiles || isSaving) ? null : _pickImagesFromDevice,
                                    icon: isLoadingFiles
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Icon(Icons.folder_open),
                                    label: Text(isLoadingFiles ? loadingProgress : globalAppState.t('browse_device')),
                                    style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: urlInputCtrl,
                                    enabled: !isSaving,
                                    decoration: InputDecoration(
                                      hintText: globalAppState.t('or_image_url'),
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    onSubmitted: (_) => _addPagesFromUrl(),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                OutlinedButton(
                                  onPressed: isSaving ? null : _addPagesFromUrl,
                                  child: Text(globalAppState.t('add_link')),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${globalAppState.t('page_list')} (${pages.length}):',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                if (pages.isNotEmpty)
                                  TextButton(
                                    onPressed: isSaving ? null : () => setState(() => pages.clear()),
                                    child: Text(
                                      globalAppState.t('clear_all'),
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            Expanded(
                              child: pages.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey),
                                          const SizedBox(height: 6),
                                          Text(globalAppState.t('no_pages_yet'), style: const TextStyle(color: Colors.grey)),
                                          const SizedBox(height: 8),
                                          OutlinedButton.icon(
                                            onPressed: isSaving ? null : _pickImagesFromDevice,
                                            icon: const Icon(Icons.upload_file),
                                            label: Text(globalAppState.t('browse_device')),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ReorderableListView.builder(
                                      onReorder: _onReorder,
                                      itemCount: pages.length,
                                      itemBuilder: (context, index) {
                                        final item = pages[index];
                                        final isBase64 = item.startsWith('data:image');

                                        return Card(
                                          key: ValueKey('$index-${item.hashCode}'),
                                          margin: const EdgeInsets.symmetric(vertical: 3),
                                          elevation: 1,
                                          child: ListTile(
                                            dense: true,
                                            leading: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.drag_handle, color: Colors.grey, size: 18),
                                                const SizedBox(width: 6),
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(4),
                                                  child: _buildImageWidget(item, width: 36, height: 46),
                                                ),
                                              ],
                                            ),
                                            title: Text(
                                              '${globalAppState.t('page_number_prefix')} ${index + 1}',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Text(
                                              isBase64 ? globalAppState.t('device_image_label') : item,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                              tooltip: globalAppState.t('clear_all'),
                                              onPressed: isSaving ? null : () => setState(() => pages.removeAt(index)),
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
                  ),

                  const SizedBox(width: 12),

                  // CỘT PHẢI: PREVIEW CUỘN DỌC LIÊN TỤC KHÔNG KHOẢNG HỞ
                  Expanded(
                    flex: 5,
                    child: Card(
                      color: const Color(0xFF141414),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            color: Colors.black45,
                            child: Row(
                              children: [
                                const Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.deepPurpleAccent),
                                const SizedBox(width: 6),
                                Text(globalAppState.t('preview_screen'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: pages.isEmpty
                                ? Center(child: Text(globalAppState.t('no_preview_images'), style: const TextStyle(color: Colors.grey)))
                                : ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: pages.length,
                                    itemBuilder: (context, index) {
                                      return Stack(
                                        alignment: Alignment.topRight,
                                        children: [
                                          _buildImageWidget(pages[index]),
                                          Container(
                                            margin: const EdgeInsets.all(6),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black87,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${globalAppState.t('page_number_prefix')} ${index + 1}',
                                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // BƯỚC 3 ĐÃ SỬA: ASYNC-AWAIT VỚI TIẾN TRÌNH LƯU
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: Text(globalAppState.t('cancel')),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: Text(
                    isSaving
                        ? 'Đang lưu lên Cloud...'
                        : (widget.editChapterIndex == null
                            ? globalAppState.t('publish_chapter')
                            : globalAppState.t('save_changes')),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final title = titleCtrl.text.trim();
                          if (title.isNotEmpty && pages.isNotEmpty) {
                            setState(() => isSaving = true);
                            try {
                              if (widget.editChapterIndex == null) {
                                await globalAppState.addChapterToStory(
                                  widget.story.id,
                                  title,
                                  imageUrls: pages,
                                );
                              } else {
                                await globalAppState.updateChapter(
                                  widget.story.id,
                                  widget.editChapterIndex!,
                                  title,
                                  imageUrls: pages,
                                );
                              }
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi khi lưu chương: $e'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => isSaving = false);
                            }
                          } else if (pages.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(globalAppState.t('alert_add_least_one'))),
                            );
                          }
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}