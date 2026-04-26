import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';

class ChapterSelectionScreen extends StatelessWidget {
  const ChapterSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔹 You can later fetch from DB (chapters table)
    final List<String> chapters = [
      'Kinematics',
      'Laws of Motion',
      'Thermodynamics',
      'Electrostatics',
      'Current Electricity',
      'Magnetism',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Chapter'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: chapters.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final chapter = chapters[index];

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              title: Text(chapter),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                context.push(
                  RouteConstants.testConfirmation,
                  extra: {
                    'test_type': 'subject',
                    'selected_chapter': chapter,
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}