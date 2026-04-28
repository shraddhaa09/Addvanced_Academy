class AnnouncementModel {
  final String id;
  final String facultyId;
  final String title;
  final String message;
  final String targetBatch;
  final String? subject;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const AnnouncementModel({
    required this.id,
    required this.facultyId,
    required this.title,
    required this.message,
    required this.targetBatch,
    this.subject,
    required this.createdAt,
    this.expiresAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      facultyId: json['faculty_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      targetBatch: json['target_batch'] as String,
      subject: json['subject'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'faculty_id': facultyId,
      'title': title,
      'message': message,
      'target_batch': targetBatch,
      'subject': subject,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
