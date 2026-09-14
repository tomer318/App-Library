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
      String mimeType = 'image/jpeg';
      if (cleanExt == 'png') {
        mimeType = 'image/png';
      } else if (cleanExt == 'webp') {
        mimeType = 'image/webp';
      } else if (cleanExt == 'gif') {
        mimeType = 'image/gif';
      }

      // Đặt tên file trực tiếp ở root bucket, KHÔNG thêm tiền tố 'public/'
      final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.$cleanExt';

      await client.storage.from('covers').uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: mimeType,
        ),
      );

      // Lấy URL công khai chính xác
      final publicUrl = client.storage.from('covers').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Lỗi uploadCoverImage: $e');
      return null;
    }
  }

  // --- SUPABASE AUTHENTICATION ---

  // 10. ĐĂNG KÝ TÀI KHOẢN QUA SUPABASE AUTH
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    String role = 'reader',
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'role': role,
      },
    );
  }

  // 11. ĐĂNG NHẬP BẰNG SUPABASE AUTH
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // 12. ĐĂNG XUẤT KHỎI SUPABASE AUTH
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // 13. LẤY THÔNG TIN USER HIỆN TẠI TỪ SESSION VÀ BẢNG PROFILES
  static Future<AppUser?> getCurrentProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      final res = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (res != null) {
        return AppUser(
          id: res['id'],
          username: res['username'] ?? (user.email?.split('@').first ?? 'User'),
          password: '', // Không lưu mật khẩu thô ở Client
          role: res['role'] ?? 'reader',
          bio: res['bio'] ?? '',
        );
      }
    } catch (e) {
      debugPrint('Lỗi getCurrentProfile: $e');
    }
    return null;
  }

  // --- PROFILE & ROLE SYNC ---

  // Cập nhật thông tin Display Name & Bio lên bảng profiles
  static Future<void> updateProfile({
    required String userId,
    required String username,
    required String bio,
  }) async {
    try {
      await client.from('profiles').update({
        'username': username,
        'bio': bio,
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Lỗi updateProfile: $e');
    }
  }

  // Cập nhật vai trò (Role) lên bảng profiles
  static Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    try {
      await client.from('profiles').update({
        'role': role,
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Lỗi updateUserRole: $e');
    }
  }

  // --- COMMENTS SYNC ---

  // Tải danh sách tất cả bình luận từ Supabase Cloud
  static Future<List<Comment>> fetchComments() async {
    try {
      final res = await client
          .from('comments')
          .select()
          .order('created_at', ascending: false);

      return (res as List).map((row) {
        return Comment(
          id: row['id'],
          storyId: row['story_id'],
          chapterIndex: row['chapter_index'] ?? 0,
          username: row['username'] ?? 'Ẩn danh',
          content: row['content'] ?? '',
          createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
          likedUsernames: (row['liked_usernames'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          reportCount: row['report_count'] ?? 0,
        );
      }).toList();
    } catch (e) {
      debugPrint('Lỗi fetchComments: $e');
      return [];
    }
  }

  // Thêm bình luận mới lên Cloud
  static Future<void> insertComment(Comment comment, String? userId) async {
    try {
      await client.from('comments').insert({
        'id': comment.id,
        'story_id': comment.storyId,
        'chapter_index': comment.chapterIndex,
        'user_id': userId,
        'username': comment.username,
        'content': comment.content,
        'liked_usernames': comment.likedUsernames,
        'report_count': comment.reportCount,
        'created_at': comment.createdAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Lỗi insertComment: $e');
    }
  }

  // Cập nhật lượt thích và lượt báo cáo của bình luận
  static Future<void> updateCommentInteraction(String commentId, List<String> likedUsernames, int reportCount) async {
    try {
      await client.from('comments').update({
        'liked_usernames': likedUsernames,
        'report_count': reportCount,
      }).eq('id', commentId);
    } catch (e) {
      debugPrint('Lỗi updateCommentInteraction: $e');
    }
  }

  // Xóa bình luận
  static Future<void> deleteComment(String commentId) async {
    try {
      await client.from('comments').delete().eq('id', commentId);
    } catch (e) {
      debugPrint('Lỗi deleteComment: $e');
    }
  }

  // Lưu hoặc cập nhật đánh giá của user cho 1 truyện
  static Future<void> submitRating({
    required String storyId,
    required String userId,
    required int rating,
  }) async {
    try {
      await client.from('ratings').upsert(
        {
          'story_id': storyId,
          'user_id': userId,
          'rating': rating,
        },
        onConflict: 'story_id,user_id',
      );
    } catch (e) {
      debugPrint('Lỗi submitRating: $e');
    }
  }

  // Lấy tất cả rating của các truyện để tính điểm trung bình
  static Future<Map<String, List<int>>> fetchAllRatings() async {
    try {
      final res = await client.from('ratings').select('story_id, rating');
      final Map<String, List<int>> result = {};
      for (final row in res as List) {
        final sId = row['story_id'] as String;
        final r = row['rating'] as int;
        result.putIfAbsent(sId, () => []).add(r);
      }
      return result;
    } catch (e) {
      debugPrint('Lỗi fetchAllRatings: $e');
      return {};
    }
  }

  // Tải ảnh trang truyện lên Supabase Storage Bucket 'comic_pages'
  static Future<String?> uploadChapterImage({
    required String storyId,
    required Uint8List bytes,
    required String fileName,
    }) async {
    try {
      final ext = fileName.split('.').last.toLowerCase();
      // Dùng microseconds và độ dài bytes để tạo tên file ngẫu nhiên an toàn, không chứa ký tự đặc biệt
      final safeFileName = '${DateTime.now().microsecondsSinceEpoch}_${bytes.length}.$ext';
      final path = '$storyId/$safeFileName';

      // Upload file dạng binary bytes
      await client.storage.from('comic_pages').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: ext == 'png' ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg'),
          upsert: true,
        ),
      );

      // Lấy URL công khai của ảnh
      final publicUrl = client.storage.from('comic_pages').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Lỗi uploadChapterImage: $e');
      return null;
    }
  }

  // Cập nhật nội dung / danh sách ảnh của một chapter lên Supabase Database
  static Future<void> updateChapter({
    required String storyId,
    required int chapterIndex,
    required String title,
    String content = '',
    List<String>? imageUrls,
  }) async {
    try {
      await client
          .from('chapters')
          .update({
            'title': title,
            'content': content,
            'image_urls': imageUrls ?? [],
          })
          .eq('story_id', storyId)
          .eq('chapter_order', chapterIndex);
    } catch (e) {
      debugPrint('Lỗi updateChapter trên Supabase: $e');
    }
  }

  // Xóa chapter trên Supabase Database
  static Future<void> deleteChapter({
    required String storyId,
    required int chapterIndex,
  }) async {
    try {
      await client
          .from('chapters')
          .delete()
          .eq('story_id', storyId)
          .eq('chapter_order', chapterIndex);
    } catch (e) {
      debugPrint('Lỗi deleteChapter trên Supabase: $e');
    }
  }
}