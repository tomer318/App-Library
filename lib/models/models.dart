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
  List<String> tags; // ĐA THỂ LOẠI (TAGS)
  int releaseYear;   // NĂM PHÁT HÀNH
  String status;
  String type;
  String language;
  String creatorId;
  String coverUrl;
  String description;
  int viewCount;
  List<int> ratings;
  List<Chapter> chapters;
  DateTime updatedAt;

  // Thuộc tính phụ tương thích ngược
  String get genre => tags.isNotEmpty ? tags.first : 'Khác';

  Story({
    required this.id,
    required this.title,
    required this.author,
    required this.tags,
    this.releaseYear = 2024,
    this.status = 'Đang tiến hành',
    this.type = 'novel',
    this.language = 'vi',
    this.creatorId = 'u_admin',
    required this.coverUrl,
    required this.description,
    this.viewCount = 0,
    List<int>? ratings,
    List<Chapter>? chapters,
    DateTime? updatedAt,
  })  : ratings = ratings ?? [],
        chapters = chapters ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  double get averageRating {
    if (ratings.isEmpty) return 5.0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'tags': tags,
        'releaseYear': releaseYear,
        'status': status,
        'type': type,
        'language': language,
        'creatorId': creatorId,
        'coverUrl': coverUrl,
        'description': description,
        'viewCount': viewCount,
        'ratings': ratings,
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Story.fromJson(Map<String, dynamic> json) => Story(
        id: json['id'],
        title: json['title'],
        author: json['author'],
        tags: json['tags'] != null ? List<String>.from(json['tags']) : (json['genre'] != null ? [json['genre']] : ['Khác']),
        releaseYear: json['releaseYear'] ?? 2024,
        status: json['status'] ?? 'Đang tiến hành',
        type: json['type'] ?? 'novel',
        language: json['language'] ?? 'vi',
        creatorId: json['creatorId'] ?? 'u_admin',
        coverUrl: json['coverUrl'],
        description: json['description'] ?? '',
        viewCount: json['viewCount'] ?? 0,
        ratings: json['ratings'] != null ? List<int>.from(json['ratings']) : [],
        chapters: json['chapters'] != null ? (json['chapters'] as List).map((c) => Chapter.fromJson(c)).toList() : [],
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