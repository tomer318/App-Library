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
          title: Text(state.t('login_require_title')),
          content: Text(state.t('bookmark_require_login')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(state.t('cancel'))),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                showDialog(context: context, builder: (_) => const AuthDialog());
              },
              child: Text(state.t('login')),
            ),
          ],
        ),
      );
    } else {
      state.toggleFavorite(story.id);
    }
  }

  void _showRatingDialog(BuildContext context, Story currentStory) {
    final state = globalAppState;
    if (state.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.t('rating_require_login')),
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
            title: Text(state.t('rating_dialog_title'), textAlign: TextAlign.center),
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
                  '$selectedStars / 5 ${state.t('rating_stars_suffix')}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(state.t('cancel')),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
                onPressed: () async {
                  await state.rateStory(currentStory.id, selectedStars);
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${state.t('rating_success')} $selectedStars ${state.t('rating_stars_suffix')}!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: Text(state.t('send_rating')),
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
                decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
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
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 380,
                      width: double.infinity,
                      decoration: const BoxDecoration(color: Colors.black),
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
                                          '${state.t('author')}: ${currentStory.author}',
                                          style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
                                        ),
                                        const SizedBox(height: 10),

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
                                                  '(${currentStory.ratings.length} ${state.t('votes_suffix')})',
                                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                                ),
                                                const Icon(Icons.edit_note, size: 15, color: Colors.amber),
                                              ],
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 14),

                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            _buildBadge(
                                              icon: Icons.calendar_today,
                                              label: '${state.t('release_year')}: ${currentStory.releaseYear}',
                                              color: Colors.blueGrey,
                                            ),
                                            _buildBadge(
                                              icon: Icons.library_books,
                                              label: '${currentStory.chapters.length} ${state.t('chapters')}',
                                              color: Colors.teal,
                                            ),
                                            _buildBadge(
                                              icon: currentStory.type == 'comic' ? Icons.photo_library : Icons.menu_book,
                                              label: currentStory.type == 'comic' ? state.t('manga') : state.t('novel'),
                                              color: Colors.purple,
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 10),

                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: currentStory.tags.map((tag) {
                                            return ActionChip(
                                              visualDensity: VisualDensity.compact,
                                              avatar: const Icon(Icons.tag, size: 13, color: Colors.deepPurpleAccent),
                                              label: Text(state.tGenre(tag), style: const TextStyle(fontSize: 11)),
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
                                      label: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          lastReadIndex != null
                                              ? '${state.t('read_continue_prefix')} ${lastReadIndex + 1})'
                                              : state.t('read_now'),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
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
                                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        side: BorderSide(
                                          color: isFav ? Colors.redAccent : Colors.grey.shade600,
                                        ),
                                      ),
                                      icon: Icon(
                                        isFav ? Icons.favorite : Icons.favorite_border,
                                        color: isFav ? Colors.redAccent : Colors.white,
                                        size: 18,
                                      ),
                                      label: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          isFav ? state.t('saved') : state.t('save_story'),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isFav ? Colors.redAccent : Colors.white,
                                            fontSize: 13,
                                          ),
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

                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                Row(
                                  children: [
                                    const Icon(Icons.auto_stories, size: 18, color: Colors.deepPurpleAccent),
                                    const SizedBox(width: 8),
                                    Text(state.t('synopsis'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  currentStory.description.trim().isEmpty
                                      ? state.t('no_description')
                                      : currentStory.description,
                                  style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey.shade300),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.format_list_bulleted, size: 20, color: Colors.deepPurpleAccent),
                                  const SizedBox(width: 8),
                                  Text(state.t('chapter_list'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

                          if (!hasChapters)
                            Container(
                              padding: const EdgeInsets.all(32),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(state.t('no_chapters_update'), style: const TextStyle(color: Colors.grey)),
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
                                        Text('$commentsCount ${state.t('comments_suffix')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        if (isCurrentReading) ...[
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.deepPurple,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(state.t('reading_badge'), style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
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

                          const SizedBox(height: 32),

                          // KHU VỰC BÌNH LUẬN NỔI BẬT CỦA BỘ TRUYỆN
                          Row(
                            children: [
                              const Icon(Icons.forum_outlined, size: 20, color: Colors.deepPurpleAccent),
                              const SizedBox(width: 8),
                              Text(
                                state.t('all_story_comments'),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Builder(
                                builder: (_) {
                                  final totalComments = state.getTopCommentsForStory(currentStory.id).length;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$totalComments',
                                      style: const TextStyle(
                                        color: Colors.deepPurpleAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Builder(
                            builder: (context) {
                              final topComments = state.getTopCommentsForStory(currentStory.id);
                              final currentUsername = state.currentUser?.username ?? (state.language == 'en' ? 'Guest' : 'Khách');

                              if (topComments.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(24),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E26),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      state.t('no_comments_in_story'),
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: topComments.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (ctx, idx) {
                                  final comment = topComments[idx];
                                  final isLiked = comment.likedUsernames.contains(currentUsername);

                                  final chapTitle = (comment.chapterIndex >= 0 && comment.chapterIndex < currentStory.chapters.length)
                                      ? currentStory.chapters[comment.chapterIndex].title
                                      : 'Chap ${comment.chapterIndex + 1}';

                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E26),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundColor: Colors.deepPurple,
                                              child: Text(
                                                comment.username.isNotEmpty ? comment.username[0].toUpperCase() : '?',
                                                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Wrap(
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                spacing: 8,
                                                runSpacing: 4,
                                                children: [
                                                  Text(
                                                    comment.username,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                  InkWell(
                                                    borderRadius: BorderRadius.circular(4),
                                                    onTap: () => Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => ReadingScreen(
                                                          story: currentStory,
                                                          initialChapterIndex: comment.chapterIndex,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.deepPurpleAccent.withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.4)),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(Icons.menu_book, size: 11, color: Colors.deepPurpleAccent),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            chapTitle,
                                                            style: const TextStyle(
                                                              fontSize: 11,
                                                              color: Colors.deepPurpleAccent,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTap: () => state.toggleLikeComment(comment.id),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                                                      size: 16,
                                                      color: isLiked ? Colors.blueAccent : Colors.grey,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${comment.likedUsernames.length}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: isLiked ? Colors.blueAccent : Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 36.0),
                                          child: Text(
                                            comment.content,
                                            style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey.shade300),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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