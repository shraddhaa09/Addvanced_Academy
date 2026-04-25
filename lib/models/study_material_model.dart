class StudyMaterialModel {
  final String? id;
  final String facultyId;
  final String subject;
  final String chapter;
  final String title;
  final String fileUrl;
  final DateTime? uploadedAt;
  final String? description;
  final String? materialType;
  final bool visibleToStudents;
  final String? fileSize;

  const StudyMaterialModel({
    this.id,
    required this.facultyId,
    required this.subject,
    required this.chapter,
    required this.title,
    required this.fileUrl,
    this.uploadedAt,
    this.description,
    this.materialType,
    this.visibleToStudents = true,
    this.fileSize,
  });

  factory StudyMaterialModel.fromJson(Map<String, dynamic> json) {
    return StudyMaterialModel(
      id: json['id'] as String?,
      facultyId: json['faculty_id'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      chapter: json['chapter'] as String? ?? '',
      title: json['title'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? '',
      uploadedAt: json['uploaded_at'] == null ? null : DateTime.tryParse(json['uploaded_at'].toString()),
      description: json['description'] as String?,
      materialType: json['material_type'] as String?,
      visibleToStudents: json['visible_to_students'] as bool? ?? true,
      fileSize: json['file_size'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'faculty_id': facultyId,
      'subject': subject,
      'chapter': chapter,
      'title': title,
      'file_url': fileUrl,
      if (uploadedAt != null) 'uploaded_at': uploadedAt!.toIso8601String(),
      if (description != null) 'description': description,
      if (materialType != null) 'material_type': materialType,
      'visible_to_students': visibleToStudents,
      if (fileSize != null) 'file_size': fileSize,
    };
  }
}