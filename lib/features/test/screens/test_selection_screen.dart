import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';

class TestSelectionScreen extends StatelessWidget {
  const TestSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Test'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose Your Test Type',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _TestCard(
            title: 'Full Test',
            description: 'PCM / PCB full syllabus test',
            duration: '180 mins',
            questions: 90,
            onTap: () {
              context.push(
                RouteConstants.testConfirmation,
                extra: {
                  'test_type': 'full',
                },
              );
            },
          ),

          const SizedBox(height: 16),

          _TestCard(
            title: 'Subjective Test',
            description: 'Select a subject and chapter',
            duration: '60 mins',
            questions: 30,
            onTap: () {
              context.push(RouteConstants.chapterSelection);
            },
          ),
        ],
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  final String title;
  final String description;
  final String duration;
  final int questions;
  final VoidCallback onTap;

  const _TestCard({
    required this.title,
    required this.description,
    required this.duration,
    required this.questions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(description),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(duration, style: const TextStyle(fontSize: 12)),
            Text('$questions Qs', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}