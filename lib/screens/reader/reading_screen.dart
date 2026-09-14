import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/safe_network_image.dart';

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

  // Cache ảnh Base64 đã giải mã sẵn sang Uint8List để không bị decode lại khi cuộn
  final Map<int, Uint8List> _decodedImageCache = {};

  bool isAutoScrolling = false;
  double autoScrollSpeed = 2.0;
  Timer? _autoScrollTimer;
  bool showControls = true;

  @override
  void initState() {
    super.initState();
    currentChapterIndex = widget.initialChapterIndex;
    fontSize = globalAppState.defaultFontSize;
    _cacheCurrentChapterImages();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      globalAppState.saveReadingProgress(widget.story.id, currentChapterIndex);
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // Giải mã trước toàn bộ ảnh cục bộ của chương hiện tại
  void _cacheCurrentChapterImages() {
    _decodedImageCache.clear();
    final chapter = widget.story.chapters[currentChapterIndex];
    for (int i = 0; i < chapter.imageUrls.length; i++) {
      final url = chapter.imageUrls[i];
      if (url.startsWith('data:image')) {
        try {
          final base64Content = url.split(',').last;
          _decodedImageCache[i] = base64Decode(base64Content);
        } catch (_) {}
      }
    }
  }

  void _toggleAutoScroll() {
    setState(() {
      isAutoScrolling = !isAutoScrolling;
    });

    if (isAutoScrolling) {
      _startAutoScroll();
    } else {
      _autoScrollTimer?.cancel();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      if (currentScroll >= maxScroll) {
        _toggleAutoScroll();
      } else {
        _scrollController.jumpTo(currentScroll + (autoScrollSpeed * 0.8));
      }
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
    if (isAutoScrolling) _toggleAutoScroll();
    setState(() {
      currentChapterIndex = newIdx;
      _cacheCurrentChapterImages();
    });
    globalAppState.saveReadingProgress(widget.story.id, newIdx);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _openCommentsSheet(BuildContext context) {
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final comments = globalAppState.getCommentsForChapter(widget.story.id, currentChapterIndex);
          final currentUsername = globalAppState.currentUser?.username ?? 'Khách';

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: SizedBox(
              height: 520,
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
                        : ListView.separated(
                            itemCount: comments.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final c = comments[i];
                              final isLiked = c.likedUsernames.contains(currentUsername);

                              return ListTile(
                                leading: CircleAvatar(child: Text(c.username[0].toUpperCase())),
                                title: Row(
                                  children: [
                                    Text(c.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(width: 8),
                                    if (c.reportCount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                        child: Text('${c.reportCount} cảnh báo', style: const TextStyle(color: Colors.redAccent, fontSize: 10)),
                                      ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(c.content),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined, size: 18, color: isLiked ? Colors.blueAccent : Colors.grey),
                                      tooltip: 'Thích',
                                      onPressed: () {
                                        globalAppState.toggleLikeComment(c.id);
                                        setSheetState(() {});
                                      },
                                    ),
                                    Text('${c.likedUsernames.length}', style: const TextStyle(fontSize: 12)),
                                    IconButton(
                                      icon: const Icon(Icons.flag_outlined, size: 18, color: Colors.grey),
                                      tooltip: 'Báo cáo vi phạm',
                                      onPressed: () {
                                        globalAppState.reportComment(c.id);
                                        setSheetState(() {});
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Đã gửi báo cáo vi phạm đến quản trị viên!'), duration: Duration(seconds: 1)),
                                        );
                                      },
                                    ),
                                  ],
                                ),
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
                            decoration: const InputDecoration(hintText: 'Viết bình luận cảm nghĩ...', border: OutlineInputBorder()),
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

  Widget _buildOptimizedImage(BuildContext context, int index, String url) {
    if (_decodedImageCache.containsKey(index)) {
      return Image.memory(
        _decodedImageCache[index]!,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const SizedBox(
          height: 120,
          child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 820 ? 820.0 : screenWidth;

    return SizedBox(
      width: contentWidth,
      child: Image.network(
        url,
        width: contentWidth,
        fit: BoxFit.fitWidth,
        gaplessPlayback: true,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: contentWidth,
            height: 350,
            color: Colors.black12,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: Colors.deepPurpleAccent,
              ),
            ),
          );
        },
        errorBuilder: (_, error, ___) => Container(
          width: contentWidth,
          height: 200,
          color: Colors.black26,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, size: 36, color: Colors.grey),
              const SizedBox(height: 6),
              Text(
                'Không thể tải ảnh trang ${index + 1}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapter = widget.story.chapters[currentChapterIndex];
    final isComic = widget.story.type == 'comic';

    return Scaffold(
      backgroundColor: _bgColor,
      // 1. DRAWER CÓ NÚT BACK VỀ TRANG CHI TIẾT
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepPurple),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mục Lục Chương',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          tooltip: 'Quay về trang thông tin truyện',
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    Text(
                      widget.story.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tổng số: ${widget.story.chapters.length} chương',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.deepPurpleAccent),
              title: const Text('Thông tin truyện & đánh giá'),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: widget.story.chapters.length,
                itemBuilder: (ctx, idx) {
                  final isCurrent = idx == currentChapterIndex;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCurrent ? Colors.deepPurple : Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      child: Text('${idx + 1}'),
                    ),
                    title: Text(
                      widget.story.chapters[idx].title,
                      style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal),
                    ),
                    trailing: isCurrent ? const Icon(Icons.bookmark, color: Colors.deepPurpleAccent) : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      _onChapterChanged(idx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // 2. APPBAR
      appBar: showControls
          ? AppBar(
              backgroundColor: _bgColor,
              elevation: 1,
              iconTheme: IconThemeData(color: _textColor),
              title: Text(chapter.title, style: TextStyle(color: _textColor, fontSize: 16)),
              actions: [
                IconButton(
                  icon: Icon(isAutoScrolling ? Icons.pause_circle_filled : Icons.play_circle_outline),
                  color: isAutoScrolling ? Colors.greenAccent : null,
                  tooltip: isAutoScrolling ? 'Dừng tự động cuộn' : 'Bật tự động cuộn',
                  onPressed: _toggleAutoScroll,
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  tooltip: 'Bình luận',
                  onPressed: () => _openCommentsSheet(context),
                ),
                if (!isComic) ...[
                  IconButton(
                    icon: const Icon(Icons.text_decrease),
                    onPressed: fontSize > 13 ? () => setState(() => fontSize -= 1.5) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.text_increase),
                    onPressed: fontSize < 30 ? () => setState(() => fontSize += 1.5) : null,
                  ),
                ],
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
            )
          : null,

      body: GestureDetector(
        onTap: () => setState(() => showControls = !showControls),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            if (isAutoScrolling && showControls)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: Colors.green.withValues(alpha: 0.15),
                child: Row(
                  children: [
                    const Icon(Icons.speed, size: 18, color: Colors.greenAccent),
                    const SizedBox(width: 8),
                    const Text('Tốc độ cuộn:', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: autoScrollSpeed,
                        min: 0.5,
                        max: 6.0,
                        divisions: 11,
                        onChanged: (v) {
                          setState(() => autoScrollSpeed = v);
                          _startAutoScroll();
                        },
                      ),
                    ),
                    Text('${autoScrollSpeed.toStringAsFixed(1)}x', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isComic ? 820 : 750),
                  child: isComic
                      ? ListView.builder(
                          key: ValueKey('comic-chap-$currentChapterIndex'),
                          controller: _scrollController,
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: chapter.imageUrls.length + 1,
                          itemBuilder: (context, index) {
                            if (index < chapter.imageUrls.length) {
                              return _buildOptimizedImage(context, index, chapter.imageUrls[index]);
                            }

                            final hasNext = currentChapterIndex < widget.story.chapters.length - 1;
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                              color: _bgColor,
                              child: Column(
                                children: [
                                  Text(
                                    hasNext ? 'Bạn đã đọc hết ${chapter.title}' : 'Bạn đã đọc đến chương mới nhất!',
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  if (hasNext)
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          backgroundColor: Colors.deepPurpleAccent,
                                        ),
                                        icon: const Icon(Icons.arrow_forward),
                                        label: Text(
                                          'Đọc tiếp: ${widget.story.chapters[currentChapterIndex + 1].title}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () => _onChapterChanged(currentChapterIndex + 1),
                                      ),
                                    )
                                  else
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.check_circle_outline),
                                      label: const Text('Quay về trang thông tin truyện'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                ],
                              ),
                            );
                          },
                        )
                      : SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chapter.content,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  color: _textColor,
                                  height: 1.8,
                                  letterSpacing: 0.2,
                                  fontFamily: globalAppState.fontFamily == 'Serif' ? 'serif' : null,
                                ),
                              ),
                              const SizedBox(height: 30),
                              const Divider(),
                              const SizedBox(height: 16),
                              if (currentChapterIndex < widget.story.chapters.length - 1)
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                                    icon: const Icon(Icons.arrow_forward),
                                    label: Text(
                                      'Chương tiếp theo: ${widget.story.chapters[currentChapterIndex + 1].title}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () => _onChapterChanged(currentChapterIndex + 1),
                                  ),
                                )
                              else
                                Center(
                                  child: Text(
                                    '🎉 Bạn đã đọc hết các chương hiện có!',
                                    style: TextStyle(color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            if (showControls)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _bgColor,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, -2)),
                  ],
                  border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.story.chapters.length > 1)
                      Row(
                        children: [
                          const Text('1', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Expanded(
                            child: Slider(
                              value: currentChapterIndex.toDouble(),
                              min: 0,
                              max: (widget.story.chapters.length - 1).toDouble(),
                              divisions: widget.story.chapters.length > 1 ? widget.story.chapters.length - 1 : 1,
                              onChanged: (v) => _onChapterChanged(v.toInt()),
                            ),
                          ),
                          Text('${widget.story.chapters.length}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: currentChapterIndex > 0 ? () => _onChapterChanged(currentChapterIndex - 1) : null,
                          icon: const Icon(Icons.chevron_left),
                          label: const Text('Chap trước'),
                        ),
                        Text(
                          '${currentChapterIndex + 1} / ${widget.story.chapters.length}',
                          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          onPressed: currentChapterIndex < widget.story.chapters.length - 1 ? () => _onChapterChanged(currentChapterIndex + 1) : null,
                          icon: const Icon(Icons.chevron_right),
                          label: const Text('Chap sau'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}