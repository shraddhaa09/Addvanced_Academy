import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';

class TestConfirmationScreen extends StatelessWidget {
  const TestConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;

    final String testType = extra?['test_type'] ?? 'full';
    final String? chapter = extra?['selected_chapter'];

    final int duration = testType == 'full' ? 180 : 60;
    final int questions = testType == 'full' ? 90 : 30;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Confirmation'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ready to Start?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            Text(
              testType == 'full'
                  ? 'Full Length Test (PCM/PCB)'
                  : 'Subjective Test',
              style: const TextStyle(fontSize: 16),
            ),

            if (chapter != null) ...[
              const SizedBox(height: 6),
              Text(
                'Chapter: $chapter',
                style: const TextStyle(fontSize: 14),
              ),
            ],

            const SizedBox(height: 20),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow('Duration', '$duration mins'),
                    _infoRow('Questions', '$questions'),
                    _infoRow('Marks', '${questions * 1}'),
                    _infoRow('Negative Marking', 'No'),
                  ],
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.push(
                    RouteConstants.testEngine,
                    extra: {
                      'test_type': testType,
                      'chapter': chapter,
                    },
                  );
                },
                child: const Text('Start Test'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}