// lib/features/tests/services/attempt_service.dart

import '../models/question_model.dart';
import '../models/test_attempt_model.dart';
import '../models/test_result_model.dart';

class AttemptService {
  /// ─────────────────────────────────────────────────────────
  /// CREATE TEST ATTEMPT (MOCK / API READY)
  /// ─────────────────────────────────────────────────────────
  Future<TestAttemptModel> createAttempt({
    required String testType, // full | subject
    String? chapter,
  }) async {
    // simulate API delay
    await Future.delayed(const Duration(milliseconds: 400));

    final int questionCount = testType == 'full' ? 90 : 30;
    final int duration = testType == 'full' ? 180 : 60;

    final questions = List.generate(
      questionCount,
      (index) => QuestionModel(
        id: 'q_$index',
        question: _generateQuestionText(index, chapter),
        options: const [
          'Option A',
          'Option B',
          'Option C',
          'Option D',
        ],
        correctIndex: index % 4,
      ),
    );

    return TestAttemptModel(
      testId: DateTime.now().millisecondsSinceEpoch.toString(),
      testType: testType,
      questions: questions,
      totalQuestions: questionCount,
      totalMarks: questionCount,
      durationMinutes: duration,
    );
  }

  /// ─────────────────────────────────────────────────────────
  /// SUBMIT TEST ATTEMPT
  /// ─────────────────────────────────────────────────────────
  Future<TestResultModel> submitAttempt(
    TestAttemptModel attempt,
  ) async {
    // simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));

    attempt.submitTest();

    return TestResultModel.fromAttempt(attempt);
  }

  /// ─────────────────────────────────────────────────────────
  /// HELPERS
  /// ─────────────────────────────────────────────────────────
  String _generateQuestionText(int index, String? chapter) {
    if (chapter != null) {
      return '[$chapter] Question ${index + 1}';
    }
    return 'Question ${index + 1}';
  }
}