import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppState extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark;
  String language = 'vi';
  AppUser? currentUser;

  // Cài đặt đọc truyện
  double defaultFontSize = 18.0;
  String fontFamily = 'Mặc định'; // 'Mặc định' hoặc 'Serif'

  // Tìm kiếm cơ bản & nâng cao
  String searchQuery = '';
  Set<String> selectedTags = {}; // LỌC NHIỀU TAG (AND)
  String filterStatus = 'Tất cả'; // 'Tất cả', 'Đang tiến hành', 'Đã hoàn thành'
  String filterAuthor = '';
  int? filterYear; // LỌC THEO NĂM
  String sortBy = 'Mới nhất'; // 'Mới nhất', 'Lượt xem', 'Điểm đánh giá'
  String selectedType = 'all'; // 'all', 'novel', 'comic'
  String storyLanguageFilter = 'all'; // 'all', 'vi', 'en'
  bool isFilterBarVisible = false; // ẨN / HIỆN THANH LỌC

  // Getter & Setter tương thích ngược cho selectedGenre
  String get selectedGenre => selectedTags.isEmpty ? 'Tất cả' : selectedTags.first;
  set selectedGenre(String g) {
    if (g == 'Tất cả') {
      selectedTags.clear();
    } else {
      selectedTags = {g};
    }
    notifyListeners();
  }

  // BỘ TAG HỆ THỐNG MẪU ĐỊNH SẴN
  final List<String> masterTags = [
    'Tâm linh',
    'Kiếm hiệp',
    'Viễn tưởng',
    'Hành động',
    'Manhwa',
    'Romance',
    'Comedy',
    'Sci-Fi',
    'Hệ thống',
    'Huyền huyễn',
    'Kinh dị',
  ];

  // Getter genres tương thích ngược
  List<String> get genres => ['Tất cả', ...masterTags];

  // Dữ liệu cá nhân theo từng User: Map<UserId, Set<StoryId>>
  Map<String, Set<String>> userFavorites = {};
  // Dữ liệu lịch sử đọc theo từng User: Map<UserId, Map<StoryId, ReadingItem>>
  Map<String, Map<String, ReadingItem>> userHistory = {};

  List<AppUser> registeredUsers = [];
  List<Comment> allComments = [];
  List<Story> stories = [];

  AppState() {
    _loadFromStorage();
  }

  // Lấy danh sách yêu thích của người dùng hiện tại
  Set<String> get currentFavorites {
    if (currentUser == null) return {};
    return userFavorites[currentUser!.id] ?? {};
  }

  // Lấy danh sách lịch sử đọc của người dùng hiện tại
  List<ReadingItem> get currentHistory {
    if (currentUser == null) return [];
    final items = userHistory[currentUser!.id]?.values.toList() ?? [];
    items.sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));
    return items;
  }

  // Danh sách tác phẩm do người dùng hiện tại tạo ra
  List<Story> get myCreatedStories {
    if (currentUser == null) return [];
    if (currentUser!.role == 'admin') return stories;
    return stories.where((s) => s.creatorId == currentUser!.id).toList();
  }

  // Lấy toàn bộ bình luận của một bộ truyện, sắp xếp theo số lượt like giảm dần
  List<Comment> getTopCommentsForStory(String storyId) {
    final list = allComments.where((c) => c.storyId == storyId).toList();
    list.sort((a, b) => b.likedUsernames.length.compareTo(a.likedUsernames.length));
    return list;
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Tải cài đặt giao diện cục bộ
    final savedTheme = prefs.getString('themeMode') ?? 'dark';
    themeMode = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;
    language = prefs.getString('language') ?? 'vi';
    defaultFontSize = prefs.getDouble('fontSize') ?? 18.0;
    fontFamily = prefs.getString('fontFamily') ?? 'Mặc định';

    // 2. Tải phiên đăng nhập: ưu tiên lấy từ Supabase Auth session
    try {
      final cloudProfile = await SupabaseService.getCurrentProfile();
      if (cloudProfile != null) {
        currentUser = cloudProfile;
      } else {
        final currentUserRaw = prefs.getString('currentUser');
        if (currentUserRaw != null) {
          currentUser = AppUser.fromJson(jsonDecode(currentUserRaw));
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải phiên đăng nhập Supabase Auth: $e');
    }

    // 3. TẢI DỮ LIỆU TỪ SUPABASE CLOUD
    try {
      // Tải danh sách User từ Supabase
      final cloudUsers = await SupabaseService.fetchUsers();
      if (cloudUsers.isNotEmpty) {
        registeredUsers = cloudUsers;
      } else {
        registeredUsers = [
          AppUser(id: 'u_admin', username: 'admin', password: '123', role: 'admin', bio: 'Quản trị viên tối cao'),
          AppUser(id: 'u_author', username: 'tacgia', password: '123', role: 'author', bio: 'Họa sĩ truyện tranh độc lập'),
          AppUser(id: 'u_1', username: 'docgia1', password: '123', role: 'reader', bio: 'Đam mê tu tiên & kiếm hiệp'),
        ];
      }

      // Tải danh sách Truyện thực tế từ Supabase (không tự nạp truyện mẫu)
      final cloudStories = await SupabaseService.fetchStories();
      stories = cloudStories;

      // NẠP RATINGS TỪ CLOUD (ĐẶT SAU KHI ĐÃ CÓ STORIES)
      try {
        final cloudRatings = await SupabaseService.fetchAllRatings();
        for (var s in stories) {
          if (cloudRatings.containsKey(s.id)) {
            s.ratings = List<int>.from(cloudRatings[s.id]!);
          }
        }
      } catch (e) {
        debugPrint('Lỗi nạp ratings: $e');
      }

    } catch (e) {
      debugPrint('Lỗi kết nối Supabase: $e');
    }

    // Tải bình luận từ Cloud
    final cloudComments = await SupabaseService.fetchComments();
    if (cloudComments.isNotEmpty) {
      allComments = cloudComments;
    }

    // 4. Tải danh sách yêu thích và lịch sử đọc
    final favRaw = prefs.getString('userFavorites');
    if (favRaw != null) {
      final Map<String, dynamic> decoded = jsonDecode(favRaw);
      userFavorites = decoded.map((k, v) => MapEntry(k, Set<String>.from(v)));
    }

    final hisRaw = prefs.getString('userHistory');
    if (hisRaw != null) {
      final Map<String, dynamic> decoded = jsonDecode(hisRaw);
      userHistory = decoded.map((k, v) {
        final Map<String, dynamic> innerMap = v;
        return MapEntry(
          k,
          innerMap.map((storyId, itemJson) => MapEntry(storyId, ReadingItem.fromJson(itemJson))),
        );
      });
    }

    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', themeMode == ThemeMode.light ? 'light' : 'dark');
    await prefs.setString('language', language);
    await prefs.setDouble('fontSize', defaultFontSize);
    await prefs.setString('fontFamily', fontFamily);
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('registeredUsers', jsonEncode(registeredUsers.map((u) => u.toJson()).toList()));
    if (currentUser != null) {
      await prefs.setString('currentUser', jsonEncode(currentUser!.toJson()));
    } else {
      await prefs.remove('currentUser');
    }
  }

  Future<void> _saveStories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stories', jsonEncode(stories.map((s) => s.toJson()).toList()));
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final serializable = userFavorites.map((k, v) => MapEntry(k, v.toList()));
    await prefs.setString('userFavorites', jsonEncode(serializable));
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final serializable = userHistory.map((k, v) {
      return MapEntry(k, v.map((sId, item) => MapEntry(sId, item.toJson())));
    });
    await prefs.setString('userHistory', jsonEncode(serializable));
  }

  Future<void> _saveComments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('allComments', jsonEncode(allComments.map((c) => c.toJson()).toList()));
  }

  // GETTER LỌC DANH SÁCH TRUYỆN HIỂN THỊ
  List<Story> get filteredStories {
    return stories.where((story) {
      // Ẩn truyện nếu trạng thái là Tạm ẩn/hidden (ngoại trừ khi admin hoặc tác giả đang xem)
      final isHidden = story.status == 'Tạm ẩn' || story.status == 'hidden';
      final canViewHidden = currentUser?.role == 'admin' || (currentUser != null && story.creatorId == currentUser?.id);
      if (isHidden && !canViewHidden) return false;

      // Tìm kiếm theo từ khóa
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchTitle = story.title.toLowerCase().contains(q);
        final matchAuthor = story.author.toLowerCase().contains(q);
        if (!matchTitle && !matchAuthor) return false;
      }

      // Lọc theo loại truyện (Novel / Comic)
      if (selectedType != 'all' && story.type != selectedType) return false;

      // Lọc theo ngôn ngữ
      if (storyLanguageFilter != 'all' && story.language != storyLanguageFilter) return false;

      // Lọc theo thể loại Tags
      if (selectedTags.isNotEmpty && !selectedTags.any((t) => story.tags.contains(t))) return false;

      return true;
    }).toList();
  }

  void toggleTagFilter(String tag) {
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }
    notifyListeners();
  }

  void setSingleTagFilter(String tag) {
    selectedTags = {tag};
    notifyListeners();
  }

  void clearTagsFilter() {
    selectedTags.clear();
    notifyListeners();
  }

  void toggleFilterBar() {
    isFilterBarVisible = !isFilterBarVisible;
    notifyListeners();
  }

  void setAdvancedFilter({
    required String author,
    String? genre,
    Set<String>? tags,
    required String status,
    required String sort,
    int? year,
  }) {
    filterAuthor = author;
    if (tags != null) {
      selectedTags = Set.from(tags);
    } else if (genre != null && genre != 'Tất cả') {
      selectedTags = {genre};
    } else {
      selectedTags.clear();
    }
    filterStatus = status;
    sortBy = sort;
    filterYear = year;
    notifyListeners();
  }

  void resetFilters() {
    searchQuery = '';
    selectedTags.clear();
    filterStatus = 'Tất cả';
    filterAuthor = '';
    filterYear = null;
    sortBy = 'Mới nhất';
    notifyListeners();
  }

  void setSearchQuery(String q) {
    searchQuery = q;
    notifyListeners();
  }

  void setSelectedGenre(String g) {
    if (g == 'Tất cả') {
      selectedTags.clear();
    } else {
      selectedTags = {g};
    }
    notifyListeners();
  }

  void setSelectedType(String type) {
    selectedType = type;
    notifyListeners();
  }

  void setStoryLanguageFilter(String lang) {
    storyLanguageFilter = lang;
    notifyListeners();
  }

  Future<void> saveReadingProgress(String storyId, int chapIndex) async {
    if (currentUser == null) return;
    final userId = currentUser!.id;
    if (!userHistory.containsKey(userId)) {
      userHistory[userId] = {};
    }
    userHistory[userId]![storyId] = ReadingItem(
      storyId: storyId,
      chapterIndex: chapIndex,
      lastReadAt: DateTime.now(),
    );

    final storyIndex = stories.indexWhere((s) => s.id == storyId);
    if (storyIndex != -1) {
      stories[storyIndex].viewCount++;
    }
    _saveHistory();
    notifyListeners();

    await SupabaseService.saveHistory(userId, storyId, chapIndex);
  }

  void clearHistory() {
    if (currentUser != null) {
      userHistory[currentUser!.id]?.clear();
      _saveHistory();
      notifyListeners();
    }
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveSettings();
    notifyListeners();
  }

  void toggleLanguage() {
    language = language == 'vi' ? 'en' : 'vi';
    _saveSettings();
    notifyListeners();
  }

  void updateReadingSettings({double? fontSize, String? font}) {
    if (fontSize != null) defaultFontSize = fontSize;
    if (font != null) fontFamily = font;
    _saveSettings();
    notifyListeners();
  }

  Future<String?> login(String emailOrUsername, String password) async {
    try {
      String email = emailOrUsername.trim();
      if (!email.contains('@')) {
        email = '${email.toLowerCase()}@gmail.com';
      }

      final res = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      if (res.user != null) {
        final profile = await SupabaseService.getCurrentProfile();
        currentUser = profile ?? AppUser(
          id: res.user!.id,
          username: res.user!.userMetadata?['username'] ?? emailOrUsername.trim(),
          password: '',
          role: res.user!.userMetadata?['role'] ?? 'reader',
        );

        await _saveUsers();
        notifyListeners();
        return null;
      }
      return 'Đăng nhập không thành công!';
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        return 'Tài khoản hoặc mật khẩu không chính xác!';
      }
      return e.message;
    } catch (e) {
      return 'Lỗi kết nối: $e';
    }
  }

  Future<String?> register({
    required String email,
    required String username,
    required String password,
    bool makeAdmin = false,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanUsername = username.trim();

    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      return 'Định dạng Email không hợp lệ!';
    }
    if (cleanUsername.length < 3) {
      return 'Tên hiển thị phải từ 3 ký tự trở lên!';
    }
    if (password.length < 6) {
      return 'Mật khẩu Supabase Auth yêu cầu tối thiểu 6 ký tự!';
    }

    try {
      final role = makeAdmin ? 'admin' : 'reader';

      final res = await SupabaseService.signUp(
        email: cleanEmail,
        password: password,
        username: cleanUsername,
        role: role,
      );

      if (res.user != null) {
        await Future.delayed(const Duration(milliseconds: 300));

        final profile = await SupabaseService.getCurrentProfile();
        currentUser = profile ?? AppUser(
          id: res.user!.id,
          username: cleanUsername,
          password: '',
          role: role,
        );

        await _saveUsers();
        notifyListeners();
        return null;
      }
      return 'Đăng ký không thành công!';
    } on AuthException catch (e) {
      if (e.message.contains('already registered') || e.message.contains('User already registered')) {
        return 'Email này đã được đăng ký tài khoản!';
      }
      return e.message;
    } catch (e) {
      return 'Lỗi đăng ký: $e';
    }
  }

  Future<void> logout() async {
    currentUser = null;
    await SupabaseService.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser');
    notifyListeners();
  }

  Future<void> becomeAuthor() async {
    if (currentUser != null && currentUser!.role == 'reader') {
      currentUser!.role = 'author';
      final idx = registeredUsers.indexWhere((u) => u.id == currentUser!.id);
      if (idx != -1) registeredUsers[idx] = currentUser!;
      _saveUsers();
      notifyListeners();

      await SupabaseService.updateUserRole(userId: currentUser!.id, role: 'author');
    }
  }

  Future<void> updateProfile(String newName, String newBio) async {
    if (currentUser != null) {
      currentUser!.username = newName;
      currentUser!.bio = newBio;
      final idx = registeredUsers.indexWhere((u) => u.id == currentUser!.id);
      if (idx != -1) registeredUsers[idx] = currentUser!;
      _saveUsers();
      notifyListeners();

      await SupabaseService.updateProfile(
        userId: currentUser!.id,
        username: newName,
        bio: newBio,
      );
    }
  }

  bool isFavorite(String storyId) {
    if (currentUser == null) return false;
    return currentFavorites.contains(storyId);
  }

  int? getLastReadChapterIndex(String storyId) {
    if (currentUser == null) return null;
    return userHistory[currentUser!.id]?[storyId]?.chapterIndex;
  }

  Future<void> toggleFavorite(String storyId) async {
    if (currentUser == null) return;
    final userId = currentUser!.id;
    if (!userFavorites.containsKey(userId)) {
      userFavorites[userId] = {};
    }

    final isFav = userFavorites[userId]!.contains(storyId);
    if (isFav) {
      userFavorites[userId]!.remove(storyId);
    } else {
      userFavorites[userId]!.add(storyId);
    }
    _saveFavorites();
    notifyListeners();

    await SupabaseService.toggleFavorite(userId, storyId, isFav);
  }

  Future<void> rateStory(String storyId, int rating) async {
    final storyIndex = stories.indexWhere((s) => s.id == storyId);
    if (storyIndex != -1) {
      stories[storyIndex].ratings.add(rating);
      _saveStories();
      notifyListeners();

      if (currentUser != null) {
        await SupabaseService.submitRating(
          storyId: storyId,
          userId: currentUser!.id,
          rating: rating,
        );
      }
    }
  }

  List<Comment> getCommentsForChapter(String storyId, int chapIndex) {
    return allComments.where((c) => c.storyId == storyId && c.chapterIndex == chapIndex).toList();
  }

  Future<void> addComment(String storyId, int chapIndex, String content) async {
    final username = currentUser?.username ?? 'Khách';
    final comment = Comment(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      storyId: storyId,
      chapterIndex: chapIndex,
      username: username,
      content: content,
      createdAt: DateTime.now(),
    );
    allComments.insert(0, comment);
    _saveComments();
    notifyListeners();

    await SupabaseService.insertComment(comment, currentUser?.id);
  }

  Future<void> deleteComment(String commentId) async {
    allComments.removeWhere((c) => c.id == commentId);
    _saveComments();
    notifyListeners();

    await SupabaseService.deleteComment(commentId);
  }

  Future<void> toggleLikeComment(String commentId) async {
    final username = currentUser?.username ?? 'Khách';
    final idx = allComments.indexWhere((c) => c.id == commentId);
    if (idx != -1) {
      final comment = allComments[idx];
      if (comment.likedUsernames.contains(username)) {
        comment.likedUsernames.remove(username);
      } else {
        comment.likedUsernames.add(username);
      }
      _saveComments();
      notifyListeners();

      await SupabaseService.updateCommentInteraction(comment.id, comment.likedUsernames, comment.reportCount);
    }
  }

  Future<void> reportComment(String commentId) async {
    final idx = allComments.indexWhere((c) => c.id == commentId);
    if (idx != -1) {
      allComments[idx].reportCount++;
      _saveComments();
      notifyListeners();

      await SupabaseService.updateCommentInteraction(allComments[idx].id, allComments[idx].likedUsernames, allComments[idx].reportCount);
    }
  }

  Future<void> addStory(Story story) async {
    stories.insert(0, story);
    notifyListeners();
    await SupabaseService.saveStory(story, isNew: true);
    _saveStories();
  }

  Future<void> updateStory(String id, String title, String author, List<String> tags, int year, String status, String cover, String desc, {String? type, String? language}) async {
    final s = stories.firstWhere((element) => element.id == id);
    s.title = title;
    s.author = author;
    s.tags = tags;
    s.releaseYear = year;
    s.status = status;
    s.coverUrl = cover;
    s.description = desc;
    if (type != null) s.type = type;
    if (language != null) s.language = language;
    s.updatedAt = DateTime.now();
    notifyListeners();

    await SupabaseService.saveStory(s, isNew: false);
    _saveStories();
  }

  Future<void> addChapterToStory(String storyId, String chapTitle, {String content = '', List<String>? imageUrls}) async {
    final s = stories.firstWhere((element) => element.id == storyId);
    final order = s.chapters.length;
    s.chapters.add(Chapter(
      title: chapTitle,
      content: content,
      imageUrls: imageUrls ?? [],
    ));
    s.updatedAt = DateTime.now();
    notifyListeners();

    await SupabaseService.addChapter(storyId, order, chapTitle, content: content, imageUrls: imageUrls);
    _saveStories();
  }

  Future<void> updateChapter(String storyId, int chapIndex, String chapTitle, {String content = '', List<String>? imageUrls}) async {
    final s = stories.firstWhere((element) => element.id == storyId);
    if (chapIndex >= 0 && chapIndex < s.chapters.length) {
      s.chapters[chapIndex].title = chapTitle;
      s.chapters[chapIndex].content = content;
      if (imageUrls != null) {
        s.chapters[chapIndex].imageUrls = imageUrls;
      }
      s.updatedAt = DateTime.now();
      _saveStories();
      notifyListeners();

      await SupabaseService.updateChapter(
        storyId: storyId,
        chapterIndex: chapIndex,
        title: chapTitle,
        content: content,
        imageUrls: imageUrls,
      );
    }
  }

  Future<void> deleteChapter(String storyId, int chapterIndex) async {
    final storyIndex = stories.indexWhere((s) => s.id == storyId);
    if (storyIndex == -1) return;

    final story = stories[storyIndex];
    if (chapterIndex < 0 || chapterIndex >= story.chapters.length) return;

    final chapTitle = story.chapters[chapterIndex].title;
    final storyTitle = story.title;
    final isComic = story.type == 'comic';

    // Xóa trong bộ nhớ tạm
    story.chapters.removeAt(chapterIndex);
    notifyListeners();

    // Gọi xóa trên Supabase DB kèm dọn Storage nếu là truyện tranh
    await SupabaseService.deleteChapter(
      storyId: storyId,
      chapterIndex: chapterIndex,
      storyTitle: isComic ? storyTitle : '',
      chapterTitle: isComic ? chapTitle : '',
    );

    _saveStories();
  }

  Future<void> removeStory(String storyId) async {
    // Lấy tiêu đề truyện trước khi xóa khỏi danh sách
    final storyIndex = stories.indexWhere((s) => s.id == storyId);
    final storyTitle = storyIndex != -1 ? stories[storyIndex].title : '';

    stories.removeWhere((s) => s.id == storyId);
    for (var favSet in userFavorites.values) {
      favSet.remove(storyId);
    }
    for (var histMap in userHistory.values) {
      histMap.remove(storyId);
    }
    notifyListeners();

    // Gọi xóa trên database kèm dọn dẹp folder Storage
    await SupabaseService.deleteStory(storyId, storyTitle: storyTitle);
    _saveStories();
    _saveFavorites();
    _saveHistory();
  }

  Future<void> updateStoryStatus(String storyId, String newStatus) async {
    final idx = stories.indexWhere((s) => s.id == storyId);
    if (idx == -1) return;

    stories[idx].status = newStatus;
    notifyListeners();

    try {
      await SupabaseService.client
          .from('stories')
          .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', storyId);
      _saveStories();
    } catch (e) {
      debugPrint('Lỗi cập nhật trạng thái truyện: $e');
    }
  }

  void deleteUser(String userId) {
    registeredUsers.removeWhere((u) => u.id == userId);
    userFavorites.remove(userId);
    userHistory.remove(userId);
    _saveUsers();
    _saveFavorites();
    _saveHistory();
    notifyListeners();
  }

  String t(String key) {
    const Map<String, Map<String, String>> dict = {
      'app_title': {'vi': 'Kho Truyện Web', 'en': 'Web Novel Platform'},
      'nav_explore': {'vi': 'Khám Phá', 'en': 'Explore'},
      'nav_favorites': {'vi': 'Tủ Sách', 'en': 'Library'},
      'nav_profile': {'vi': 'Cá Nhân', 'en': 'Profile'},
      'nav_admin': {'vi': 'Quản Trị', 'en': 'Admin'},
      'nav_studio': {'vi': 'Sáng Tác', 'en': 'Studio'},
      'login': {'vi': 'Đăng Nhập', 'en': 'Login'},
      'logout': {'vi': 'Đăng Xuất', 'en': 'Logout'},
      'settings': {'vi': 'Cài đặt hệ thống', 'en': 'System Settings'},
      'dark_mode': {'vi': 'Chế độ tối', 'en': 'Dark Mode'},
      'light_mode': {'vi': 'Chế độ sáng', 'en': 'Light Mode'},
      'lang_label': {'vi': 'Ngôn ngữ', 'en': 'Language'},
      'search_hint': {'vi': 'Tìm kiếm tên truyện hoặc tác giả...', 'en': 'Search story or author...'},
      'all': {'vi': 'Tất cả', 'en': 'All'},
      'novel': {'vi': 'Novel', 'en': 'Novel'},
      'manga': {'vi': 'Manga', 'en': 'Manga'},
      'filter_all_lang': {'vi': 'Mọi ngôn ngữ', 'en': 'All Languages'},
      'filter_vi': {'vi': 'Tiếng Việt', 'en': 'Vietnamese'},
      'filter_en': {'vi': 'Tiếng Anh', 'en': 'English'},
      'author': {'vi': 'Tác giả', 'en': 'Author'},
      'genre': {'vi': 'Thể loại', 'en': 'Genre'},
      'chapters': {'vi': 'Số chương', 'en': 'Chapters'},
      'empty_favorites': {'vi': 'Bạn chưa lưu truyện nào vào tủ sách.', 'en': 'No bookmarks yet.'},
      'empty_history': {'vi': 'Bạn chưa đọc truyện nào gần đây.', 'en': 'No reading history.'},
      'read_now': {'vi': 'Đọc Từ Đầu', 'en': 'Read First'},
      'continue_reading': {'vi': 'Đọc Tiếp', 'en': 'Continue'},
      'system_options': {'vi': 'Tùy Chọn Hệ Thống', 'en': 'System Preferences'},
      'logout_account': {'vi': 'Đăng xuất khỏi tài khoản', 'en': 'Log out of account'},
      'saved_stories': {'vi': 'Truyện đã lưu', 'en': 'Saved Stories'},
      'reading_stories': {'vi': 'Đang đọc dở', 'en': 'In Progress'},
      'register_author': {'vi': 'Đăng ký làm Tác giả / Dịch giả', 'en': 'Become an Author / Translator'},
      'tab_favorites': {'vi': 'Truyện Yêu Thích', 'en': 'Favorite Stories'},
      'tab_history': {'vi': 'Lịch Sử Đọc', 'en': 'Reading History'},
      'auth_login_title': {'vi': 'Đăng Nhập Tài Khoản', 'en': 'Account Login'},
      'auth_register_title': {'vi': 'Đăng Ký Tài Khoản', 'en': 'Account Registration'},
      'username': {'vi': 'Tên đăng nhập', 'en': 'Username'},
      'password': {'vi': 'Mật khẩu', 'en': 'Password'},
      'cancel': {'vi': 'Hủy', 'en': 'Cancel'},
      'no_account': {'vi': 'Chưa có tài khoản? Nhấn để Đăng Ký', 'en': 'No account? Click to Register'},
      'has_account': {'vi': 'Đã có tài khoản? Nhấn để Đăng Nhập', 'en': 'Already have an account? Log In'},
      'sample_accounts': {'vi': 'Tài khoản mẫu có sẵn:', 'en': 'Demo accounts available:'},
      'not_logged_in_title': {'vi': 'Bạn Chưa Đăng Nhập', 'en': 'You Are Not Logged In'},
      'not_logged_in_desc': {
        'vi': 'Vui lòng đăng nhập hoặc đăng ký tài khoản để đồng bộ tủ sách,\nlịch sử đọc và tùy chỉnh trang cá nhân.',
        'en': 'Please log in or register to sync your library,\nreading history, and customize your profile.'
      },
      'locked_library_title': {'vi': 'Tủ Sách Cá Nhân Đang Khóa', 'en': 'Personal Library Locked'},
      'locked_library_desc': {
        'vi': 'Tủ sách và lịch sử đọc chỉ dành riêng cho thành viên.\nVui lòng đăng nhập để lưu trữ các bộ truyện yêu thích của bạn!',
        'en': 'Library and reading history are for members only.\nPlease log in to bookmark and track your favorites!'
      },
      'login_now': {'vi': 'Đăng Nhập Ngay', 'en': 'Log In Now'},
      'adv_search_title': {'vi': 'Bộ Lọc & Tìm Kiếm Nâng Cao', 'en': 'Advanced Search & Filters'},
      'status': {'vi': 'Tình trạng', 'en': 'Status'},
      'all_status': {'vi': 'Tất cả tình trạng', 'en': 'All Statuses'},
      'ongoing': {'vi': 'Đang tiến hành', 'en': 'Ongoing'},
      'completed': {'vi': 'Đã hoàn thành', 'en': 'Completed'},
      'sort_by': {'vi': 'Sắp xếp theo', 'en': 'Sort By'},
      'sort_newest': {'vi': 'Thời gian cập nhật mới nhất', 'en': 'Latest Updated'},
      'sort_views': {'vi': 'Lượt xem nhiều nhất', 'en': 'Most Viewed'},
      'sort_rating': {'vi': 'Điểm đánh giá cao nhất', 'en': 'Highest Rated'},
      'reset_default': {'vi': 'Đặt lại mặc định', 'en': 'Reset Default'},
      'apply_filter': {'vi': 'Áp Dụng Bộ Lọc', 'en': 'Apply Filter'},
      'manage_chapters': {'vi': 'Quản lý các chap', 'en': 'Manage Chapters'},
      'add_chapter': {'vi': 'Thêm chương mới', 'en': 'Add Chapter'},
      'edit_story': {'vi': 'Sửa thông tin truyện', 'en': 'Edit Story'},
      'delete_story': {'vi': 'Xóa truyện', 'en': 'Delete Story'},
      'story_title': {'vi': 'Tên truyện', 'en': 'Story Title'},
      'cover_url': {'vi': 'URL Ảnh bìa', 'en': 'Cover URL'},
      'description': {'vi': 'Mô tả', 'en': 'Description'},
      'chapter_title': {'vi': 'Tiêu đề chương', 'en': 'Chapter Title'},
      'chapter_content': {'vi': 'Nội dung văn bản chương', 'en': 'Chapter Content'},
      'publish_chapter': {'vi': 'Đăng Chương', 'en': 'Publish Chapter'},
      'save_changes': {'vi': 'Lưu Thay Đổi', 'en': 'Save Changes'},
      'close': {'vi': 'Đóng', 'en': 'Close'},
      'comic_studio_title': {'vi': 'Thêm Chương Truyện Tranh Mới', 'en': 'New Comic Chapter Studio'},
      'browse_device': {'vi': 'Chọn ảnh từ máy (Browse)', 'en': 'Browse Images from Device'},
      'or_image_url': {'vi': 'Hoặc dán URL link ảnh...', 'en': 'Or paste image URLs...'},
      'add_link': {'vi': 'Thêm link', 'en': 'Add Link'},
      'page_list': {'vi': 'Danh sách trang', 'en': 'Page List'},
      'clear_all': {'vi': 'Xóa tất cả', 'en': 'Clear All'},
      'preview_screen': {'vi': 'Màn Hình Xem Trước (Preview Cuộn Dọc)', 'en': 'Live Vertical Preview'},
      'edit_profile_title': {'vi': 'Chỉnh sửa thông tin cá nhân', 'en': 'Edit Profile Information'},
      'display_name': {'vi': 'Tên hiển thị', 'en': 'Display Name'},
      'bio_label': {'vi': 'Giới thiệu bản thân (Bio)', 'en': 'Biography (Bio)'},
      'save': {'vi': 'Lưu', 'en': 'Save'},
      'edit_chapter_title': {'vi': 'Sửa chương', 'en': 'Edit Chapter'},
      'edit_chapter_tooltip': {'vi': 'Sửa chương này', 'en': 'Edit this chapter'},
      'delete_chapter_tooltip': {'vi': 'Xóa chương này', 'en': 'Delete this chapter'},
      'no_chapters_yet': {'vi': 'Truyện này chưa có chương nào.', 'en': 'No chapters available yet.'},
      'page_count_suffix': {'vi': 'trang ảnh', 'en': 'pages'},
      'char_count_suffix': {'vi': 'ký tự', 'en': 'characters'},
      'edit_comic_prefix': {'vi': 'Chỉnh Sửa', 'en': 'Edit'},
      'drag_drop_hint': {'vi': 'Kéo giữ icon ☰ để đổi thứ tự trang', 'en': 'Drag ☰ icon to reorder pages'},
      'device_image_label': {'vi': 'Ảnh từ thiết bị', 'en': 'Device image'},
      'no_pages_yet': {'vi': 'Chưa có trang nào.', 'en': 'No pages yet.'},
      'select_from_device': {'vi': 'Chọn ảnh từ thư mục máy', 'en': 'Browse from device'},
      'reading_images': {'vi': 'Đang đọc ảnh...', 'en': 'Reading images...'},
      'no_preview_images': {'vi': 'Chưa có ảnh để xem trước', 'en': 'No preview available'},
      'page_number_prefix': {'vi': 'Trang', 'en': 'Page'},
      'alert_add_least_one': {'vi': 'Vui lòng thêm ít nhất 1 trang ảnh trước khi lưu!', 'en': 'Please add at least 1 image page!'},
      'settings_title': {'vi': 'Cài Đặt Hệ Thống', 'en': 'System Settings'},
      'dark_mode_desc': {'vi': 'Bật chế độ dịu mắt khi đọc ban đêm', 'en': 'Comfortable viewing in low-light'},
      'font_family_label': {'vi': 'Kiểu phông chữ đọc', 'en': 'Reader Font Family'},
      'font_sans': {'vi': 'Sans-serif (Chuẩn)', 'en': 'Sans-serif (Default)'},
      'font_serif': {'vi': 'Serif (Báo chí)', 'en': 'Serif (Editorial)'},
      'default_font_size': {'vi': 'Cỡ chữ đọc mặc định', 'en': 'Default Font Size'},
      'auth_empty_fields': {'vi': 'Vui lòng nhập đầy đủ thông tin!', 'en': 'Please fill in all fields!'},
      'auth_login_success': {'vi': 'Đăng nhập thành công!', 'en': 'Login successful!'},
      'auth_register_success': {'vi': 'Đăng ký tài khoản thành công!', 'en': 'Account registered successfully!'},
      'auth_login_button': {'vi': 'Đăng Nhập', 'en': 'Log In'},
      'auth_register_button': {'vi': 'Đăng Ký', 'en': 'Register'},
      'author_role': {'vi': 'Tác giả / Dịch giả', 'en': 'Author / Translator'},
      'role': {'vi': 'Vai trò', 'en': 'Role'},
      'admin_role': {'vi': 'Quản trị viên', 'en': 'Administrator'},
      'reader_role': {'vi': 'Độc giả', 'en': 'Reader'},
      'admin_dash_title': {'vi': 'Bảng Điều Khiển Quản Trị', 'en': 'Admin Dashboard'},
      'total_stories': {'vi': 'Tổng Truyện', 'en': 'Total Stories'},
      'total_chapters': {'vi': 'Tổng Chương', 'en': 'Total Chapters'},
      'total_views': {'vi': 'Lượt Xem', 'en': 'Total Views'},
      'total_comments': {'vi': 'Bình Luận', 'en': 'Comments'},
      'total_members': {'vi': 'Thành Viên', 'en': 'Members'},
      'tab_stories': {'vi': 'Quản Lý Truyện', 'en': 'Manage Stories'},
      'tab_comments': {'vi': 'Kiểm Duyệt Bình Luận', 'en': 'Moderate Comments'},
      'tab_users': {'vi': 'Danh Sách Người Dùng', 'en': 'User List'},
      'story_list': {'vi': 'Danh Sách Đầu Truyện', 'en': 'Story Catalog'},
      'add_new_story': {'vi': 'Thêm Truyện Mới', 'en': 'Add New Story'},
      'studio_title': {'vi': 'Creator Studio', 'en': 'Creator Studio'},
      'studio_subtitle': {'vi': 'Không gian sáng tác dành riêng cho Tác giả / Dịch giả', 'en': 'Creative space exclusively for Authors & Translators'},
      
      // Story Detail & Reading Screen
      'release_year': {'vi': 'Năm phát hành', 'en': 'Release Year'},
      'synopsis': {'vi': 'Tóm Tắt Nội Dung', 'en': 'Synopsis'},
      'no_description': {'vi': 'Chưa có tóm tắt chi tiết cho truyện này.', 'en': 'No description available for this story.'},
      'chapter_list': {'vi': 'Danh Sách Chương', 'en': 'Chapter List'},
      'no_chapters_update': {'vi': 'Truyện này hiện chưa có chương nào được cập nhật.', 'en': 'No chapters have been updated yet.'},
      'saved': {'vi': 'ĐÃ LƯU', 'en': 'BOOKMARKED'},
      'save_story': {'vi': 'LƯU TRUYỆN', 'en': 'BOOKMARK'},
      'reading_badge': {'vi': 'ĐANG ĐỌC', 'en': 'READING'},
      'read_continue_prefix': {'vi': 'ĐỌC TIẾP (CHAP', 'en': 'CONTINUE (CH.'},
      'comments_suffix': {'vi': 'bình luận', 'en': 'comments'},
      'votes_suffix': {'vi': 'đánh giá', 'en': 'votes'},
      'table_of_contents': {'vi': 'Mục Lục Chương', 'en': 'Table of Contents'},
      'story_info_and_ratings': {'vi': 'Thông tin truyện & đánh giá', 'en': 'Story Info & Ratings'},
      'auto_scroll_speed': {'vi': 'Tốc độ cuộn:', 'en': 'Scroll speed:'},
      'prev_chap': {'vi': 'Chap trước', 'en': 'Prev Chap'},
      'next_chap': {'vi': 'Chap sau', 'en': 'Next Chap'},
      'paper_light': {'vi': 'Giấy Trắng', 'en': 'White Theme'},
      'paper_sepia': {'vi': 'Giấy Vàng Sepia', 'en': 'Sepia Theme'},
      'paper_dark': {'vi': 'Giấy Đen Dark', 'en': 'Dark Theme'},
      'read_end_chap_prefix': {'vi': 'Bạn đã đọc hết', 'en': 'You have finished reading'},
      'read_latest_chap': {'vi': 'Bạn đã đọc đến chương mới nhất!', 'en': 'You have reached the latest chapter!'},
      'read_next_chap': {'vi': 'Đọc tiếp', 'en': 'Read next'},
      'back_to_info': {'vi': 'Quay về trang thông tin truyện', 'en': 'Back to Story Info'},
      'read_all_chapters': {'vi': '🎉 Bạn đã đọc hết các chương hiện có!', 'en': '🎉 You have read all available chapters!'},
      'comments_title': {'vi': 'Bình luận', 'en': 'Comments'},
      'no_comments_yet': {'vi': 'Chưa có bình luận nào. Hãy là người đầu tiên!', 'en': 'No comments yet. Be the first to comment!'},
      'write_comment_hint': {'vi': 'Viết bình luận cảm nghĩ...', 'en': 'Write your comment...'},
      'like_tooltip': {'vi': 'Thích', 'en': 'Like'},
      'report_tooltip': {'vi': 'Báo cáo vi phạm', 'en': 'Report'},
      'report_sent': {'vi': 'Đã gửi báo cáo vi phạm đến quản trị viên!', 'en': 'Report has been sent to admin!'},
      'cannot_load_image': {'vi': 'Không thể tải ảnh trang', 'en': 'Failed to load page'},
      'rating_dialog_title': {'vi': 'Đánh giá truyện', 'en': 'Rate this story'},
      'rating_stars_suffix': {'vi': 'Sao', 'en': 'Stars'},
      'send_rating': {'vi': 'Gửi đánh giá', 'en': 'Submit Rating'},
      'rating_success': {'vi': 'Bạn đã đánh giá', 'en': 'You have rated'},
      'rating_require_login': {'vi': 'Vui lòng đăng nhập để đánh giá truyện!', 'en': 'Please log in to rate this story!'},
      'bookmark_require_login': {'vi': 'Vui lòng đăng nhập để lưu truyện vào Tủ Sách cá nhân!', 'en': 'Please log in to bookmark stories!'},
      'login_require_title': {'vi': 'Yêu cầu đăng nhập', 'en': 'Login Required'},
      'no_stories_found': {'vi': 'Không tìm thấy truyện phù hợp.', 'en': 'No matching stories found.'},
      'reset_filters': {'vi': 'Đặt lại bộ lọc', 'en': 'Reset filters'},
      'chaps_count_suffix': {'vi': 'chap', 'en': 'chaps'},
      'all_story_comments': {'vi': 'Bình Luận Nổi Bật Của Bộ Truyện', 'en': 'Top Story Comments'},
      'no_comments_in_story': {'vi': 'Chưa có bình luận nào cho bộ truyện này.', 'en': 'No comments for this story yet.'},
      'likes': {'vi': 'Thích', 'en': 'Likes'},
    };
    return dict[key]?[language] ?? key;
  }

  String tGenre(String g) {
    if (g == 'Tất cả') return t('all');
    if (language == 'en') {
      switch (g) {
        case 'Tâm linh': return 'Spiritual';
        case 'Kiếm hiệp': return 'Martial Arts';
        case 'Viễn tưởng': return 'Sci-Fi';
        case 'Hành động': return 'Action';
        case 'Hành động / Manhwa': return 'Action / Manhwa';
        default: return g;
      }
    }
    return g;
  }

  static List<Story> _getInitialStories() {
    return [];
  }
}

final globalAppState = AppState();