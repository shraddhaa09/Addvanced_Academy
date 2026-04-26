class FacultyModel {
  final String id;
  final String name;
  final String mobile;
  final String subject;
  final String? qualification;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FacultyModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.subject,
    this.qualification,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FacultyModel.fromJson(Map<String, dynamic> json) {
    return FacultyModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      qualification: json['qualification'] as String?,
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'subject': subject,
      'qualification': qualification,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FacultyModel copyWith({
    String? name,
    String? mobile,
    String? subject,
    String? qualification,
  }) {
    return FacultyModel(
      id: id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      subject: subject ?? this.subject,
      qualification: qualification ?? this.qualification,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
