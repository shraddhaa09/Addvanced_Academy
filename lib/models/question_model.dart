// lib/features/tests/models/question_model.dart

class QuestionModel {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;

  /// userSelectedIndex:
  /// - null  -> not attempted
  /// - 0..3  -> selected option
  int? userSelectedIndex;

  /// isMarkedForReview:
  /// used in palette (mark for review feature)
  bool isMarkedForReview;

  QuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.userSelectedIndex,
    this.isMarkedForReview = false,
  });

  /// ── Helpers (Schema Logic) ───────────────────────────────

  bool get isAttempted => userSelectedIndex != null;

  bool get isCorrect =>
      userSelectedIndex != null && userSelectedIndex == correctIndex;

  bool get isWrong =>
      userSelectedIndex != null && userSelectedIndex != correctIndex;

  /// Status used in Question Palette
  QuestionStatus get status {
    if (isMarkedForReview && userSelectedIndex != null) {
      return QuestionStatus.answeredMarked;
    }
    if (isMarkedForReview) {
      return QuestionStatus.marked;
    }
    if (userSelectedIndex != null) {
      return QuestionStatus.answered;
    }
    return QuestionStatus.notVisited;
  }

  /// Reset answer (if needed)
  void clearAnswer() {
    userSelectedIndex = null;
  }

  /// Select answer
  void selectAnswer(int index) {
    userSelectedIndex = index;
  }

  /// Toggle mark for review
  void toggleMarkForReview() {
    isMarkedForReview = !isMarkedForReview;
  }
}

/// ── ENUM (Strict Schema for Palette & Engine) ───────────────
enum QuestionStatus {
  notVisited,
  answered,
  marked,
  answeredMarked,
}