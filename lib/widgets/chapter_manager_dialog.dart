import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/novel_parser.dart';
import 'comic_chapter_editor_dialog.dart';

class ChapterManagerDialog extends StatefulWidget {
  final Story story;

  const ChapterManagerDialog({super.key, required this.story});

  @override
  State<ChapterManagerDialog> createState() => _ChapterManagerDialogState();
}

class _ChapterManagerDialogState extends State<ChapterManagerDialog> {
  bool _isImporting = false;
  bool _isSavingBatch = false;

  // HỘP THOẠI SOẠN THẢO / CHỈNH SỬA MỘT CHƯƠNG NOVEL
  void _editNovelChapter(int index) {
    final chap = widget.story.chapters[index];
    final titleCtrl = TextEditingController(text: chap.title);
    final contentCtrl = TextEditingController(text: chap.content);
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final wordsCount = contentCtrl.text.trim().isEmpty
              ? 0
              : contentCtrl.text.trim().split(RegExp(r'\s+')).length;
          final charsCount = contentCtrl.text.length;

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
                              '${globalAppState.t('edit_chapter_title')}: ${chap.title}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.story.title} • Chỉnh sửa nội dung chương chữ',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: isSaving ? null : () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

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
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.text_fields, size: 14, color: Colors.amber),
                            const SizedBox(width: 6),
                            Text(
                              '$charsCount ký tự • $wordsCount từ',
                              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: TextField(
                      controller: contentCtrl,
                      enabled: !isSaving,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(fontSize: 15, height: 1.6),
                      decoration: const InputDecoration(
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
                        onPressed: isSaving ? null : () => Navigator.pop(ctx),
                        child: Text(globalAppState.t('cancel')),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          backgroundColor: Colors.deepPurple,
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final title = titleCtrl.text.trim();
                                final content = contentCtrl.text.trim();

                                if (title.isNotEmpty && content.isNotEmpty) {
                                  setDialogState(() => isSaving = true);
                                  try {
                                    await globalAppState.updateChapter(
                                      widget.story.id,
                                      index,
                                      title,
                                      content: content,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(ctx);
                                      setState(() {});
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
                            : const Icon(Icons.save, size: 16),
                        label: Text(isSaving ? 'Đang lưu...' : globalAppState.t('save_changes')),
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

  // HỘP THOẠI THÊM THỦ CÔNG 1 CHƯƠNG CHỮ
  void _showAddSingleNovelChapter() {
    final titleCtrl = TextEditingController(text: 'Chương ${widget.story.chapters.length + 1}: ');
    final contentCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final wordsCount = contentCtrl.text.trim().isEmpty
              ? 0
              : contentCtrl.text.trim().split(RegExp(r'\s+')).length;
          final charsCount = contentCtrl.text.length;

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
                        child: Text(
                          '${globalAppState.t('add_chapter')}: ${widget.story.title}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: isSaving ? null : () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  TextField(
                    controller: titleCtrl,
                    enabled: !isSaving,
                    decoration: InputDecoration(
                      labelText: globalAppState.t('chapter_title'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$charsCount ký tự • $wordsCount từ',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: TextField(
                      controller: contentCtrl,
                      enabled: !isSaving,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Nhập nội dung chương vào đây...',
                        contentPadding: EdgeInsets.all(16),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSaving ? null : () => Navigator.pop(ctx),
                        child: Text(globalAppState.t('cancel')),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final t = titleCtrl.text.trim();
                                final c = contentCtrl.text.trim();
                                if (t.isNotEmpty && c.isNotEmpty) {
                                  setDialogState(() => isSaving = true);
                                  await globalAppState.addChapterToStory(widget.story.id, t, content: c);
                                  if (context.mounted) {
                                    Navigator.pop(ctx);
                                    setState(() {});
                                  }
                                }
                              },
                        child: Text(isSaving ? 'Đang lưu...' : globalAppState.t('publish_chapter')),
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

  // TÍNH NĂNG NHẬP HÀNG LOẠT CHƯƠNG TỪ FILE .TXT VÀO BỘ TRUYỆN
  Future<void> _importChaptersFromTxt() async {
    final picker = ImagePicker();
    final file = await picker.pickMedia();
    if (file == null) return;

    setState(() => _isImporting = true);
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy nội dung chương hợp lệ trong file!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
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
                  'Hệ thống sẽ thêm danh sách các chương sau vào truyện:',
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
        setState(() => _isSavingBatch = true);
        for (final ch in parsedChapters) {
          await globalAppState.addChapterToStory(widget.story.id, ch.title, content: ch.content);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thêm thành công ${parsedChapters.length} chương vào truyện!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đọc file: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _isSavingBatch = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isComic = widget.story.type == 'comic';
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 800 ? 750.0 : (screenWidth * 0.95);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFF1E1E26),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        height: 560,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // HEADER CÓ TIÊU ĐỀ VÀ NÚT ĐÓNG
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${globalAppState.t('manage_chapters')}: ${widget.story.title}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.story.chapters.length} chương • ${widget.story.type == 'comic' ? 'Truyện Tranh' : 'Truyện Chữ'}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: (_isImporting || _isSavingBatch) ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 20),

            // THANH CÔNG CỤ: NÚT THÊM CHƯƠNG & NÚT NHẬP TXT HÀNG LOẠT
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(globalAppState.t('add_chapter')),
                  onPressed: (_isImporting || _isSavingBatch)
                      ? null
                      : () {
                          if (isComic) {
                            showDialog(
                              context: context,
                              builder: (_) => ComicChapterEditorDialog(story: widget.story),
                            ).then((_) => setState(() {}));
                          } else {
                            _showAddSingleNovelChapter();
                          }
                        },
                ),

                // Nút Nhập TXT chỉ áp dụng cho Novel
                if (!isComic)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.tealAccent,
                      side: const BorderSide(color: Colors.tealAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: _isImporting || _isSavingBatch
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.tealAccent),
                          )
                        : const Icon(Icons.upload_file, size: 16),
                    label: Text(
                      _isSavingBatch
                          ? 'Đang lưu...'
                          : (_isImporting ? 'Đang đọc file...' : 'Nhập tự động từ file .txt'),
                    ),
                    onPressed: (_isImporting || _isSavingBatch) ? null : _importChaptersFromTxt,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // DANH SÁCH CHƯƠNG
            Expanded(
              child: widget.story.chapters.isEmpty
                  ? Center(child: Text(globalAppState.t('no_chapters_yet')))
                  : ListView.separated(
                      itemCount: widget.story.chapters.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, index) {
                        final chap = widget.story.chapters[index];
                        final pageCount = chap.imageUrls.length;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.black38,
                            child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
                          ),
                          title: Text(chap.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                            isComic
                                ? '$pageCount ${globalAppState.t('page_count_suffix')}'
                                : '${chap.content.length} ${globalAppState.t('char_count_suffix')}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.amber, size: 20),
                                tooltip: globalAppState.t('edit_chapter_tooltip'),
                                onPressed: (_isImporting || _isSavingBatch)
                                    ? null
                                    : () {
                                        if (isComic) {
                                          showDialog(
                                            context: context,
                                            builder: (_) => ComicChapterEditorDialog(
                                              story: widget.story,
                                              editChapterIndex: index,
                                            ),
                                          ).then((_) => setState(() {}));
                                        } else {
                                          _editNovelChapter(index);
                                        }
                                      },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                tooltip: globalAppState.t('delete_chapter_tooltip'),
                                onPressed: (_isImporting || _isSavingBatch)
                                    ? null
                                    : () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (dialogCtx) => AlertDialog(
                                            backgroundColor: const Color(0xFF1E1E26),
                                            title: const Text('Xác nhận xóa chương'),
                                            content: Text('Bạn có chắc muốn xóa "${chap.title}"? Dữ liệu chương và toàn bộ ảnh lưu trữ sẽ bị xóa vĩnh viễn.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(dialogCtx, false),
                                                child: const Text('Hủy'),
                                              ),
                                              FilledButton(
                                                style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                                                onPressed: () => Navigator.pop(dialogCtx, true),
                                                child: const Text('Xóa chương'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await globalAppState.deleteChapter(widget.story.id, index);
                                          if (mounted) setState(() {});
                                        }
                                      },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 20),

            // FOOTER NÚT ĐÓNG
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: (_isImporting || _isSavingBatch) ? null : () => Navigator.pop(context),
                child: Text(globalAppState.t('close')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}