// lib/features/tests/providers/test_session_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/question_model.dart';
import '../models/test_attempt_model.dart';
import '../models/test_result_model.dart';

/// ─────────────────────────────────────────────────────────
/// STATE
/// ─────────────────────────────────────────────────────────
class TestSessionState {
  final TestAttemptModel? attempt;
  final TestResultModel? result;
  final bool isLoading;

  const TestSessionState({
    this.attempt,
    this.result,
    this.isLoading = false,
  });

  TestSessionState copyWith({
    TestAttemptModel? attempt,
    TestResultModel? result,
    bool? isLoading,
  }) {
    return TestSessionState(
      attempt: attempt ?? this.attempt,
      result: result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// PROVIDER
/// ─────────────────────────────────────────────────────────
final testSessionProvider =
    StateNotifierProvider<TestSessionNotifier, TestSessionState>(
  (ref) => TestSessionNotifier(),
);

/// ─────────────────────────────────────────────────────────
/// NOTIFIER
/// ─────────────────────────────────────────────────────────
class TestSessionNotifier extends StateNotifier<TestSessionState> {
  Timer? _timer;

  TestSessionNotifier() : super(const TestSessionState());

  /// ── START TEST (CREATE ATTEMPT) ─────────────────────────
  void startTest({
    required String testType,
    String? chapter,
  }) {
    state = state.copyWith(isLoading: true);

    // MOCK QUESTIONS (replace with API later)
    final questions = List.generate(
      testType == 'full' ? 90 : 30,
      (index) => QuestionModel(
        id: 'q$index',
        question: 'Sample Question ${index + 1}',
        options: const [
          'Option A',
          'Option B',
          'Option C',
          'Option D',
        ],
        correctIndex: index % 4,
      ),
    );

    final attempt = TestAttemptModel(
      testId: DateTime.now().millisecondsSinceEpoch.toString(),
      testType: testType,
      questions: questions,
      totalQuestions: questions.length,
      totalMarks: questions.length,
      durationMinutes: testType == 'full' ? 180 : 60,
    );

    state = TestSessionState(
      attempt: attempt,
      result: null,
      isLoading: false,
    );

    _startTimer(attempt.durationMinutes);
  }

  /// ── TIMER LOGIC ─────────────────────────────────────────
  void _startTimer(int minutes) {
    _timer?.cancel();

    final totalSeconds = minutes * 60;

    _timer = Timer(Duration(seconds: totalSeconds), () {
      submitTest();
    });
  }

  /// ── NAVIGATION ──────────────────────────────────────────
  void goToQuestion(int index) {
    final attempt = state.attempt;
    if (attempt == null) return;

    attempt.goToQuestion(index);
    state = state.copyWith(attempt: attempt);
  }

  void nextQuestion() {
    final attempt = state.attempt;
    if (attempt == null) return;

    attempt.nextQuestion();
    state = state.copyWith(attempt: attempt);
  }

  void previousQuestion() {
    final attempt = state.attempt;
    if (attempt == null) return;

    attempt.previousQuestion();
    state = state.copyWith(attempt: attempt);
  }

  /// ── ANSWERS ─────────────────────────────────────────────
  void selectAnswer(int index) {
    final attempt = state.attempt;
    if (attempt == null) return;

    attempt.selectAnswer(index);
    state = state.copyWith(attempt: attempt);
  }

  void clearAnswer() {
    final attempt = state.attempt;
    if (attempt == null) return;

    attempt.clearAnswer();
    state = state.copyWith(attempt: attempt);
  }

  void toggleMarkForReview() {
    final attempt = state.attempt;
    if (attempt == null) return;

    attempt.toggleMarkForReview();
    state = state.copyWith(attempt: attempt);
  }

  /// ── SUBMIT TEST ─────────────────────────────────────────
  void submitTest() {
    final attempt = state.attempt;
    if (attempt == null) return;

    _timer?.cancel();

    attempt.submitTest();

    final result = TestResultModel.fromAttempt(attempt);

    state = TestSessionState(
      attempt: attempt,
      result: result,
      isLoading: false,
    );
  }

  /// ── RESET SESSION ───────────────────────────────────────
  void reset() {
    _timer?.cancel();
    state = const TestSessionState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}