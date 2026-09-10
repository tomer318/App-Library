class Comment {
  final String id;
  final String storyId;
  final int chapterIndex;
  final String username;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.storyId,
    required this.chapterIndex,
    required this.username,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'storyId': storyId,
    'chapterIndex': chapterIndex,
    'username': username,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'],
    storyId: json['storyId'],
    chapterIndex: json['chapterIndex'],
    username: json['username'],
    content: json['content'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class Chapter {
  String title;
  String content;

  Chapter({
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
  };

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
    title: json['title'],
    content: json['content'],
  );
}

class Story {
  final String id;
  String title;
  String author;
  String genre;
  String coverUrl;
  String description;
  final List<Chapter> chapters;
  final List<int> ratings;
  int viewCount;

  Story({
    required this.id,
    required this.title,
    required this.author,
    required this.genre,
    required this.coverUrl,
    required this.description,
    required this.chapters,
    List<int>? ratings,
    this.viewCount = 120,
  }) : ratings = ratings ?? [5, 5, 4];

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
    'chapters': chapters.map((c) => c.toJson()).toList(),
    'ratings': ratings,
    'viewCount': viewCount,
  };

  factory Story.fromJson(Map<String, dynamic> json) => Story(
    id: json['id'],
    title: json['title'],
    author: json['author'],
    genre: json['genre'],
    coverUrl: json['coverUrl'],
    description: json['description'],
    chapters: (json['chapters'] as List).map((c) => Chapter.fromJson(c)).toList(),
    ratings: List<int>.from(json['ratings'] ?? [5, 5, 4]),
    viewCount: json['viewCount'] ?? 0,
  );
}

class AppUser {
  final String id;
  String username;
  String password;
  final String role;
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