// lib/features/tests/screens/answer_review_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AnswerReviewScreen extends StatelessWidget {
  const AnswerReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F3FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Answer Review',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _ScoreSummaryCard(),
          SizedBox(height: 18),

          _QuestionReviewCard(
            questionNo: 1,
            question:
                'What is the SI unit of Force?',
            options: [
              'Newton',
              'Pascal',
              'Joule',
              'Watt',
            ],
            selectedAnswer: 1,
            correctAnswer: 0,
          ),

          SizedBox(height: 16),

          _QuestionReviewCard(
            questionNo: 2,
            question:
                'Which law explains the relationship between pressure and volume?',
            options: [
              'Charles Law',
              'Boyle Law',
              'Newton Law',
              'Faraday Law',
            ],
            selectedAnswer: 2,
            correctAnswer: 1,
          ),

          SizedBox(height: 16),

          _QuestionReviewCard(
            questionNo: 3,
            question:
                'The acceleration due to gravity on Earth is approximately?',
            options: [
              '12.8 m/s²',
              '9.8 m/s²',
              '7.2 m/s²',
              '15 m/s²',
            ],
            selectedAnswer: 1,
            correctAnswer: 1,
          ),
        ],
      ),
    );
  }
}

class _ScoreSummaryCard extends StatelessWidget {
  const _ScoreSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6C5CE7),
            Color(0xFF8B7CF6),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Test Review',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '22 / 30 Correct',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Review every question with correct answers and your selected responses.',
            style: TextStyle(
              color: Colors.white,
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  final int questionNo;
  final String question;
  final List<String> options;
  final int selectedAnswer;
  final int correctAnswer;

  const _QuestionReviewCard({
    required this.questionNo,
    required this.question,
    required this.options,
    required this.selectedAnswer,
    required this.correctAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEECFD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Q$questionNo',
                  style: const TextStyle(
                    color: Color(0xFF6C5CE7),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                selectedAnswer == correctAnswer
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: selectedAnswer == correctAnswer
                    ? const Color(0xFF00B894)
                    : const Color(0xFFE74C3C),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF1A1A2E),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          ...List.generate(options.length, (index) {
            final isCorrect = index == correctAnswer;
            final isSelected = index == selectedAnswer;

            Color borderColor = Colors.grey.shade200;
            Color bgColor = Colors.white;

            if (isCorrect) {
              borderColor = const Color(0xFF00B894);
              bgColor = const Color(0xFFE9FBF6);
            } else if (isSelected && !isCorrect) {
              borderColor = const Color(0xFFE74C3C);
              bgColor = const Color(0xFFFFEEEE);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor,
                  width: 1.4,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      options[index],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A2E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isCorrect)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF00B894),
                      size: 20,
                    ),
                  if (isSelected && !isCorrect)
                    const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFE74C3C),
                      size: 20,
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}