import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../reader/reading_screen.dart';

class StoryDetailScreen extends StatelessWidget {
  final Story story;
  const StoryDetailScreen({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    final state = globalAppState;
    final isFav = state.favoriteStoryIds.contains(story.id);
    final lastReadIndex = state.readingHistory[story.id];

    return Scaffold(
      appBar: AppBar(
        title: Text(story.title),
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.redAccent : null),
            onPressed: () => state.toggleFavorite(story.id),
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
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: () {
                                if (story.chapters.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ReadingScreen(story: story, initialChapterIndex: 0)),
                                  );
                                }
                              },
                              icon: const Icon(Icons.menu_book),
                              label: Text(state.t('read_now')),
                            ),
                            if (lastReadIndex != null && lastReadIndex < story.chapters.length)
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ReadingScreen(story: story, initialChapterIndex: lastReadIndex)),
                                  );
                                },
                                icon: const Icon(Icons.play_arrow),
                                label: Text('${state.t('continue_reading')} (Chap ${lastReadIndex + 1})'),
                              ),
                            IconButton.outlined(
                              icon: const Icon(Icons.star_border),
                              tooltip: 'Đánh giá truyện này',
                              onPressed: () => _showRatingDialog(context, story),
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