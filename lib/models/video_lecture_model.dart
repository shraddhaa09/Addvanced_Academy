class VideoLectureModel {
  final String? id;
  final String facultyId;
  final String subjectId;
  final String chapterId;
  final String title;
  final String? description;
  final String storagePath;
  final int? durationSec;
  final int? fileSizeKb;
  final bool isVisible;
  final DateTime? uploadedAt;
  final DateTime? updatedAt;

  const VideoLectureModel({
    this.id,
    required this.facultyId,
    required this.subjectId,
    required this.chapterId,
    required this.title,
    this.description,
    required this.storagePath,
    this.durationSec,
    this.fileSizeKb,
    this.isVisible = true,
    this.uploadedAt,
    this.updatedAt,
  });

  factory VideoLectureModel.fromJson(Map<String, dynamic> json) {
    return VideoLectureModel(
      id: json['id'] as String?,
      facultyId: json['faculty_id'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? '',
      chapterId: json['chapter_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      storagePath: json['storage_path'] as String? ?? '',
      durationSec: json['duration_sec'] as int?,
      fileSizeKb: json['file_size_kb'] as int?,
      isVisible: json['is_visible'] as bool? ?? true,
      uploadedAt: json['uploaded_at'] == null ? null : DateTime.tryParse(json['uploaded_at'].toString()),
      updatedAt: json['updated_at'] == null ? null : DateTime.tryParse(json['updated_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'faculty_id': facultyId,
      'subject_id': subjectId,
      'chapter_id': chapterId,
      'title': title,
      if (description != null) 'description': description,
      'storage_path': storagePath,
      if (durationSec != null) 'duration_sec': durationSec,
      if (fileSizeKb != null) 'file_size_kb': fileSizeKb,
      'is_visible': isVisible,
      if (uploadedAt != null) 'uploaded_at': uploadedAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}