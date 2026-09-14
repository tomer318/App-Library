import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/auth_dialog.dart';
import '../reader/reading_screen.dart';
import '../../widgets/safe_network_image.dart';

class StoryDetailScreen extends StatelessWidget {
  final Story story;
  const StoryDetailScreen({super.key, required this.story});

  void _onFavoritePressed(BuildContext context, AppState state) {
    if (state.currentUser == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Yêu cầu đăng nhập'),
          content: const Text('Vui lòng đăng nhập để lưu truyện vào Tủ Sách cá nhân!'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                showDialog(context: context, builder: (_) => const AuthDialog());
              },
              child: const Text('Đăng Nhập'),
            ),
          ],
        ),
      );
    } else {
      state.toggleFavorite(story.id);
    }
  }

  void _showRatingDialog(BuildContext context, Story currentStory) {
    if (globalAppState.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để đánh giá truyện!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int selectedStars = 5;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Đánh giá truyện', textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentStory.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starNum = index + 1;
                    return IconButton(
                      icon: Icon(
                        starNum <= selectedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () {
                        setDialogState(() => selectedStars = starNum);
                      },
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Text(
                  '$selectedStars / 5 Sao',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
                onPressed: () async {
                  await globalAppState.rateStory(currentStory.id, selectedStars);
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Bạn đã đánh giá $selectedStars sao cho truyện!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Gửi đánh giá'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = globalAppState;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final currentStory = state.stories.firstWhere(
          (s) => s.id == story.id,
          orElse: () => story,
        );

        final isFav = state.isFavorite(currentStory.id);
        final lastReadIndex = state.getLastReadChapterIndex(currentStory.id);
        final hasChapters = currentStory.chapters.isNotEmpty;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.redAccent : Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () => _onFavoritePressed(context, state),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // 1. HERO BANNER BLUR HEADER
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Ảnh nền làm mờ bao phủ
                    Container(
                      height: 380,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (currentStory.coverUrl.isNotEmpty)
                            Image.network(
                              currentStory.coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(),
                            ),
                          BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.72),
                            ),
                          ),
                          // Gradient phủ tối dần xuống thân trang
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                                  Theme.of(context).scaffoldBackgroundColor,
                                ],
                                stops: const [0.3, 0.8, 1.0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Khối nội dung chính đè lên Hero
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 90, 24, 0),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Ảnh bìa chính thức
                                  Hero(
                                    tag: 'cover-${currentStory.id}',
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            blurRadius: 18,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SafeNetworkImage(
                                          imageUrl: currentStory.coverUrl,
                                          width: MediaQuery.of(context).size.width < 500 ? 120 : 170,
                                          height: MediaQuery.of(context).size.width < 500 ? 170 : 240,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),

                                  // Cột thông tin truyện
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentStory.title,
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Tác giả: ${currentStory.author}',
                                          style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
                                        ),
                                        const SizedBox(height: 10),

                                        // Thay thế khối InkWell cũ bằng đoạn code bọc Wrap/FittedBox gọn gàng:
                                        InkWell(
                                          onTap: () => _showRatingDialog(context, currentStory),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withValues(alpha: 0.15),
                                              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Wrap(
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              spacing: 4,
                                              runSpacing: 2,
                                              children: [
                                                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                                Text(
                                                  '${currentStory.averageRating.toStringAsFixed(1)}/5.0',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.amber,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Text(
                                                  '(${currentStory.ratings.length} vote)',
                                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                                ),
                                                const Icon(Icons.edit_note, size: 15, color: Colors.amber),
                                              ],
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 14),

                                        // Badge Meta (Năm, Số chương, Thể loại)
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            _buildBadge(
                                              icon: Icons.calendar_today,
                                              label: '${currentStory.releaseYear}',
                                              color: Colors.blueGrey,
                                            ),
                                            _buildBadge(
                                              icon: Icons.library_books,
                                              label: '${currentStory.chapters.length} chương',
                                              color: Colors.teal,
                                            ),
                                            _buildBadge(
                                              icon: currentStory.type == 'comic' ? Icons.photo_library : Icons.menu_book,
                                              label: currentStory.type == 'comic' ? 'Manga / Comic' : 'Tiểu Thuyết',
                                              color: Colors.purple,
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 10),

                                        // Tags Thể Loại
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: currentStory.tags.map((tag) {
                                            return ActionChip(
                                              visualDensity: VisualDensity.compact,
                                              avatar: const Icon(Icons.tag, size: 13, color: Colors.deepPurpleAccent),
                                              label: Text(tag, style: const TextStyle(fontSize: 11)),
                                              onPressed: () {
                                                state.setSingleTagFilter(tag);
                                                Navigator.pop(context);
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // CỤM NÚT CALL-TO-ACTION (CTA)
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        backgroundColor: Colors.deepPurple,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.menu_book),
                                      label: Text(
                                        lastReadIndex != null ? 'ĐỌC TIẾP (CHAP ${lastReadIndex + 1})' : 'ĐỌC TỪ ĐẦU',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      onPressed: hasChapters
                                          ? () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ReadingScreen(
                                                    story: currentStory,
                                                    initialChapterIndex: lastReadIndex ?? 0,
                                                  ),
                                                ),
                                              )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 1,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        side: BorderSide(
                                          color: isFav ? Colors.redAccent : Colors.grey.shade600,
                                        ),
                                      ),
                                      icon: Icon(
                                        isFav ? Icons.favorite : Icons.favorite_border,
                                        color: isFav ? Colors.redAccent : Colors.white,
                                      ),
                                      label: Text(
                                        isFav ? 'ĐÃ LƯU' : 'LƯU TRUYỆN',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isFav ? Colors.redAccent : Colors.white,
                                        ),
                                      ),
                                      onPressed: () => _onFavoritePressed(context, state),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // 2. KHỐI THÂN TRANG (TÓM TẮT & DANH SÁCH CHƯƠNG)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Khối giới thiệu nội dung
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E26),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.auto_stories, size: 18, color: Colors.deepPurpleAccent),
                                    const SizedBox(width: 8),
                                    Text('Tóm Tắt Nội Dung', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  currentStory.description.trim().isEmpty
                                      ? 'Chưa có tóm tắt chi tiết cho truyện này.'
                                      : currentStory.description,
                                  style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey.shade300),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Tiêu đề danh sách chương
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.format_list_bulleted, size: 20, color: Colors.deepPurpleAccent),
                                  const SizedBox(width: 8),
                                  const Text('Danh Sách Chương', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${currentStory.chapters.length}',
                                      style: const TextStyle(color: Colors.deepPurpleAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Grid / List các chương
                          if (!hasChapters)
                            Container(
                              padding: const EdgeInsets.all(32),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text('Truyện này hiện chưa có chương nào được cập nhật.', style: TextStyle(color: Colors.grey)),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: currentStory.chapters.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 6),
                              itemBuilder: (ctx, idx) {
                                final chap = currentStory.chapters[idx];
                                final isCurrentReading = lastReadIndex == idx;
                                final commentsCount = state.getCommentsForChapter(currentStory.id, idx).length;

                                return Material(
                                  color: isCurrentReading
                                      ? Colors.deepPurple.withValues(alpha: 0.18)
                                      : const Color(0xFF1E1E26),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: isCurrentReading ? Colors.deepPurpleAccent : Colors.white10,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: isCurrentReading ? Colors.deepPurple : Colors.black26,
                                      child: Text(
                                        '${idx + 1}',
                                        style: TextStyle(
                                          color: isCurrentReading ? Colors.white : Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      chap.title,
                                      style: TextStyle(
                                        fontWeight: isCurrentReading ? FontWeight.bold : FontWeight.w500,
                                        color: isCurrentReading ? Colors.deepPurpleAccent : Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Row(
                                      children: [
                                        const Icon(Icons.chat_bubble_outline, size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('$commentsCount bình luận', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        if (isCurrentReading) ...[
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.deepPurple,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('ĐANG ĐỌC', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReadingScreen(story: currentStory, initialChapterIndex: idx),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge({required IconData icon, required String label, required MaterialColor color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color.shade200),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color.shade100, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}