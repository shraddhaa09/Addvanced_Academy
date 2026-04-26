// lib/features/tests/models/test_attempt_model.dart

import 'question_model.dart';

class TestAttemptModel {
  final String testId;
  final String testType; // full | subjective
  final List<QuestionModel> questions;

  final int totalQuestions;
  final int totalMarks;
  final int durationMinutes;

  int currentIndex;

  DateTime startTime;
  DateTime? endTime;

  TestAttemptModel({
    required this.testId,
    required this.testType,
    required this.questions,
    required this.totalQuestions,
    required this.totalMarks,
    required this.durationMinutes,
    this.currentIndex = 0,
  }) : startTime = DateTime.now();

  /// ── NAVIGATION ───────────────────────────────────────────

  void goToQuestion(int index) {
    if (index >= 0 && index < questions.length) {
      currentIndex = index;
    }
  }

  void nextQuestion() {
    if (currentIndex < questions.length - 1) {
      currentIndex++;
    }
  }

  void previousQuestion() {
    if (currentIndex > 0) {
      currentIndex--;
    }
  }

  QuestionModel get currentQuestion => questions[currentIndex];

  /// ── ANSWER ACTIONS ───────────────────────────────────────

  void selectAnswer(int index) {
    questions[currentIndex].selectAnswer(index);
  }

  void clearAnswer() {
    questions[currentIndex].clearAnswer();
  }

  void toggleMarkForReview() {
    questions[currentIndex].toggleMarkForReview();
  }

  /// ── TEST COMPLETION ──────────────────────────────────────

  void submitTest() {
    endTime = DateTime.now();
  }

  bool get isCompleted => endTime != null;

  Duration get timeTaken =>
      (endTime ?? DateTime.now()).difference(startTime);

  /// ── RESULT CALCULATION ───────────────────────────────────

  int get correctCount =>
      questions.where((q) => q.isCorrect).length;

  int get wrongCount =>
      questions.where((q) => q.isWrong).length;

  int get unattemptedCount =>
      questions.where((q) => !q.isAttempted).length;

  int get score {
    // schema: +1 for correct, 0 for wrong (no negative marking)
    return correctCount * 1;
  }

  double get accuracy {
    final attempted = correctCount + wrongCount;
    if (attempted == 0) return 0;
    return (correctCount / attempted) * 100;
  }

  /// ── PALETTE COUNTS ───────────────────────────────────────

  int get answeredCount =>
      questions.where((q) => q.isAttempted).length;

  int get markedCount =>
      questions.where((q) => q.isMarkedForReview).length;

  /// ── PROGRESS ─────────────────────────────────────────────

  double get progress {
    if (questions.isEmpty) return 0;
    return answeredCount / questions.length;
  }
}