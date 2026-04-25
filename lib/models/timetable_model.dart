class TimetableModel {
  final String id;
  final String facultyId;
  final String subjectId;
  final String subjectName;
  final String startTime;
  final String endTime;
  final String dayOfWeek;
  final String? room;
  final String type;

  const TimetableModel({
    required this.id,
    required this.facultyId,
    required this.subjectId,
    required this.subjectName,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
    this.room,
    required this.type,
  });

  factory TimetableModel.fromJson(Map<String, dynamic> json) {
    return TimetableModel(
      id: json['id'] as String,
      facultyId: json['faculty_id'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      dayOfWeek: json['day_of_week'] as String? ?? '',
      room: json['room'] as String?,
      type: json['type'] as String? ?? 'Lecture',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'faculty_id': facultyId,
      'subject_id': subjectId,
      'subject_name': subjectName,
      'start_time': startTime,
      'end_time': endTime,
      'day_of_week': dayOfWeek,
      'room': room,
      'type': type,
    };
  }
}
