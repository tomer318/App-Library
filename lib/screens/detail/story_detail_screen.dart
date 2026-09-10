import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/auth_dialog.dart';
import '../reader/reading_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final state = globalAppState;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final isFav = state.isFavorite(story.id);
        final lastReadIndex = state.getLastReadChapterIndex(story.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(story.title),
            actions: [
              IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.redAccent : null),
                onPressed: () => _onFavoritePressed(context, state),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(story.coverUrl, width: 140, height: 200, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(story.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  '${story.averageRating.toStringAsFixed(1)} / 5.0 (${story.ratings.length} đánh giá)',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${state.t('author')}: ${story.author}'),
                            const SizedBox(height: 4),
                            Text('${state.t('genre')}: ${story.genre}'),
                            const SizedBox(height: 4),
                            Text('${state.t('chapters')}: ${story.chapters.length}'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                Chip(
                                  label: Text(story.type == 'comic' ? 'Manga' : 'Novel', style: const TextStyle(fontSize: 11)),
                                  visualDensity: VisualDensity.compact,
                                ),
                                Chip(
                                  label: Text(
                                    story.language == 'en' ? '🇬🇧 English' : '🇻🇳 Tiếng Việt',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Giới Thiệu Nội Dung', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(story.description, style: const TextStyle(fontSize: 15, height: 1.5)),
                  const Divider(height: 40),
                  const Text('Danh Sách Chương', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...List.generate(story.chapters.length, (idx) {
                    final chap = story.chapters[idx];
                    final isCurrentReading = lastReadIndex == idx;
                    final commentsCount = state.getCommentsForChapter(story.id, idx).length;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCurrentReading ? Colors.deepPurple : null,
                          foregroundColor: isCurrentReading ? Colors.white : null,
                          child: Text('${idx + 1}'),
                        ),
                        title: Text(chap.title, style: TextStyle(fontWeight: isCurrentReading ? FontWeight.bold : FontWeight.normal)),
                        subtitle: Text('$commentsCount bình luận', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ReadingScreen(story: story, initialChapterIndex: idx)),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRatingDialog(BuildContext context, Story story) {
    int selected = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Đánh giá truyện'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final star = index + 1;
              return IconButton(
                icon: Icon(star <= selected ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                onPressed: () => setModalState(() => selected = star),
              );
            }),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () {
                globalAppState.rateStory(story.id, selected);
                Navigator.pop(ctx);
              },
              child: const Text('Gửi Đánh Giá'),
            ),
          ],
        ),
      ),
    );
  }
}