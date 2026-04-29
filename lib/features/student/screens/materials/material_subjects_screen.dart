import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class MaterialSubjectsScreen extends StatelessWidget {
  const MaterialSubjectsScreen({super.key});

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
        title: const Text('Study Material'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: subjects.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final subject = subjects[index];

          return Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(subject),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/student/materials/$subject/chapters');
              },
            ),
          );
        },
      ),
    );
  }
}
