import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark;
  String language = 'vi';
  AppUser? currentUser;

  // Cài đặt đọc truyện
  double defaultFontSize = 18.0;
  String fontFamily = 'Mặc định'; // 'Mặc định' hoặc 'Serif'

  // Tìm kiếm cơ bản & nâng cao
  String searchQuery = '';
  String selectedGenre = 'Tất cả';
  String filterStatus = 'Tất cả'; // 'Tất cả', 'Đang tiến hành', 'Đã hoàn thành'
  String filterAuthor = '';
  String sortBy = 'Mới nhất'; // 'Mới nhất', 'Lượt xem', 'Điểm đánh giá'
  String selectedType = 'all'; // 'all', 'novel', 'comic'
  String storyLanguageFilter = 'all'; // 'all', 'vi', 'en'

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

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    final savedTheme = prefs.getString('themeMode') ?? 'dark';
    themeMode = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;
    language = prefs.getString('language') ?? 'vi';
    defaultFontSize = prefs.getDouble('fontSize') ?? 18.0;
    fontFamily = prefs.getString('fontFamily') ?? 'Mặc định';

    final usersRaw = prefs.getString('registeredUsers');
    if (usersRaw != null) {
      final List decoded = jsonDecode(usersRaw);
      registeredUsers = decoded.map((e) => AppUser.fromJson(e)).toList();
    } else {
      registeredUsers = [
        AppUser(id: 'u_admin', username: 'admin', password: '123', role: 'admin', bio: 'Quản trị viên tối cao'),
        AppUser(id: 'u_author', username: 'tacgia', password: '123', role: 'author', bio: 'Họa sĩ truyện tranh độc lập'),
        AppUser(id: 'u_1', username: 'docgia1', password: '123', role: 'reader', bio: 'Đam mê tu tiên & kiếm hiệp'),
      ];
      _saveUsers();
    }

    final currentUserRaw = prefs.getString('currentUser');
    if (currentUserRaw != null) {
      currentUser = AppUser.fromJson(jsonDecode(currentUserRaw));
    }

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

    final storiesRaw = prefs.getString('stories');
    if (storiesRaw != null) {
      final List decoded = jsonDecode(storiesRaw);
      stories = decoded.map((e) => Story.fromJson(e)).toList();
    } else {
      stories = _getInitialStories();
      _saveStories();
    }

    final commentsRaw = prefs.getString('allComments');
    if (commentsRaw != null) {
      final List decoded = jsonDecode(commentsRaw);
      allComments = decoded.map((e) => Comment.fromJson(e)).toList();
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

  List<String> get genres {
    final set = {'Tất cả'};
    for (var s in stories) {
      set.add(s.genre);
    }
    return set.toList();
  }

  // BỘ LỌC TÌM KIẾM NÂNG CAO
  List<Story> get filteredStories {
    final list = stories.where((s) {
      final matchesSearch = s.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          s.author.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesAuthor = filterAuthor.isEmpty || s.author.toLowerCase().contains(filterAuthor.toLowerCase());
      final matchesGenre = selectedGenre == 'Tất cả' || s.genre == selectedGenre;
      final matchesStatus = filterStatus == 'Tất cả' || s.status == filterStatus;
      final matchesType = selectedType == 'all' || s.type == selectedType;
      final matchesLang = storyLanguageFilter == 'all' || s.language == storyLanguageFilter;

      return matchesSearch && matchesAuthor && matchesGenre && matchesStatus && matchesType && matchesLang;
    }).toList();

    if (sortBy == 'Lượt xem') {
      list.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    } else if (sortBy == 'Điểm đánh giá') {
      list.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    } else {
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    return list;
  }

  void setSearchQuery(String q) {
    searchQuery = q;
    notifyListeners();
  }

  void setSelectedGenre(String g) {
    selectedGenre = g;
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

  void setAdvancedFilter({required String author, required String genre, required String status, required String sort}) {
    filterAuthor = author;
    selectedGenre = genre;
    filterStatus = status;
    sortBy = sort;
    notifyListeners();
  }

  void resetFilters() {
    searchQuery = '';
    selectedGenre = 'Tất cả';
    filterStatus = 'Tất cả';
    filterAuthor = '';
    sortBy = 'Mới nhất';
    notifyListeners();
  }

  void saveReadingProgress(String storyId, int chapIndex) {
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
      _saveStories();
    }
    _saveHistory();
    notifyListeners();
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

  String? login(String username, String password) {
    final user = registeredUsers.cast<AppUser?>().firstWhere(
      (u) => u?.username.toLowerCase() == username.trim().toLowerCase(),
      orElse: () => null,
    );

    if (user == null) return 'Tài khoản không tồn tại trên hệ thống!';
    if (user.password != password) return 'Mật khẩu không chính xác!';

    currentUser = user;
    _saveUsers();
    notifyListeners();
    return null;
  }

  String? register(String username, String password, {bool makeAdmin = false}) {
    final exists = registeredUsers.any(
      (u) => u.username.toLowerCase() == username.trim().toLowerCase(),
    );
    if (exists) return 'Tên đăng nhập đã được sử dụng!';
    if (password.length < 3) return 'Mật khẩu phải từ 3 ký tự trở lên!';

    final newUser = AppUser(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      username: username.trim(),
      password: password,
      role: makeAdmin ? 'admin' : 'reader',
    );
    registeredUsers.add(newUser);
    currentUser = newUser;
    _saveUsers();
    notifyListeners();
    return null;
  }

  void becomeAuthor() {
    if (currentUser != null && currentUser!.role == 'reader') {
      currentUser!.role = 'author';
      final idx = registeredUsers.indexWhere((u) => u.id == currentUser!.id);
      if (idx != -1) registeredUsers[idx] = currentUser!;
      _saveUsers();
      notifyListeners();
    }
  }

  void logout() {
    currentUser = null;
    _saveUsers();
    notifyListeners();
  }

  void updateProfile(String newName, String newBio) {
    if (currentUser != null) {
      currentUser!.username = newName;
      currentUser!.bio = newBio;
      final idx = registeredUsers.indexWhere((u) => u.id == currentUser!.id);
      if (idx != -1) registeredUsers[idx] = currentUser!;
      _saveUsers();
      notifyListeners();
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

  void toggleFavorite(String storyId) {
    if (currentUser == null) return;
    final userId = currentUser!.id;
    if (!userFavorites.containsKey(userId)) {
      userFavorites[userId] = {};
    }

    if (userFavorites[userId]!.contains(storyId)) {
      userFavorites[userId]!.remove(storyId);
    } else {
      userFavorites[userId]!.add(storyId);
    }
    _saveFavorites();
    notifyListeners();
  }

  void rateStory(String storyId, int rating) {
    final story = stories.firstWhere((s) => s.id == storyId);
    story.ratings.add(rating);
    _saveStories();
    notifyListeners();
  }

  List<Comment> getCommentsForChapter(String storyId, int chapIndex) {
    return allComments.where((c) => c.storyId == storyId && c.chapterIndex == chapIndex).toList();
  }

  void addComment(String storyId, int chapIndex, String content) {
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
  }

  void deleteComment(String commentId) {
    allComments.removeWhere((c) => c.id == commentId);
    _saveComments();
    notifyListeners();
  }

  void toggleLikeComment(String commentId) {
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
    }
  }

  void reportComment(String commentId) {
    final idx = allComments.indexWhere((c) => c.id == commentId);
    if (idx != -1) {
      allComments[idx].reportCount++;
      _saveComments();
      notifyListeners();
    }
  }

  void addStory(Story story) {
    stories.insert(0, story);
    _saveStories();
    notifyListeners();
  }

  void updateStory(String id, String title, String author, String genre, String status, String cover, String desc) {
    final s = stories.firstWhere((element) => element.id == id);
    s.title = title;
    s.author = author;
    s.genre = genre;
    s.status = status;
    s.coverUrl = cover;
    s.description = desc;
    s.updatedAt = DateTime.now();
    _saveStories();
    notifyListeners();
  }

  void addChapterToStory(String storyId, String chapTitle, {String content = '', List<String>? imageUrls}) {
    final s = stories.firstWhere((element) => element.id == storyId);
    s.chapters.add(Chapter(
      title: chapTitle,
      content: content,
      imageUrls: imageUrls ?? [],
    ));
    s.updatedAt = DateTime.now();
    _saveStories();
    notifyListeners();
  }

  void updateChapter(String storyId, int chapIndex, String chapTitle, {String content = '', List<String>? imageUrls}) {
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
    }
  }

  void deleteChapter(String storyId, int chapIndex) {
    final s = stories.firstWhere((element) => element.id == storyId);
    if (chapIndex >= 0 && chapIndex < s.chapters.length) {
      s.chapters.removeAt(chapIndex);
      s.updatedAt = DateTime.now();
      _saveStories();
      notifyListeners();
    }
  }

  void removeStory(String storyId) {
    stories.removeWhere((s) => s.id == storyId);
    for (var favSet in userFavorites.values) {
      favSet.remove(storyId);
    }
    for (var histMap in userHistory.values) {
      histMap.remove(storyId);
    }
    allComments.removeWhere((c) => c.storyId == storyId);
    _saveStories();
    _saveFavorites();
    _saveHistory();
    _saveComments();
    notifyListeners();
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
      // Profile & System
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
      // Advanced Search Dialog
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
      // Dialogs & Actions
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
      // Profile edit dialog
      'edit_profile_title': {'vi': 'Chỉnh sửa thông tin cá nhân', 'en': 'Edit Profile Information'},
      'display_name': {'vi': 'Tên hiển thị', 'en': 'Display Name'},
      'bio_label': {'vi': 'Giới thiệu bản thân (Bio)', 'en': 'Biography (Bio)'},
      'save': {'vi': 'Lưu', 'en': 'Save'},
      // Chapter Manager
      'edit_chapter_title': {'vi': 'Sửa chương', 'en': 'Edit Chapter'},
      'edit_chapter_tooltip': {'vi': 'Sửa chương này', 'en': 'Edit this chapter'},
      'delete_chapter_tooltip': {'vi': 'Xóa chương này', 'en': 'Delete this chapter'},
      'no_chapters_yet': {'vi': 'Truyện này chưa có chương nào.', 'en': 'No chapters available yet.'},
      'page_count_suffix': {'vi': 'trang ảnh', 'en': 'pages'},
      'char_count_suffix': {'vi': 'ký tự', 'en': 'characters'},
      // Comic editor
      'edit_comic_prefix': {'vi': 'Chỉnh Sửa', 'en': 'Edit'},
      'drag_drop_hint': {'vi': 'Kéo giữ icon ☰ để đổi thứ tự trang', 'en': 'Drag ☰ icon to reorder pages'},
      'device_image_label': {'vi': 'Ảnh từ thiết bị', 'en': 'Device image'},
      'no_pages_yet': {'vi': 'Chưa có trang nào.', 'en': 'No pages yet.'},
      'select_from_device': {'vi': 'Chọn ảnh từ thư mục máy', 'en': 'Browse from device'},
      'reading_images': {'vi': 'Đang đọc ảnh...', 'en': 'Reading images...'},
      'no_preview_images': {'vi': 'Chưa có ảnh để xem trước', 'en': 'No preview available'},
      'page_number_prefix': {'vi': 'Trang', 'en': 'Page'},
      'alert_add_least_one': {'vi': 'Vui lòng thêm ít nhất 1 trang ảnh trước khi lưu!', 'en': 'Please add at least 1 image page!'},
      // Settings dialog
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
      // Admin Dashboard
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
    };
    return dict[key]?[language] ?? key;
  }

  // DỊCH TÊN THỂ LOẠI THEO NGÔN NGỮ ĐANG CHỌN
  String tGenre(String g) {
    if (g == 'Tất cả') return t('all');
    if (language == 'en') {
      switch (g) {
        case 'Tâm linh': return 'Spiritual';
        case 'Kiếm hiệp': return 'Martial Arts';
        case 'Viễn tưởng': return 'Sci-Fi';
        case 'Hành động / Manhwa': return 'Action / Manhwa';
        default: return g;
      }
    }
    return g;
  }

  static List<Story> _getInitialStories() {
    return [
      Story(
        id: '1',
        title: 'Hành Trình Về Phương Đông',
        author: 'Baird T. Spalding',
        genre: 'Tâm linh',
        status: 'Đã hoàn thành',
        type: 'novel',
        creatorId: 'u_admin',
        coverUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400&q=80',
        description: 'Cuốn sách ghi lại những trải nghiệm sâu sắc của đoàn thám hiểm Hoàng gia Anh tại vùng đất Ấn Độ huyền bí.',
        viewCount: 1450,
        ratings: [5, 5, 5, 4],
        chapters: [
          Chapter(
            title: 'Chương 1: Lời giới thiệu đoàn thám hiểm',
            content: 'Đoàn khảo cứu gồm các nhà khoa học hàng đầu được cử đến phương Đông để tìm hiểu về các hiện tượng tâm linh...\n\nHọ đã khám phá ra những chân lý bất biến về vũ trụ và tinh thần nhân loại.',
          ),
          Chapter(
            title: 'Chương 2: Cuộc gặp gỡ bên dòng sông Hằng',
            content: 'Bên bờ sông linh thiêng buổi sớm mai, không gian tĩnh lặng lạ thường...\n\nVị đạo sĩ già chia sẻ về sự bình an nội tại và con đường tìm lại chính mình.',
          ),
        ],
      ),
      Story(
        id: '2',
        title: 'Hiệp Khách Hành Giả',
        author: 'Kim Dung',
        genre: 'Kiếm hiệp',
        status: 'Đang tiến hành',
        type: 'novel',
        creatorId: 'u_admin',
        coverUrl: 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=400&q=80',
        description: 'Chuyện về những hiệp sĩ giang hồ đầy phong trần, tình huynh đệ và những bí kíp võ học kinh thiên động địa.',
        viewCount: 890,
        ratings: [5, 4, 4],
        chapters: [
          Chapter(
            title: 'Chương 1: Gió nổi chốn biên ải',
            content: 'Gió tuyết gầm rú qua trập trùng rặng núi. Trong quán trọ nhỏ ven đường, đao kiếm xé toạc màn đêm tĩnh mịch...\n\nMột vị kiếm khách cô độc bước vào mang theo bí mật động trời.',
          ),
        ],
      ),
      Story(
        id: '3',
        title: 'Biên Niên Sử Vị Lai 2099',
        author: 'Sci-Fi Studio',
        genre: 'Viễn tưởng',
        status: 'Đang tiến hành',
        type: 'novel',
        creatorId: 'u_admin',
        coverUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=400&q=80',
        description: 'Thế giới năm 2099, nơi mạng nơ-ron và con người kết nối với nhau trong thành phố công nghệ ánh sáng.',
        viewCount: 520,
        ratings: [5, 5],
        chapters: [
          Chapter(
            title: 'Chương 1: Kỷ nguyên Cybernetic',
            content: 'Ánh sáng neon chiếu rọi qua những tầng mây bụi kim loại. Hệ thống máy chủ trung tâm phát đi thông điệp khởi động chu kỳ mới...',
          ),
        ],
      ),
      Story(
        id: '4',
        title: 'Solo Leveling: Thợ Săn Tối Thượng',
        author: 'Chugong & DUBU',
        genre: 'Hành động / Manhwa',
        type: 'comic',
        status: 'Đang tiến hành',
        creatorId: 'u_author',
        coverUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=400&q=80',
        description: 'Thế giới xuất hiện những cánh cổng nối với hầm ngục quái vật. Thợ săn hạng E yếu nhất bắt đầu hành trình thăng cấp không giới hạn.',
        viewCount: 3820,
        ratings: [5, 5, 5, 5],
        chapters: [
          Chapter(
            title: 'Chương 1: Cửa Hầm Ngục Kép',
            imageUrls: [
              'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800&q=80',
              'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&q=80',
              'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=800&q=80',
            ],
          ),
          Chapter(
            title: 'Chương 2: Tượng Đá Khổng Lồ',
            imageUrls: [
              'https://images.unsplash.com/photo-1514539079130-25950c84af65?w=800&q=80',
              'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&q=80',
            ],
          ),
        ],
      ),
      Story(
        id: '5',
        title: 'The Cyberpunk Odyssey 2099',
        author: 'Alexander Vance',
        genre: 'Sci-Fi',
        type: 'novel',
        language: 'en',
        status: 'Đang tiến hành',
        creatorId: 'u_admin',
        coverUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=400&q=80',
        description: 'An epic cyberpunk journey across neon-lit megacities and neural cyberspace.',
        viewCount: 2150,
        ratings: [5, 5, 5],
        chapters: [
          Chapter(
            title: 'Chapter 1: Neon Shadows',
            content: 'The rain poured relentlessly over the towering skyscrapers of Neo-Veridia...\nA lone hacker prepared the ultimate breach.',
          ),
        ],
      ),
    ];
  }
}

final globalAppState = AppState();