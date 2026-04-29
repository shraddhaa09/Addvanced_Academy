import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/faculty_providers.dart';
import '../../../../core/widgets/action_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_widgets.dart';

class VideoSubjectsScreen extends ConsumerWidget {
  const VideoSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Video Lectures',
          style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: const Color(0xFFEEEEEE)),
        ),
      ),
      body: subjectsAsync.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return const Center(
              child: AppEmptyState(
                title: 'No subjects found',
                message: 'Stay tuned! Video lectures will be available soon.',
                icon: Icons.video_library_rounded,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final subject = subjects[index];

              return ActionCard(
                title: subject.name,
                subtitle: 'Watch recorded classes & tutorials',
                icon: Icons.play_circle_fill_rounded,
                accentColor: const Color(0xFF5B4FCF),
                iconBackground: const Color(0xFFEEECFD),
                onTap: () {
                  context.push('/student/videos/list/${subject.name}');
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
