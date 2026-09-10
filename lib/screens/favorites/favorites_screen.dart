import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../detail/story_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = globalAppState;
    final favoriteStories = state.stories.where((s) => state.favoriteStoryIds.contains(s.id)).toList();

    if (favoriteStories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border, size: 70, color: Colors.grey),
            const SizedBox(height: 16),
            Text(state.t('empty_favorites'), style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favoriteStories.length,
          itemBuilder: (context, index) {
            final story = favoriteStories[index];
            final lastReadIndex = state.readingHistory[story.id];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(story.coverUrl, width: 45, height: 60, fit: BoxFit.cover),
                ),
                title: Text(story.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  lastReadIndex != null
                      ? 'Đang đọc: ${story.chapters[lastReadIndex].title}'
                      : '${story.author} • ${story.genre}',
                  style: TextStyle(color: lastReadIndex != null ? Colors.deepPurpleAccent : null),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => state.toggleFavorite(story.id),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StoryDetailScreen(story: story)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}