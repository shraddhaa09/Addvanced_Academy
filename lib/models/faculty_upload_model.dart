class FacultyUploadModel {
  final String contentType;
  final String id;
  final String facultyId;
  final String facultyName;
  final String subject;
  final String chapter;
  final String title;
  final String description;
  final String storagePath; 
  final DateTime? uploadedAt;
  final bool isVisible;

  const FacultyUploadModel({
    required this.contentType,
    required this.id,
    required this.facultyId,
    required this.facultyName,
    required this.subject,
    required this.chapter,
    required this.title,
    this.description = '',
    required this.storagePath,
    this.uploadedAt,
    required this.isVisible,
  });

  factory FacultyUploadModel.fromJson(Map<String, dynamic> json) {
    return FacultyUploadModel(
      contentType: json['content_type'] as String? ?? '',
      id: json['id'] as String? ?? '',
      facultyId: json['faculty_id'] as String? ?? '',
      facultyName: json['faculty_name'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      chapter: json['chapter'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      storagePath: json['storage_path'] as String? ?? '', // ✅ Added
      uploadedAt: json['uploaded_at'] == null ? null : DateTime.tryParse(json['uploaded_at'].toString()),
      isVisible: json['is_visible'] as bool? ?? true,
    );
  }
}
