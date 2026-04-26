import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';

class TestEngineScreen extends StatefulWidget {
  const TestEngineScreen({super.key});

  @override
  State<TestEngineScreen> createState() => _TestEngineScreenState();
}

class _TestEngineScreenState extends State<TestEngineScreen> {
  late int totalQuestions;
  late int durationMinutes;

  int currentIndex = 0;
  List<int?> answers = [];

  Timer? timer;
  int remainingSeconds = 0;

  bool isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (isInitialized) return;

    final extra =
        GoRouterState.of(context).extra as Map<String, dynamic>?;

    final testType = extra?['test_type'] ?? 'full';

    totalQuestions = testType == 'full' ? 90 : 30;
    durationMinutes = testType == 'full' ? 180 : 60;

    answers = List.generate(totalQuestions, (_) => null);
    remainingSeconds = durationMinutes * 60;

    startTimer();

    isInitialized = true;
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds <= 0) {
        t.cancel();
        submitTest();
      } else {
        setState(() {
          remainingSeconds--;
        });
      }
    });
  }

  void submitTest() {
    timer?.cancel();

    int attempted = answers.where((e) => e != null).length;
    int correct = attempted ~/ 2;
    int score = correct;

    context.go(
      RouteConstants.result,
      extra: {
        'score': score,
        'total': totalQuestions,
        'attempted': attempted,
        'correct': correct,
      },
    );
  }

  String get formattedTime {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${currentIndex + 1}/$totalQuestions'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Text(
                formattedTime,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // QUESTION
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'This is Question ${currentIndex + 1}',
              style: const TextStyle(fontSize: 18),
            ),
          ),

          // OPTIONS
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, i) {
                return RadioListTile<int>(
                  value: i,
                  groupValue: answers[currentIndex],
                  title: Text('Option ${i + 1}'),
                  onChanged: (val) {
                    setState(() {
                      answers[currentIndex] = val;
                    });
                  },
                );
              },
            ),
          ),

          // NAVIGATION
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: currentIndex == 0
                      ? null
                      : () {
                          setState(() {
                            currentIndex--;
                          });
                        },
                  child: const Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: currentIndex == totalQuestions - 1
                      ? submitTest
                      : () {
                          setState(() {
                            currentIndex++;
                          });
                        },
                  child: Text(
                    currentIndex == totalQuestions - 1
                        ? 'Submit'
                        : 'Next',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}