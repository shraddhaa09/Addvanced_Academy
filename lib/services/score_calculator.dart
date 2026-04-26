// lib/features/tests/services/score_service.dart

import '../models/test_attempt_model.dart';
import '../models/test_result_model.dart';

class ScoreService {
  /// ─────────────────────────────────────────────────────────
  /// CALCULATE RESULT FROM ATTEMPT
  /// ─────────────────────────────────────────────────────────
  TestResultModel calculateResult(TestAttemptModel attempt) {
    attempt.submitTest();

    return TestResultModel.fromAttempt(attempt);
  }

  /// ─────────────────────────────────────────────────────────
  /// SUBJECT-WISE BREAKDOWN (SCHEMA SUPPORT)
  /// ─────────────────────────────────────────────────────────
  Map<String, SubjectScore> calculateSubjectWise(
    TestAttemptModel attempt,
  ) {
    final Map<String, SubjectScore> subjectScores = {};

    for (final q in attempt.questions) {
      // extract subject from question text (mock logic)
      final subject = _extractSubject(q.question);

      subjectScores.putIfAbsent(
        subject,
        () => SubjectScore(subject: subject),
      );

      final data = subjectScores[subject]!;

      if (q.isCorrect) {
        data.correct++;
      } else if (q.isWrong) {
        data.wrong++;
      } else {
        data.unattempted++;
      }
    }

    return subjectScores;
  }

  /// ─────────────────────────────────────────────────────────
  /// PERFORMANCE LABEL (SCHEMA)
  /// ─────────────────────────────────────────────────────────
  String getPerformanceLabel(double percentage) {
    if (percentage >= 80) return 'Excellent';
    if (percentage >= 60) return 'Good';
    if (percentage >= 40) return 'Average';
    return 'Needs Improvement';
  }

  /// ─────────────────────────────────────────────────────────
  /// HELPERS
  /// ─────────────────────────────────────────────────────────
  String _extractSubject(String questionText) {
    if (questionText.contains('Physics')) return 'Physics';
    if (questionText.contains('Chemistry')) return 'Chemistry';
    if (questionText.contains('Mathematics')) return 'Mathematics';
    if (questionText.contains('Biology')) return 'Biology';
    return 'General';
  }
}

/// ─────────────────────────────────────────────────────────
/// SUBJECT SCORE MODEL
/// ─────────────────────────────────────────────────────────
class SubjectScore {
  final String subject;

  int correct = 0;
  int wrong = 0;
  int unattempted = 0;

  SubjectScore({
    required this.subject,
  });

  int get total => correct + wrong + unattempted;

  int get score => correct; // +1 marking scheme

  double get accuracy {
    final attempted = correct + wrong;
    if (attempted == 0) return 0;
    return (correct / attempted) * 100;
  }
}