class VideoLectureModel {
  const VideoLectureModel({
    required this.id,
    required this.facultyId,
    required this.subjectId,
    required this.chapterId,
    required this.title,
    required this.storagePath,
    required this.isVisible,
    required this.uploadedAt,
    this.description,
    this.durationSec,
    this.fileSizeKb,
    this.updatedAt,
  });

  final String id;
  final String facultyId;
  final String subjectId;
  final String chapterId;
  final String title;
  final String storagePath;
  final bool isVisible;
  final DateTime uploadedAt;
  final String? description;
  final int? durationSec;
  final int? fileSizeKb;
  final DateTime? updatedAt;

  factory VideoLectureModel.fromJson(Map<String, dynamic> json) {
    return VideoLectureModel(
      id: json['id'] as String,
      facultyId: json['faculty_id'] as String,
      subjectId: json['subject_id'] as String,
      chapterId: json['chapter_id'] as String,
      title: json['title'] as String,
      storagePath: json['storage_path'] as String,
      isVisible: (json['is_visible'] as bool?) ?? true,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
      description: json['description'] as String?,
      durationSec: json['duration_sec'] as int?,
      fileSizeKb: json['file_size_kb'] as int?,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'faculty_id': facultyId,
      'subject_id': subjectId,
      'chapter_id': chapterId,
      'title': title,
      'description': description,
      'storage_path': storagePath,
      'duration_sec': durationSec,
      'file_size_kb': fileSizeKb,
      'is_visible': isVisible,
      'uploaded_at': uploadedAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  VideoLectureModel copyWith({
    String? id,
    String? facultyId,
    String? subjectId,
    String? chapterId,
    String? title,
    String? storagePath,
    bool? isVisible,
    DateTime? uploadedAt,
    String? description,
    int? durationSec,
    int? fileSizeKb,
    DateTime? updatedAt,
  }) {
    return VideoLectureModel(
      id: id ?? this.id,
      facultyId: facultyId ?? this.facultyId,
      subjectId: subjectId ?? this.subjectId,
      chapterId: chapterId ?? this.chapterId,
      title: title ?? this.title,
      storagePath: storagePath ?? this.storagePath,
      isVisible: isVisible ?? this.isVisible,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      description: description ?? this.description,
      durationSec: durationSec ?? this.durationSec,
      fileSizeKb: fileSizeKb ?? this.fileSizeKb,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
