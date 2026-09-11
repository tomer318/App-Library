import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'dart:typed_data';

class SupabaseService {
  static final client = Supabase.instance.client;

  // 1. TẢI DANH SÁCH TRUYỆN VÀ CÁC CHƯƠNG TỪ SUPABASE
  static Future<List<Story>> fetchStories() async {
    try {
      final response = await client
          .from('stories')
          .select('*, chapters(*)')
          .order('updated_at', ascending: false);

      final List dataList = response as List;
      return dataList.map((data) {
        final chaptersData = (data['chapters'] as List? ?? [])
          ..sort((a, b) => (a['chapter_order'] as int).compareTo(b['chapter_order'] as int));

        final chapters = chaptersData.map((c) => Chapter(
          title: c['title'] ?? '',
          content: c['content'] ?? '',
          imageUrls: List<String>.from(c['image_urls'] ?? []),
        )).toList();

        return Story(
          id: data['id'],
          title: data['title'] ?? '',
          author: data['author'] ?? '',
          tags: List<String>.from(data['tags'] ?? []),
          releaseYear: data['release_year'] ?? 2024,
          status: data['status'] ?? 'Đang tiến hành',
          type: data['type'] ?? 'novel',
          language: data['language'] ?? 'vi',
          creatorId: data['creator_id'] ?? '',
          coverUrl: data['cover_url'] ?? '',
          description: data['description'] ?? '',
          viewCount: data['view_count'] ?? 0,
          ratings: List<int>.from(data['ratings'] ?? []),
          chapters: chapters,
          updatedAt: DateTime.tryParse(data['updated_at'] ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Lỗi fetchStories từ Supabase: $e');
      return [];
    }
  }

  // 2. TẢI DANH SÁCH USER
  static Future<List<AppUser>> fetchUsers() async {
    try {
      final res = await client.from('profiles').select();
      return (res as List).map((u) => AppUser(
        id: u['id'],
        username: u['username'] ?? '',
        password: u['password'] ?? '123',
        role: u['role'] ?? 'reader',
        bio: u['bio'] ?? '',
      )).toList();
    } catch (e) {
      debugPrint('Lỗi fetchUsers: $e');
      return [];
    }
  }

  // 3. THÊM HOẶC CẬP NHẬT TRUYỆN LÊN CLOUD
  static Future<void> saveStory(Story story, {bool isNew = true}) async {
    final payload = {
      'id': story.id,
      'title': story.title,
      'author': story.author,
      'tags': story.tags,
      'release_year': story.releaseYear,
      'status': story.status,
      'type': story.type,
      'language': story.language,
      'creator_id': story.creatorId,
      'cover_url': story.coverUrl,
      'description': story.description,
      'view_count': story.viewCount,
      'ratings': story.ratings,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (isNew) {
      await client.from('stories').insert(payload);
      for (int i = 0; i < story.chapters.length; i++) {
        final c = story.chapters[i];
        await client.from('chapters').insert({
          'story_id': story.id,
          'chapter_order': i,
          'title': c.title,
          'content': c.content,
          'image_urls': c.imageUrls,
        });
      }
    } else {
      await client.from('stories').update(payload).eq('id', story.id);
    }
  }

  // 4. THÊM CHƯƠNG MỚI
  static Future<void> addChapter(String storyId, int order, String title, {String content = '', List<String>? imageUrls}) async {
    await client.from('chapters').insert({
      'story_id': storyId,
      'chapter_order': order,
      'title': title,
      'content': content,
      'image_urls': imageUrls ?? [],
    });

    await client.from('stories').update({
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', storyId);
  }

  // 5. XÓA TRUYỆN
  static Future<void> deleteStory(String storyId) async {
    await client.from('stories').delete().eq('id', storyId);
  }

  // 6. ĐĂNG KÝ TÀI KHOẢN MỚI
  static Future<void> registerUser(AppUser user) async {
    await client.from('profiles').insert({
      'id': user.id,
      'username': user.username,
      'password': user.password,
      'role': user.role,
      'bio': user.bio,
    });
  }

  // 7. LƯU TIẾN ĐỘ ĐỌC (UPSERT)
  static Future<void> saveHistory(String userId, String storyId, int chapterIndex) async {
    try {
      await client.from('reading_history').upsert({
        'user_id': userId,
        'story_id': storyId,
        'chapter_index': chapterIndex,
        'last_read_at': DateTime.now().toIso8601String(),
      });

      // Tăng lượt xem (Cần tạo RPC `increment_view_count` trong SQL sau nếu muốn tối ưu, 
      // tạm thời bỏ qua hoặc dùng hàm update trực tiếp như dưới đây)
      final s = await client.from('stories').select('view_count').eq('id', storyId).single();
      final currentViews = (s['view_count'] as int? ?? 0) + 1;
      await client.from('stories').update({'view_count': currentViews}).eq('id', storyId);
    } catch (e) {
      debugPrint('Lỗi saveHistory: $e');
    }
  }

  // 8. BẬT/TẮT YÊU THÍCH (BOOKMARK)
  static Future<void> toggleFavorite(String userId, String storyId, bool isFavorite) async {
    try {
      if (isFavorite) {
        await client.from('favorites').delete().match({'user_id': userId, 'story_id': storyId});
      } else {
        await client.from('favorites').insert({'user_id': userId, 'story_id': storyId});
      }
    } catch (e) {
      debugPrint('Lỗi toggleFavorite: $e');
    }
  }

  // 9. TẢI ẢNH BÌA LÊN SUPABASE STORAGE
  static Future<String?> uploadCoverImage(Uint8List bytes, String fileExtension) async {
    try {
      final cleanExt = fileExtension.replaceAll('.', '').toLowerCase();
      // Xác định chính xác MIME type
      String mimeType = 'image/jpeg';
      if (cleanExt == 'png') {
        mimeType = 'image/png';
      } else if (cleanExt == 'webp') {
        mimeType = 'image/webp';
      } else if (cleanExt == 'gif') {
        mimeType = 'image/gif';
      }

      final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.$cleanExt';
      final path = 'public/$fileName';

      await client.storage.from('covers').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: mimeType,
        ),
      );

      final publicUrl = client.storage.from('covers').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Lỗi uploadCoverImage: $e');
      return null;
    }
  }
}