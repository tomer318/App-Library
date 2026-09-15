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

  // 5. CẬP NHẬT CHƯƠNG TRÊN SUPABASE
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

      await client.from('stories').update({
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', storyId);
    } catch (e) {
      debugPrint('Lỗi updateChapter trên Supabase: $e');
    }
  }

  // 6. XÓA CHƯƠNG TRÊN SUPABASE VÀ DỌN DẸP STORAGE NẾU LÀ COMIC
  static Future<void> deleteChapter({
    required String storyId,
    required int chapterIndex,
    String storyTitle = '',
    String chapterTitle = '',
    bool isComic = false,
  }) async {
    try {
      // 1. Dọn dẹp folder ảnh của chương trên bucket comic_pages nếu là truyện tranh
      if (isComic && storyTitle.isNotEmpty && chapterTitle.isNotEmpty) {
        final storyFolder = '${slugify(storyTitle)}_$storyId';
        final chapFolder = 'chap_${chapterIndex + 1}_${slugify(chapterTitle)}';
        final targetPath = '$storyFolder/$chapFolder';
        await deleteStorageFolder('comic_pages', targetPath);
      }

      // 2. Xóa bản ghi chương trong database
      await client
          .from('chapters')
          .delete()
          .eq('story_id', storyId)
          .eq('chapter_order', chapterIndex);

      // 3. Cập nhật thời gian sửa đổi của truyện
      await client.from('stories').update({
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', storyId);
    } catch (e) {
      debugPrint('Lỗi deleteChapter trên Supabase: $e');
    }
  }

  // 7. XÓA TOÀN BỘ FILE TRONG THƯ MỤC STORAGE (ĐỆ QUY)
  static Future<void> deleteStorageFolder(String bucketName, String folderPath) async {
    try {
      final List<FileObject> objects = await client.storage.from(bucketName).list(path: folderPath);
      for (final item in objects) {
        final fullPath = '$folderPath/${item.name}';
        // Nếu là thư mục con (ví dụ folder chap bên trong comic_pages)
        if (item.id == null) {
          await deleteStorageFolder(bucketName, fullPath);
        } else {
          await client.storage.from(bucketName).remove([fullPath]);
        }
      }
      // Xóa các file ở cấp hiện tại
      final filePaths = objects.where((e) => e.id != null).map((e) => '$folderPath/${e.name}').toList();
      if (filePaths.isNotEmpty) {
        await client.storage.from(bucketName).remove(filePaths);
      }
    } catch (e) {
      debugPrint('Lỗi dọn dẹp folder $folderPath trên bucket $bucketName: $e');
    }
  }

  // XÓA TRUYỆN TRÊN DATABASE KÈM DỌN DẸP SẠCH TOÀN BỘ STORAGE
  static Future<void> deleteStory(String storyId, {String storyTitle = ''}) async {
    try {
      // 1. Dọn dẹp thư mục trên Storage nếu có tên truyện
      if (storyTitle.isNotEmpty) {
        final folderName = '${slugify(storyTitle)}_$storyId';
        // Dọn dẹp trên bucket covers
        await deleteStorageFolder('covers', folderName);
        // Dọn dẹp trên bucket comic_pages
        await deleteStorageFolder('comic_pages', folderName);
      }

      // 2. Xóa bình luận liên quan đến truyện
      await client.from('comments').delete().eq('story_id', storyId);

      // 3. Xóa các chương trong bảng chapters
      await client.from('chapters').delete().eq('story_id', storyId);

      // 4. Xóa truyện trong bảng stories
      await client.from('stories').delete().eq('id', storyId);
    } catch (e) {
      debugPrint('Lỗi khi xóa truyện $storyId: $e');
    }
  }

  // 8. ĐĂNG KÝ TÀI KHOẢN MỚI
  static Future<void> registerUser(AppUser user) async {
    await client.from('profiles').insert({
      'id': user.id,
      'username': user.username,
      'password': user.password,
      'role': user.role,
      'bio': user.bio,
    });
  }

  // 9. LƯU TIẾN ĐỘ ĐỌC (UPSERT)
  static Future<void> saveHistory(String userId, String storyId, int chapterIndex) async {
    try {
      await client.from('reading_history').upsert({
        'user_id': userId,
        'story_id': storyId,
        'chapter_index': chapterIndex,
        'last_read_at': DateTime.now().toIso8601String(),
      });

      final s = await client.from('stories').select('view_count').eq('id', storyId).single();
      final currentViews = (s['view_count'] as int? ?? 0) + 1;
      await client.from('stories').update({'view_count': currentViews}).eq('id', storyId);
    } catch (e) {
      debugPrint('Lỗi saveHistory: $e');
    }
  }

  // 10. BẬT/TẮT YÊU THÍCH (BOOKMARK)
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

  // 11. HÀM TẠO SLUG CHUẨN: BỎ DẤU TIẾNG VIỆT VÀ KÝ TỰ ĐẶC BIỆT
  static String slugify(String text) {
    var str = text.toLowerCase().trim();
    const vietnamese = [
      'a', 'á', 'à', 'ả', 'ã', 'ạ', 'ă', 'ắ', 'ằ', 'ẳ', 'ẵ', 'ặ', 'â', 'ấ', 'ầ', 'ẩ', 'ẫ', 'ậ',
      'd', 'đ',
      'e', 'é', 'è', 'ẻ', 'ẽ', 'ẹ', 'ê', 'ế', 'ề', 'ể', 'ễ', 'ệ',
      'i', 'í', 'ì', 'ỉ', 'ĩ', 'ị',
      'o', 'ó', 'ò', 'ỏ', 'õ', 'ọ', 'ô', 'ố', 'ồ', 'ổ', 'ỗ', 'ộ', 'ơ', 'ớ', 'ờ', 'ở', 'ỡ', 'ợ',
      'u', 'ú', 'ù', 'ủ', 'ũ', 'ụ', 'ư', 'ứ', 'ừ', 'ử', 'ữ', 'ự',
      'y', 'ý', 'ỳ', 'ỷ', 'ỹ', 'ỵ'
    ];
    const english = [
      'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a',
      'd', 'd',
      'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e',
      'i', 'i', 'i', 'i', 'i', 'i',
      'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o', 'o',
      'u', 'u', 'u', 'u', 'u', 'u', 'u', 'u', 'u', 'u', 'u', 'u',
      'y', 'y', 'y', 'y', 'y', 'y'
    ];

    for (int i = 0; i < vietnamese.length; i++) {
      str = str.replaceAll(vietnamese[i], english[i]);
    }
    str = str.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_');
    if (str.startsWith('_')) str = str.substring(1);
    if (str.endsWith('_')) str = str.substring(0, str.length - 1);
    return str.isEmpty ? 'story' : str;
  }

  // 12. TẢI ẢNH BÌA LÊN SUPABASE STORAGE
  static Future<String?> uploadCoverImage(Uint8List bytes, String fileExtension, {String storyTitle = '', String storyId = ''}) async {
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

      final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.$cleanExt';
      final path = (storyTitle.isNotEmpty && storyId.isNotEmpty)
          ? '${slugify(storyTitle)}_$storyId/$fileName'
          : fileName;

      await client.storage.from('covers').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: mimeType,
        ),
      );

      return client.storage.from('covers').getPublicUrl(path);
    } catch (e, stack) {
      debugPrint('LỖI CHI TIẾT UPLOAD BÌA: $e');
      debugPrint('STACK TRACE: $stack');
      return null;
    }
  }

  // 13. TẢI ẢNH TRANG TRUYỆN (COMIC PAGES) VỚI FOLDER PHÂN CẤP
  static Future<String?> uploadChapterImage({
    required String storyId,
    required String storyTitle,
    required int chapterOrder,
    required String chapterTitle,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final ext = fileName.split('.').last.toLowerCase();
      final safeFileName = '${DateTime.now().microsecondsSinceEpoch}_${bytes.length}.$ext';
      
      final storyFolder = '${slugify(storyTitle)}_$storyId';
      final chapFolder = 'chap_${chapterOrder + 1}_${slugify(chapterTitle)}';
      final path = '$storyFolder/$chapFolder/$safeFileName';

      await client.storage.from('comic_pages').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: ext == 'png' ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg'),
          upsert: true,
        ),
      );

      return client.storage.from('comic_pages').getPublicUrl(path);
    } catch (e) {
      debugPrint('Lỗi uploadChapterImage: $e');
      return null;
    }
  }

  // --- SUPABASE AUTHENTICATION ---

  // 14. ĐĂNG KÝ TÀI KHOẢN QUA SUPABASE AUTH
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

  // 15. ĐĂNG NHẬP BẰNG SUPABASE AUTH
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // 16. ĐĂNG XUẤT KHỎI SUPABASE AUTH
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // 17. LẤY THÔNG TIN USER HIỆN TẠI TỪ SESSION VÀ BẢNG PROFILES
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
          password: '',
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

  static Future<void> deleteComment(String commentId) async {
    try {
      await client.from('comments').delete().eq('id', commentId);
    } catch (e) {
      debugPrint('Lỗi deleteComment: $e');
    }
  }

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
}