import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../models/video_lecture_model.dart';
import '../../../../services/video_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    required this.video,
  });

  final VideoLectureModel video;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final VideoService _videoService = VideoService();

  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      final videoUrl = _videoService.getPublicUrl(widget.video.storagePath);

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _controller = controller;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load video: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.video.title),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _errorMessage != null
            ? Text(_errorMessage!)
            : controller == null
            ? const Text('Video unavailable.')
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
            const SizedBox(height: 16),
            IconButton(
              iconSize: 48,
              onPressed: () {
                setState(() {
                  if (controller.value.isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }
                });
              },
              icon: Icon(
                controller.value.isPlaying
                    ? Icons.pause_circle
                    : Icons.play_circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
