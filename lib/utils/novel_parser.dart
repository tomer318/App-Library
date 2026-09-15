class ParsedChapter {
  final String title;
  final String content;

  ParsedChapter({required this.title, required this.content});
}

class NovelParser {
  // Nhận diện tiêu đề: Prologue, Epilogue, Chapter 1, Chapter2, Chapter i, Chương 1...
  static final RegExp _headerRegex = RegExp(
    r'^(Prologue|Epilogue|Chapter\s*[0-9ivxlcdm]+|Chương\s*\d+|Hồi\s*\d+|Mở\s+đầu|Kết\s+thúc)[\s:\-|]*(.*)$',
    caseSensitive: false,
  );

  // Điểm kết thúc sách (bỏ qua phụ lục, lời bạt sau Epilogue)
  static final RegExp _stopRegex = RegExp(
    r'^(Character Profiles|Afterword|Profile|Yen Newsletter|Lời bạt|Thông tin nhân vật)',
    caseSensitive: false,
  );

  static List<ParsedChapter> parseTxtFile(String rawText) {
    if (rawText.trim().isEmpty) return [];

    final lines = rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

    // 1. Tìm tất cả vị trí xuất hiện của Header chương
    final List<int> headerIndices = [];
    for (int i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.isEmpty) continue;

      if (_headerRegex.hasMatch(trimmed)) {
        headerIndices.add(i);
      }
    }

    if (headerIndices.isEmpty) {
      return [ParsedChapter(title: 'Toàn văn', content: rawText.trim())];
    }

    // 2. Thu thập các chương và loại bỏ mục lục (nội dung ngắn < 120 ký tự)
    final List<ParsedChapter> validChapters = [];

    for (int k = 0; k < headerIndices.length; k++) {
      final startIndex = headerIndices[k];
      final rawHeaderLine = lines[startIndex].trim();

      // Điểm kết thúc của chương là trước header tiếp theo hoặc hết file
      int endIndex = (k + 1 < headerIndices.length) ? headerIndices[k + 1] : lines.length;

      // Gom nội dung giữa startIndex và endIndex
      final List<String> chapterBodyLines = [];
      for (int i = startIndex + 1; i < endIndex; i++) {
        final line = lines[i];
        final trimmed = line.trim();

        // Nếu chạm từ khóa kết thúc (như Character Profiles ở cuối sách) thì dừng
        if (_stopRegex.hasMatch(trimmed)) {
          break;
        }

        // Bỏ qua các dòng banner lặp
        if (trimmed.toLowerCase().startsWith('chapter ') && trimmed.contains('|')) continue;
        if (trimmed.toUpperCase().startsWith('OVERLORD')) continue;
        if (trimmed.toUpperCase() == rawHeaderLine.toUpperCase()) continue;

        chapterBodyLines.add(line);
      }

      final body = _cleanChapterContent(chapterBodyLines);

      // Nếu nội dung > 120 ký tự thì ĐÂY LÀ CHƯƠNG THẬT (loại bỏ hoàn toàn mục lục)
      if (body.length > 120) {
        final cleanTitle = _formatChapterTitle(rawHeaderLine);
        validChapters.add(ParsedChapter(title: cleanTitle, content: body));
      }
    }

    // Nếu không tách được theo tiêu đề thì lưu toàn bộ nội dung
    if (validChapters.isEmpty && rawText.trim().isNotEmpty) {
      validChapters.add(ParsedChapter(title: 'Toàn văn', content: rawText.trim()));
    }

    return validChapters;
  }

  // Chuẩn hóa tên chương: "Chapter2 The Floor..." -> "Chapter 2: The Floor..."
  static String _formatChapterTitle(String rawTitle) {
    final match = _headerRegex.firstMatch(rawTitle);
    if (match == null) return rawTitle;

    var prefix = match.group(1)!.trim();
    var suffix = match.group(2)!.trim();

    // Sửa chữ La Mã hoặc viết liền "Chapter2" -> "Chapter 2"
    prefix = prefix.replaceAllMapped(RegExp(r'(Chapter|Chương)(\d+)', caseSensitive: false), (m) => '${m[1]} ${m[2]}');
    if (prefix.toLowerCase() == 'chapter i') prefix = 'Chapter 1';
    if (prefix.toLowerCase() == 'chapter ii') prefix = 'Chapter 2';
    if (prefix.toLowerCase() == 'chapter iii') prefix = 'Chapter 3';
    if (prefix.toLowerCase() == 'chapter iv') prefix = 'Chapter 4';
    if (prefix.toLowerCase() == 'chapter v') prefix = 'Chapter 5';

    // Viết hoa chữ cái đầu
    prefix = prefix.substring(0, 1).toUpperCase() + prefix.substring(1);

    if (suffix.isNotEmpty) {
      return '$prefix: $suffix';
    }
    return prefix;
  }

  static String _cleanChapterContent(List<String> rawLines) {
    var text = rawLines.join('\n').trim();
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text;
  }
}