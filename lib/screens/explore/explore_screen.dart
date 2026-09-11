import 'package:flutter/material.dart';
import '../../widgets/shimmer_loading.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../detail/story_detail_screen.dart';
import '../../widgets/advanced_search_dialog.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = globalAppState;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final stories = state.filteredStories;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. THANH TÌM KIẾM VÀ NÚT BẬT/TẮT BỘ LỌC
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: state.t('search_hint'),
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (val) => state.setSearchQuery(val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: Icon(state.isFilterBarVisible ? Icons.filter_alt : Icons.filter_alt_outlined),
                        tooltip: 'Ẩn/Hiện bộ lọc',
                        onPressed: state.toggleFilterBar,
                      ),
                      const SizedBox(width: 4),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.tune),
                        tooltip: 'Bộ lọc nâng cao',
                        onPressed: () => showDialog(
                          context: context,
                          barrierColor: Colors.black.withValues(alpha: 0.65),
                          builder: (_) => const AdvancedSearchDialog(),
                        ),
                      ),
                    ],
                  ),

                  // 2. KHỐI BỘ LỌC CÓ THỂ THU GỌN / MỞ RỘNG (COLLAPSIBLE)
                  if (state.isFilterBarVisible) ...[
                    const SizedBox(height: 8),
                    // Phân loại Novel / Manga
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        segments: [
                          ButtonSegment(
                            value: 'all',
                            label: Text(state.t('all'), maxLines: 1, style: const TextStyle(fontSize: 12)),
                            icon: const Icon(Icons.apps, size: 14),
                          ),
                          ButtonSegment(
                            value: 'novel',
                            label: Text(state.t('novel'), maxLines: 1, style: const TextStyle(fontSize: 12)),
                            icon: const Icon(Icons.menu_book, size: 14),
                          ),
                          ButtonSegment(
                            value: 'comic',
                            label: Text(state.t('manga'), maxLines: 1, style: const TextStyle(fontSize: 12)),
                            icon: const Icon(Icons.photo_library, size: 14),
                          ),
                        ],
                        selected: {state.selectedType},
                        onSelectionChanged: (val) => state.setSelectedType(val.first),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Lọc theo ngôn ngữ (Tất cả / Tiếng Việt / Tiếng Anh)
                    SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          FilterChip(
                            label: Text(state.t('filter_all_lang'), style: const TextStyle(fontSize: 11)),
                            selected: state.storyLanguageFilter == 'all',
                            onSelected: (_) => state.setStoryLanguageFilter('all'),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 6),
                          FilterChip(
                            avatar: const Text('🇻🇳', style: TextStyle(fontSize: 12)),
                            label: Text(state.t('filter_vi'), style: const TextStyle(fontSize: 11)),
                            selected: state.storyLanguageFilter == 'vi',
                            onSelected: (_) => state.setStoryLanguageFilter('vi'),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 6),
                          FilterChip(
                            avatar: const Text('🇬🇧', style: TextStyle(fontSize: 12)),
                            label: Text(state.t('filter_en'), style: const TextStyle(fontSize: 11)),
                            selected: state.storyLanguageFilter == 'en',
                            onSelected: (_) => state.setStoryLanguageFilter('en'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Thanh lọc đa Tag (Master Tags)
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ChoiceChip(
                            label: Text(state.t('all'), style: const TextStyle(fontSize: 12)),
                            selected: state.selectedTags.isEmpty,
                            onSelected: (_) => state.clearTagsFilter(),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 6),
                          ...state.masterTags.map((tag) {
                            final isSel = state.selectedTags.contains(tag);
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: FilterChip(
                                label: Text(state.tGenre(tag), style: const TextStyle(fontSize: 12)),
                                selected: isSel,
                                onSelected: (_) => state.toggleTagFilter(tag),
                                visualDensity: VisualDensity.compact,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // 3. DANH SÁCH THẺ TRUYỆN (GRIDVIEW RESPONSIVE)
                  Expanded(
                    child: stories.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off, size: 60, color: Colors.grey),
                                const SizedBox(height: 12),
                                const Text('Không tìm thấy truyện phù hợp.', style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: state.resetFilters,
                                  child: const Text('Đặt lại bộ lọc'),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 260,
                              childAspectRatio: 0.50,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: stories.length,
                            itemBuilder: (ctx, idx) {
                              final story = stories[idx];
                              final isFav = state.isFavorite(story.id);

                              return Card(
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => StoryDetailScreen(story: story)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            if (story.coverUrl.trim().isEmpty)
                                              Container(
                                                color: Colors.grey.shade900,
                                                child: const Icon(Icons.menu_book, size: 40, color: Colors.grey),
                                              )
                                            else
                                              Image.network(
                                                story.coverUrl,
                                                fit: BoxFit.cover,
                                                headers: const {'Accept': 'image/*'},
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return const ShimmerEffect(
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    borderRadius: 0,
                                                  );
                                                },
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  color: Colors.grey.shade900,
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        story.type == 'comic' ? Icons.photo_library : Icons.menu_book,
                                                        size: 40,
                                                        color: Colors.grey,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      const Text(
                                                        'Không tải được ảnh',
                                                        style: TextStyle(fontSize: 10, color: Colors.grey),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            // ĐIỂM ĐÁNH GIÁ & CỜ NGÔN NGỮ
                                            Positioned(
                                              top: 8,
                                              left: 8,
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withValues(alpha: 0.7),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.star, color: Colors.amber, size: 14),
                                                        const SizedBox(width: 2),
                                                        Text(
                                                          story.averageRating.toStringAsFixed(1),
                                                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withValues(alpha: 0.7),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      story.language == 'en' ? '🇬🇧 EN' : '🇻🇳 VI',
                                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // NÚT BOOKMARK TỦ SÁCH
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: IconButton(
                                                icon: Icon(
                                                  isFav ? Icons.favorite : Icons.favorite_border,
                                                  color: isFav ? Colors.redAccent : Colors.white,
                                                ),
                                                onPressed: () => state.toggleFavorite(story.id),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              story.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    story.author,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                  ),
                                                ),
                                                Text(
                                                  '${story.releaseYear}',
                                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            // HIỂN THỊ CÁC TAG - BẤM VÀO TAG ĐỂ LỌC
                                            Wrap(
                                              spacing: 4,
                                              runSpacing: 4,
                                              children: story.tags.take(3).map((tag) {
                                                return InkWell(
                                                  borderRadius: BorderRadius.circular(4),
                                                  onTap: () => state.setSingleTagFilter(tag),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.deepPurpleAccent.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      state.tGenre(tag),
                                                      style: const TextStyle(fontSize: 9, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w600),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                            const SizedBox(height: 4),
                                            Text('${story.chapters.length} chap', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}