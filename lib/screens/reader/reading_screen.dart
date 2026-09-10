import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

enum PaperTheme { light, sepia, dark }

class ReadingScreen extends StatefulWidget {
  final Story story;
  final int initialChapterIndex;

  const ReadingScreen({super.key, required this.story, required this.initialChapterIndex});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late int currentChapterIndex;
  late double fontSize;
  PaperTheme paperTheme = PaperTheme.dark;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    currentChapterIndex = widget.initialChapterIndex;
    fontSize = globalAppState.defaultFontSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      globalAppState.saveReadingProgress(widget.story.id, currentChapterIndex);
    });
  }

  Color get _bgColor {
    switch (paperTheme) {
      case PaperTheme.light: return Colors.white;
      case PaperTheme.sepia: return const Color(0xFFFBF0D9);
      case PaperTheme.dark: return const Color(0xFF181818);
    }
  }

  Color get _textColor {
    switch (paperTheme) {
      case PaperTheme.light: return Colors.black87;
      case PaperTheme.sepia: return const Color(0xFF5F4B32);
      case PaperTheme.dark: return Colors.grey.shade300;
    }
  }

  void _onChapterChanged(int newIdx) {
    setState(() => currentChapterIndex = newIdx);
    globalAppState.saveReadingProgress(widget.story.id, newIdx);
    _scrollController.jumpTo(0);
  }

  void _openCommentsSheet(BuildContext context) {
    final commentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final comments = globalAppState.getCommentsForChapter(widget.story.id, currentChapterIndex);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: SizedBox(
              height: 480,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bình luận (${comments.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: comments.isEmpty
                        ? const Center(child: Text('Chưa có bình luận nào. Hãy là người đầu tiên!', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: comments.length,
                            itemBuilder: (_, i) {
                              final c = comments[i];
                              return ListTile(
                                leading: CircleAvatar(child: Text(c.username[0].toUpperCase())),
                                title: Text(c.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: Text(c.content),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentCtrl,
                            decoration: const InputDecoration(hintText: 'Viết bình luận...', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          icon: const Icon(Icons.send),
                          onPressed: () {
                            if (commentCtrl.text.trim().isNotEmpty) {
                              globalAppState.addComment(widget.story.id, currentChapterIndex, commentCtrl.text.trim());
                              commentCtrl.clear();
                              setSheetState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapter = widget.story.chapters[currentChapterIndex];

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 1,
        iconTheme: IconThemeData(color: _textColor),
        title: Text(chapter.title, style: TextStyle(color: _textColor, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Xem bình luận',
            onPressed: () => _openCommentsSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: fontSize > 13 ? () => setState(() => fontSize -= 1.5) : null,
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: fontSize < 30 ? () => setState(() => fontSize += 1.5) : null,
          ),
          PopupMenuButton<PaperTheme>(
            icon: const Icon(Icons.color_lens_outlined),
            onSelected: (theme) => setState(() => paperTheme = theme),
            itemBuilder: (_) => const [
              PopupMenuItem(value: PaperTheme.light, child: Text('Giấy Trắng')),
              PopupMenuItem(value: PaperTheme.sepia, child: Text('Giấy Vàng Sepia')),
              PopupMenuItem(value: PaperTheme.dark, child: Text('Giấy Đen Dark')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 750),
                  child: Text(
                    chapter.content,
                    style: TextStyle(fontSize: fontSize, color: _textColor, height: 1.8, letterSpacing: 0.2),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _bgColor,
              border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: currentChapterIndex > 0 ? () => _onChapterChanged(currentChapterIndex - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Chap trước'),
                ),
                Text('${currentChapterIndex + 1} / ${widget.story.chapters.length}', style: TextStyle(color: _textColor, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: currentChapterIndex < widget.story.chapters.length - 1 ? () => _onChapterChanged(currentChapterIndex + 1) : null,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Chap sau'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}