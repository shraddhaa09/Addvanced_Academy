class VideoLectureModel {
  final String? id;
  final String facultyId;
  final String subject;
  final String title;
  final String videoUrl;
  final DateTime? uploadedAt;
  final String? description;
  final String? chapter;
  final bool visibleToStudents;
  final String? duration;

  const VideoLectureModel({
    this.id,
    required this.facultyId,
    required this.subject,
    required this.title,
    required this.videoUrl,
    this.uploadedAt,
    this.description,
    this.chapter,
    this.visibleToStudents = true,
    this.duration,
  });

  factory VideoLectureModel.fromJson(Map<String, dynamic> json) {
    return VideoLectureModel(
      id: json['id'] as String?,
      facultyId: json['faculty_id'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      title: json['title'] as String? ?? '',
      videoUrl: json['video_url'] as String? ?? '',
      uploadedAt: json['uploaded_at'] == null ? null : DateTime.tryParse(json['uploaded_at'].toString()),
      description: json['description'] as String?,
      chapter: json['chapter'] as String?,
      visibleToStudents: json['visible_to_students'] as bool? ?? true,
      duration: json['duration'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'faculty_id': facultyId,
      'subject': subject,
      'title': title,
      'video_url': videoUrl,
      if (uploadedAt != null) 'uploaded_at': uploadedAt!.toIso8601String(),
      if (description != null) 'description': description,
      if (chapter != null) 'chapter': chapter,
      'visible_to_students': visibleToStudents,
      if (duration != null) 'duration': duration,
    };
  }
}