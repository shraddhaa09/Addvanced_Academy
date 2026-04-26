// lib/features/tests/models/test_model.dart

class TestModel {
  final String id;

  /// Schema:
  /// full_pcm | full_pcb | subject
  final String testType;

  final String title;
  final String description;

  final int totalQuestions;
  final int durationMinutes;
  final int totalMarks;

  /// Optional (for subjective test)
  final String? subject;
  final String? chapter;

  /// Metadata
  final DateTime createdAt;
  final bool isAssigned;
  final bool isCompleted;

  TestModel({
    required this.id,
    required this.testType,
    required this.title,
    required this.description,
    required this.totalQuestions,
    required this.durationMinutes,
    required this.totalMarks,
    this.subject,
    this.chapter,
    this.isAssigned = false,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// ── FACTORY HELPERS (Schema Presets) ─────────────────────

  factory TestModel.fullPCM({
    required String id,
  }) {
    return TestModel(
      id: id,
      testType: 'full_pcm',
      title: 'Full Test (PCM)',
      description: 'Physics, Chemistry, Mathematics full syllabus test',
      totalQuestions: 90,
      durationMinutes: 180,
      totalMarks: 90,
    );
  }

  factory TestModel.fullPCB({
    required String id,
  }) {
    return TestModel(
      id: id,
      testType: 'full_pcb',
      title: 'Full Test (PCB)',
      description: 'Physics, Chemistry, Biology full syllabus test',
      totalQuestions: 90,
      durationMinutes: 180,
      totalMarks: 90,
    );
  }

  factory TestModel.subjective({
    required String id,
    required String subject,
    required String chapter,
  }) {
    return TestModel(
      id: id,
      testType: 'subject',
      title: '$subject - $chapter',
      description: 'Chapter-wise practice test',
      totalQuestions: 30,
      durationMinutes: 60,
      totalMarks: 30,
      subject: subject,
      chapter: chapter,
    );
  }

  /// ── GETTERS (Schema Logic) ───────────────────────────────

  bool get isFullTest =>
      testType == 'full_pcm' || testType == 'full_pcb';

  bool get isSubjective => testType == 'subject';

  String get displayType {
    switch (testType) {
      case 'full_pcm':
        return 'Full Test (PCM)';
      case 'full_pcb':
        return 'Full Test (PCB)';
      case 'subject':
        return 'Subject Test';
      default:
        return 'Test';
    }
  }

  String get durationLabel => '$durationMinutes mins';

  String get questionLabel => '$totalQuestions Questions';
}