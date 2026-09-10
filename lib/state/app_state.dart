import 'package:flutter/material.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark;
  String language = 'vi';
  AppUser? currentUser;
  final Set<String> favoriteStoryIds = {};
  final Map<String, int> readingHistory = {};

  String searchQuery = '';
  String selectedGenre = 'Tất cả';
  double defaultFontSize = 18.0;

  // Danh sách tài khoản đã đăng ký trong hệ thống
  final List<AppUser> registeredUsers = [
    AppUser(id: 'u_admin', username: 'admin', password: '123', role: 'admin', bio: 'Quản trị viên tối cao'),
    AppUser(id: 'u_1', username: 'docgia1', password: '123', role: 'reader', bio: 'Đam mê tu tiên & kiếm hiệp'),
  ];

  // Danh sách bình luận tập trung để Admin dễ kiểm duyệt
  final List<Comment> allComments = [
    Comment(
      id: 'c1',
      storyId: '1',
      chapterIndex: 0,
      username: 'docgia1',
      content: 'Chương 1 mở đầu rất sâu sắc!',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  final List<Story> stories = [
    Story(
      id: '1',
      title: 'Hành Trình Về Phương Đông',
      author: 'Baird T. Spalding',
      genre: 'Tâm linh',
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
  ];

  List<String> get genres {
    final set = {'Tất cả'};
    for (var s in stories) {
      set.add(s.genre);
    }
    return set.toList();
  }

  List<Story> get filteredStories {
    return stories.where((s) {
      final matchesSearch = s.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          s.author.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesGenre = selectedGenre == 'Tất cả' || s.genre == selectedGenre;
      return matchesSearch && matchesGenre;
    }).toList();
  }

  void setSearchQuery(String q) {
    searchQuery = q;
    notifyListeners();
  }

  void setSelectedGenre(String g) {
    selectedGenre = g;
    notifyListeners();
  }

  void saveReadingProgress(String storyId, int chapIndex) {
    readingHistory[storyId] = chapIndex;
    final story = stories.firstWhere((s) => s.id == storyId, orElse: () => stories.first);
    story.viewCount++;
    notifyListeners();
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggleLanguage() {
    language = language == 'vi' ? 'en' : 'vi';
    notifyListeners();
  }

  // Đăng nhập: Trả về null nếu thành công, trả về chuỗi báo lỗi nếu thất bại
  String? login(String username, String password) {
    final user = registeredUsers.cast<AppUser?>().firstWhere(
      (u) => u?.username.toLowerCase() == username.trim().toLowerCase(),
      orElse: () => null,
    );

    if (user == null) {
      return 'Tài khoản không tồn tại trên hệ thống!';
    }
    if (user.password != password) {
      return 'Mật khẩu không chính xác!';
    }

    currentUser = user;
    notifyListeners();
    return null;
  }

  // Đăng ký: Trả về null nếu thành công
  String? register(String username, String password, {bool makeAdmin = false}) {
    final exists = registeredUsers.any(
      (u) => u.username.toLowerCase() == username.trim().toLowerCase(),
    );
    if (exists) {
      return 'Tên đăng nhập đã được sử dụng!';
    }
    if (password.length < 3) {
      return 'Mật khẩu phải từ 3 ký tự trở lên!';
    }

    final newUser = AppUser(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      username: username.trim(),
      password: password,
      role: makeAdmin ? 'admin' : 'reader',
    );
    registeredUsers.add(newUser);
    currentUser = newUser;
    notifyListeners();
    return null;
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  void updateProfile(String newName, String newBio) {
    if (currentUser != null) {
      currentUser!.username = newName;
      currentUser!.bio = newBio;
      notifyListeners();
    }
  }

  void toggleFavorite(String storyId) {
    if (favoriteStoryIds.contains(storyId)) {
      favoriteStoryIds.remove(storyId);
    } else {
      favoriteStoryIds.add(storyId);
    }
    notifyListeners();
  }

  void rateStory(String storyId, int rating) {
    final story = stories.firstWhere((s) => s.id == storyId);
    story.ratings.add(rating);
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
    notifyListeners();
  }

  void deleteComment(String commentId) {
    allComments.removeWhere((c) => c.id == commentId);
    notifyListeners();
  }

  // Quản trị Admin truyện
  void addStory(Story story) {
    stories.insert(0, story);
    notifyListeners();
  }

  void updateStory(String id, String title, String author, String genre, String cover, String desc) {
    final s = stories.firstWhere((element) => element.id == id);
    s.title = title;
    s.author = author;
    s.genre = genre;
    s.coverUrl = cover;
    s.description = desc;
    notifyListeners();
  }

  void addChapterToStory(String storyId, String chapTitle, String content) {
    final s = stories.firstWhere((element) => element.id == storyId);
    s.chapters.add(Chapter(title: chapTitle, content: content));
    notifyListeners();
  }

  void removeStory(String storyId) {
    stories.removeWhere((s) => s.id == storyId);
    favoriteStoryIds.remove(storyId);
    readingHistory.remove(storyId);
    allComments.removeWhere((c) => c.storyId == storyId);
    notifyListeners();
  }

  void deleteUser(String userId) {
    registeredUsers.removeWhere((u) => u.id == userId);
    notifyListeners();
  }

  String t(String key) {
    const Map<String, Map<String, String>> dict = {
      'app_title': {'vi': 'Kho Truyện Web', 'en': 'Web Novel Platform'},
      'nav_explore': {'vi': 'Khám Phá', 'en': 'Explore'},
      'nav_favorites': {'vi': 'Tủ Sách', 'en': 'Bookmarks'},
      'nav_profile': {'vi': 'Cá Nhân', 'en': 'Profile'},
      'nav_admin': {'vi': 'Quản Trị', 'en': 'Admin'},
      'login': {'vi': 'Đăng Nhập', 'en': 'Login'},
      'logout': {'vi': 'Đăng Xuất', 'en': 'Logout'},
      'add_story': {'vi': 'Thêm Truyện Mới', 'en': 'Add Story'},
      'search_hint': {'vi': 'Tìm kiếm tên truyện hoặc tác giả...', 'en': 'Search story or author...'},
      'author': {'vi': 'Tác giả', 'en': 'Author'},
      'genre': {'vi': 'Thể loại', 'en': 'Genre'},
      'chapters': {'vi': 'Số chương', 'en': 'Chapters'},
      'empty_favorites': {'vi': 'Chưa có truyện nào trong tủ sách.', 'en': 'No bookmarks yet.'},
      'read_now': {'vi': 'Đọc Từ Đầu', 'en': 'Read First'},
      'continue_reading': {'vi': 'Đọc Tiếp', 'en': 'Continue'},
    };
    return dict[key]?[language] ?? key;
  }
}

final globalAppState = AppState();