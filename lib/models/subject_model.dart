class SubjectModel {
  final String id;
  final String name;
  final String label;
  final DateTime? createdAt;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.label,
    this.createdAt,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      label: json['label'] as String? ?? '',
      createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'label': label,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
