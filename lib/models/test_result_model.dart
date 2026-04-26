// lib/features/tests/models/test_result_model.dart

import 'test_attempt_model.dart';

class TestResultModel {
  final String testId;
  final String testType;

  final int totalQuestions;
  final int totalMarks;

  final int correctAnswers;
  final int wrongAnswers;
  final int unattempted;

  final int score;
  final double accuracy;

  final Duration timeTaken;

  final DateTime submittedAt;

  TestResultModel({
    required this.testId,
    required this.testType,
    required this.totalQuestions,
    required this.totalMarks,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.unattempted,
    required this.score,
    required this.accuracy,
    required this.timeTaken,
    required this.submittedAt,
  });

  /// ── FACTORY FROM ATTEMPT (STRICT SCHEMA) ─────────────────
  factory TestResultModel.fromAttempt(TestAttemptModel attempt) {
    return TestResultModel(
      testId: attempt.testId,
      testType: attempt.testType,
      totalQuestions: attempt.totalQuestions,
      totalMarks: attempt.totalMarks,
      correctAnswers: attempt.correctCount,
      wrongAnswers: attempt.wrongCount,
      unattempted: attempt.unattemptedCount,
      score: attempt.score,
      accuracy: attempt.accuracy,
      timeTaken: attempt.timeTaken,
      submittedAt: DateTime.now(),
    );
  }

  /// ── PERFORMANCE HELPERS ──────────────────────────────────

  bool get isPassed {
    // schema rule: pass if >= 40%
    return percentage >= 40;
  }

  double get percentage {
    if (totalMarks == 0) return 0;
    return (score / totalMarks) * 100;
  }

  String get performanceLabel {
    if (percentage >= 80) return 'Excellent';
    if (percentage >= 60) return 'Good';
    if (percentage >= 40) return 'Average';
    return 'Needs Improvement';
  }

  /// ── TIME FORMAT ──────────────────────────────────────────

  String get formattedTime {
    final minutes = timeTaken.inMinutes;
    final seconds = timeTaken.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  /// ── SUMMARY (for UI cards) ───────────────────────────────

  String get summaryText {
    return 'Score: $score/$totalMarks • '
        'Accuracy: ${accuracy.toStringAsFixed(1)}%';
  }
}