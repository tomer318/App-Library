class Comment {
  final String id;
  final String storyId;
  final int chapterIndex;
  final String username;
  final String content;
  final DateTime createdAt;
  final List<String> likedUsernames;
  int reportCount;

  Comment({
    required this.id,
    required this.storyId,
    required this.chapterIndex,
    required this.username,
    required this.content,
    required this.createdAt,
    List<String>? likedUsernames,
    this.reportCount = 0,
  }) : likedUsernames = likedUsernames ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'storyId': storyId,
    'chapterIndex': chapterIndex,
    'username': username,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'likedUsernames': likedUsernames,
    'reportCount': reportCount,
  };

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'],
    storyId: json['storyId'],
    chapterIndex: json['chapterIndex'],
    username: json['username'],
    content: json['content'],
    createdAt: DateTime.parse(json['createdAt']),
    likedUsernames: List<String>.from(json['likedUsernames'] ?? []),
    reportCount: json['reportCount'] ?? 0,
  );
}

class Chapter {
  String title;
  String content; // Dành cho truyện chữ
  List<String> imageUrls; // Dành cho truyện tranh (Comic/Manga)

  Chapter({
    required this.title,
    this.content = '',
    List<String>? imageUrls,
  }) : imageUrls = imageUrls ?? [];

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'imageUrls': imageUrls,
  };

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
    title: json['title'],
    content: json['content'] ?? '',
    imageUrls: List<String>.from(json['imageUrls'] ?? []),
  );
}

class Story {
  final String id;
  String title;
  String author;
  String genre;
  String coverUrl;
  String description;
  String status; // 'Đang tiến hành' hoặc 'Đã hoàn thành'
  String type; // 'novel' (Truyện chữ) hoặc 'comic' (Truyện tranh)
  String language; // 'vi' hoặc 'en'
  String creatorId; // ID người tạo truyện
  final List<Chapter> chapters;
  final List<int> ratings;
  int viewCount;
  DateTime updatedAt;

  Story({
    required this.id,
    required this.title,
    required this.author,
    required this.genre,
    required this.coverUrl,
    required this.description,
    required this.chapters,
    this.status = 'Đang tiến hành',
    this.type = 'novel',
    this.creatorId = 'u_admin',
    this.language = 'vi',
    List<int>? ratings,
    this.viewCount = 120,
    DateTime? updatedAt,
  })  : ratings = ratings ?? [5, 5, 4],
        updatedAt = updatedAt ?? DateTime.now();

  double get averageRating {
    if (ratings.isEmpty) return 5.0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'genre': genre,
    'coverUrl': coverUrl,
    'description': description,
    'status': status,
    'type': type,
    'creatorId': creatorId,
    'language': language,
    'chapters': chapters.map((c) => c.toJson()).toList(),
    'ratings': ratings,
    'viewCount': viewCount,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Story.fromJson(Map<String, dynamic> json) => Story(
    id: json['id'],
    title: json['title'],
    author: json['author'],
    genre: json['genre'],
    coverUrl: json['coverUrl'],
    description: json['description'],
    status: json['status'] ?? 'Đang tiến hành',
    type: json['type'] ?? 'novel',
    creatorId: json['creatorId'] ?? 'u_admin',
    language: json['language'] ?? 'vi',
    chapters: (json['chapters'] as List).map((c) => Chapter.fromJson(c)).toList(),
    ratings: List<int>.from(json['ratings'] ?? [5, 5, 4]),
    viewCount: json['viewCount'] ?? 0,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
  );
}

class ReadingItem {
  final String storyId;
  final int chapterIndex;
  final DateTime lastReadAt;

  ReadingItem({
    required this.storyId,
    required this.chapterIndex,
    required this.lastReadAt,
  });

  Map<String, dynamic> toJson() => {
    'storyId': storyId,
    'chapterIndex': chapterIndex,
    'lastReadAt': lastReadAt.toIso8601String(),
  };

  factory ReadingItem.fromJson(Map<String, dynamic> json) => ReadingItem(
    storyId: json['storyId'],
    chapterIndex: json['chapterIndex'],
    lastReadAt: DateTime.parse(json['lastReadAt']),
  );
}

class AppUser {
  final String id;
  String username;
  String password;
  String role; // 'admin', 'author', hoặc 'reader'
  String bio;

  AppUser({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    this.bio = 'Mọt sách chính hiệu',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'password': password,
    'role': role,
    'bio': bio,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'],
    username: json['username'],
    password: json['password'],
    role: json['role'],
    bio: json['bio'] ?? 'Mọt sách chính hiệu',
  );
}