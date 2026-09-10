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
      builder: (ctx) => AlertDialog(
        title: Text('${globalAppState.t('edit_chapter_title')}: ${chap.title}'),
        content: SizedBox(
          width: 550,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: InputDecoration(labelText: globalAppState.t('chapter_title'), border: const OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: contentCtrl, maxLines: 8, decoration: InputDecoration(labelText: globalAppState.t('chapter_content'), border: const OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(globalAppState.t('cancel'))),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isComic = widget.story.type == 'comic';

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${globalAppState.t('manage_chapters')}: ${widget.story.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width > 650 ? 600 : double.infinity,
        height: 420,
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
                    subtitle: Text(isComic ? '$pageCount ${globalAppState.t('page_count_suffix')}' : '${chap.content.length} ${globalAppState.t('char_count_suffix')}'),
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
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(globalAppState.t('close')),
        ),
      ],
    );
  }
}