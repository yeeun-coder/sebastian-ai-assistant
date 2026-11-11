class DiaryEntry {
  final int id;
  final String diaryDate;
  final String? title;
  final String content;
  final String? mood;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DiaryEntry({
    required this.id,
    required this.diaryDate,
    this.title,
    required this.content,
    this.mood,
    this.createdAt,
    this.updatedAt,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as int,
      diaryDate: json['diaryDate'] as String,
      title: json['title'] as String?,
      content: json['content'] as String,
      mood: json['mood'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  String get displayTime {
    final dt = createdAt?.toLocal();
    if (dt == null) return '';
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get displayTitle {
    final t = title?.trim();
    if (t != null && t.isNotEmpty) return t;
    final line = content.trim().split('\n').first;
    if (line.length <= 40) return line;
    return '${line.substring(0, 40)}…';
  }
}
