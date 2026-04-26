class ChapterModel {
  final String id;
  final String subjectId;
  final String name;
  final int? chapterNo;
  final DateTime? createdAt;

  const ChapterModel({
    required this.id,
    required this.subjectId,
    required this.name,
    this.chapterNo,
    this.createdAt,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      id: json['id'] as String,
      subjectId: json['subject_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      chapterNo: json['chapter_no'] as int?,
      createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'name': name,
      if (chapterNo != null) 'chapter_no': chapterNo,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
