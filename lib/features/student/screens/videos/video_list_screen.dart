import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../models/video_lecture_model.dart';
import '../../../../services/video_service.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({
    super.key,
    required this.subject,
  });

  final String subject;

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  late final VideoService _videoService;
  late Future<List<VideoLectureModel>> _videosFuture;

  @override
  void initState() {
    super.initState();
    _videoService = VideoService();
    _videosFuture = _videoService.fetchVideosBySubject(widget.subject);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subject} Videos'),
      ),
      body: FutureBuilder<List<VideoLectureModel>>(
        future: _videosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading videos: ${snapshot.error}'),
            );
          }

          final videos = snapshot.data ?? [];

          if (videos.isEmpty) {
            return const Center(
              child: Text('No videos available for this subject.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final video = videos[index];

              return Card(
                child: ListTile(
                  title: Text(video.title),
                  subtitle: Text(
                    video.description?.isNotEmpty == true
                        ? video.description!
                        : 'Uploaded on ${video.uploadedAt.toLocal()}',
                  ),
                  trailing: const Icon(Icons.play_circle_fill),
                  onTap: () {
                    context.push(
                      RouteConstants.videoPlayer,
                      extra: video,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
