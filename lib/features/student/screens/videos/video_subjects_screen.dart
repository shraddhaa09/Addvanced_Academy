import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VideoSubjectsScreen extends StatelessWidget {
  const VideoSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const subjects = [
      'Physics',
      'Chemistry',
      'Maths',
      'Biology',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Lectures'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: subjects.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final subject = subjects[index];

          return Card(
            child: ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: Text(subject),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/student/videos/$subject');
              },
            ),
          );
        },
      ),
    );
  }
}
