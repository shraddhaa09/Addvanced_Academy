import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../providers/student_providers.dart';
import '../../../../models/video_lecture_model.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/widgets/hero_banner.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_widgets.dart';

class VideoListScreen extends ConsumerWidget {
  const VideoListScreen({
    super.key,
    required this.subject,
  });

  final String subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(studentVideosProvider(subject));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          '$subject Lectures',
          style: const TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: HeroBanner(
              title: '$subject Lectures',
              subtitle: 'Watch recorded classes and tutorials',
              tag: 'Video Lectures',
              gradientColors: const [Color(0xFF5B4FCF), Color(0xFF7C6FE0)],
              backgroundIcon: Icons.play_circle_fill_rounded,
            ),
          ),
          Expanded(
            child: videosAsync.when(
              data: (videos) {
                if (videos.isEmpty) {
                  return const Center(
                    child: AppEmptyState(
                      title: 'No videos found',
                      message: 'Check back later for recorded lecture sessions.',
                      icon: Icons.video_library_rounded,
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: videos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return _VideoCard(video: video);
                  },
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: 5,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: ShimmerBox(width: double.infinity, height: 80, borderRadius: 14),
                ),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final VideoLectureModel video;
  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          context.push(
            '${RouteConstants.videoSubjects}/player',
            extra: video,
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF0F0F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B4FCF).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF5B4FCF), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.description ?? 'Video lecture',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFD1D5DB)),
            ],
          ),
        ),
      ),
    );
  }
}

