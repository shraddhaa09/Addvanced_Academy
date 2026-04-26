// lib/features/tests/services/question_service.dart

import '../models/question_model.dart';

class QuestionService {
  /// ─────────────────────────────────────────────────────────
  /// FETCH QUESTIONS (MOCK / API READY)
  /// ─────────────────────────────────────────────────────────
  Future<List<QuestionModel>> fetchQuestions({
    required String testType, // full | subject
    String? subject,
    String? chapter,
  }) async {
    // simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));

    final int count = testType == 'full' ? 90 : 30;

    return List.generate(count, (index) {
      return QuestionModel(
        id: 'q_$index',
        question: _buildQuestionText(
          index: index,
          subject: subject,
          chapter: chapter,
        ),
        options: _generateOptions(index),
        correctIndex: index % 4,
      );
    });
  }

  /// ─────────────────────────────────────────────────────────
  /// HELPERS
  /// ─────────────────────────────────────────────────────────

  String _buildQuestionText({
    required int index,
    String? subject,
    String? chapter,
  }) {
    if (subject != null && chapter != null) {
      return '[$subject - $chapter] Question ${index + 1}';
    }
    if (subject != null) {
      return '[$subject] Question ${index + 1}';
    }
    return 'Question ${index + 1}';
  }

  List<String> _generateOptions(int index) {
    return [
      'Option A for Q${index + 1}',
      'Option B for Q${index + 1}',
      'Option C for Q${index + 1}',
      'Option D for Q${index + 1}',
    ];
  }
}