import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/auth_dialog.dart';
import '../detail/story_detail_screen.dart';
import '../reader/reading_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = globalAppState;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        // NẾU CHƯA ĐĂNG NHẬP: KHÓA TỦ SÁCH
        if (state.currentUser == null) {
          return Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bookmark_remove_outlined, size: 70, color: Colors.deepPurpleAccent),
                    const SizedBox(height: 16),
                    Text(state.t('locked_library_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      state.t('locked_library_desc'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => showDialog(context: context, builder: (_) => const AuthDialog()),
                      icon: const Icon(Icons.login),
                      label: Text(state.t('login_now')),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // KHI ĐÃ ĐĂNG NHẬP: HIỆN 2 TAB (YÊU THÍCH & LỊCH SỬ ĐỌC)
        final favStories = state.stories.where((s) => state.currentFavorites.contains(s.id)).toList();
        final historyItems = state.currentHistory;

        return DefaultTabController(
          length: 2,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TabBar(
                      tabs: [
                        Tab(icon: const Icon(Icons.favorite), text: state.t('tab_favorites')),
                        Tab(icon: const Icon(Icons.history), text: state.t('tab_history')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // TAB 1: DANH SÁCH YÊU THÍCH
                          favStories.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.bookmark_border, size: 60, color: Colors.grey),
                                      const SizedBox(height: 12),
                                      Text(state.t('empty_favorites'), style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: favStories.length,
                                  itemBuilder: (context, index) {
                                    final story = favStories[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      child: ListTile(
                                        leading: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.network(story.coverUrl, width: 45, height: 60, fit: BoxFit.cover),
                                        ),
                                        title: Text(story.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text('${story.author} • ${story.genre} • ${story.status}'),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          tooltip: 'Xóa khỏi tủ sách',
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

                          // TAB 2: LỊCH SỬ ĐỌC GẦN ĐÂY
                          historyItems.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.history_toggle_off, size: 60, color: Colors.grey),
                                      const SizedBox(height: 12),
                                      Text(state.t('empty_history'), style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: state.clearHistory,
                                        icon: const Icon(Icons.delete_sweep, size: 18),
                                        label: Text(state.language == 'en' ? 'Clear all history' : 'Xóa toàn bộ lịch sử'),
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: historyItems.length,
                                        itemBuilder: (context, index) {
                                          final item = historyItems[index];
                                          final story = state.stories.firstWhere((s) => s.id == item.storyId, orElse: () => state.stories.first);
                                          final chapter = (item.chapterIndex < story.chapters.length)
                                              ? story.chapters[item.chapterIndex]
                                              : story.chapters.first;

                                          return Card(
                                            margin: const EdgeInsets.symmetric(vertical: 6),
                                            child: ListTile(
                                              leading: ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: Image.network(story.coverUrl, width: 45, height: 60, fit: BoxFit.cover),
                                              ),
                                              title: Text(story.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              subtitle: Text('Đang đọc: ${chapter.title}\nLúc: ${_formatDate(item.lastReadAt)}'),
                                              trailing: FilledButton.tonal(
                                                onPressed: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => ReadingScreen(story: story, initialChapterIndex: item.chapterIndex),
                                                  ),
                                                ),
                                                child: Text(state.t('continue_reading')),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day}/${dt.month}/${dt.year}';
  }
}