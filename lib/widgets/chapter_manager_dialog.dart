import 'package:flutter/material.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'comic_chapter_editor_dialog.dart';

class ChapterManagerDialog extends StatefulWidget {
  final Story story;

  const ChapterManagerDialog({super.key, required this.story});

  @override
  State<ChapterManagerDialog> createState() => _ChapterManagerDialogState();
}

class _ChapterManagerDialogState extends State<ChapterManagerDialog> {
  void _editNovelChapter(int index) {
    final chap = widget.story.chapters[index];
    final titleCtrl = TextEditingController(text: chap.title);
    final contentCtrl = TextEditingController(text: chap.content);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 550,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${globalAppState.t('edit_chapter_title')}: ${chap.title}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: globalAppState.t('chapter_title'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: globalAppState.t('chapter_content'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(globalAppState.t('cancel')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      globalAppState.updateChapter(
                        widget.story.id,
                        index,
                        titleCtrl.text.trim(),
                        content: contentCtrl.text.trim(),
                      );
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    child: Text(globalAppState.t('save_changes')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isComic = widget.story.type == 'comic';
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 650 ? 600.0 : (screenWidth * 0.92);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        height: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // HEADER CÓ TIÊU ĐỀ VÀ NÚT ĐÓNG
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${globalAppState.t('manage_chapters')}: ${widget.story.title}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 20),

            // DANH SÁCH CHƯƠNG (EXPANDED CUỘN AN TOÀN)
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
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(chap.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            isComic
                                ? '$pageCount ${globalAppState.t('page_count_suffix')}'
                                : '${chap.content.length} ${globalAppState.t('char_count_suffix')}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.amber),
                                tooltip: globalAppState.t('edit_chapter_tooltip'),
                                onPressed: () {
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
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                tooltip: globalAppState.t('delete_chapter_tooltip'),
                                onPressed: () {
                                  globalAppState.deleteChapter(widget.story.id, index);
                                  setState(() {});
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
                onPressed: () => Navigator.pop(context),
                child: Text(globalAppState.t('close')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}