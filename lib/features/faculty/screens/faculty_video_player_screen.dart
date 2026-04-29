import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../../models/faculty_upload_model.dart';

class FacultyVideoPlayerScreen extends StatefulWidget {
  final FacultyUploadModel upload;
  const FacultyVideoPlayerScreen({super.key, required this.upload});

  @override
  State<FacultyVideoPlayerScreen> createState() => _FacultyVideoPlayerScreenState();
}

class _FacultyVideoPlayerScreenState extends State<FacultyVideoPlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final url = Supabase.instance.client.storage
          .from('video-lectures')
          .getPublicUrl(widget.upload.storagePath);

      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF5B4FCF),
          handleColor: const Color(0xFF5B4FCF),
        ),
        placeholder: Container(color: Colors.black),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.upload.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.upload.subject,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : _error != null
                ? Text('Error loading video: $_error', style: const TextStyle(color: Colors.white))
                : Chewie(controller: _chewieController!),
      ),
    );
  }
}
