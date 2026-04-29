import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';

class MaterialChaptersScreen extends StatelessWidget {
  const MaterialChaptersScreen({
    super.key,
    required this.subject,
  });

  final String subject;

  static const List<String> chapters = [
    'chapter-1',
    'chapter-2',
    'chapter-3',
    'chapter-4',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$subject Chapters'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: chapters.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final chapter = chapters[index];

          return Card(
            child: ListTile(
              title: Text(chapter),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/student/materials/$subject/$chapter');
              },
            ),
          );
        },
      ),
    );
  }
}
