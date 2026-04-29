class StudentModel {
  final String id;
  final String name;
  final String mobile;
  final String batch;
  final String? rollNo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudentModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.batch,
    this.rollNo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      batch: json['batch'] as String? ?? '',
      rollNo: json['roll_no'] as String?,
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'batch': batch,
      'roll_no': rollNo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  StudentModel copyWith({
    String? name,
    String? mobile,
    String? batch,
    String? rollNo,
  }) {
    return StudentModel(
      id: id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      batch: batch ?? this.batch,
      rollNo: rollNo ?? this.rollNo,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
