import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/faculty_providers.dart';
import '../../../../core/widgets/action_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_widgets.dart';

class MaterialChaptersScreen extends ConsumerWidget {
  const MaterialChaptersScreen({
    super.key,
    required this.subject, // This is now subjectId
  });

  final String subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(chaptersProvider(subject));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Select Chapter',
          style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      body: chaptersAsync.when(
        data: (chapters) {
          if (chapters.isEmpty) {
            return const Center(
              child: AppEmptyState(
                title: 'No chapters found',
                message: 'Stay tuned! Content will be added for this subject soon.',
                icon: Icons.auto_stories_rounded,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: chapters.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              return ActionCard(
                title: chapter.name,
                subtitle: 'View available notes and PDFs',
                icon: Icons.folder_open_rounded,
                accentColor: const Color(0xFF5B4FCF),
                iconBackground: const Color(0xFFEEECFD),
                onTap: () {
                  context.push('/student/materials/list/$subject/${chapter.id}');
                },
              );
            },
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: 6,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerBox(width: double.infinity, height: 72, borderRadius: 14),
          ),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
