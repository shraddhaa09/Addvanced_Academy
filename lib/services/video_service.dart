import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/video_lecture_model.dart';

class VideoService {
  final SupabaseClient _client;

  VideoService(this._client);

  Future<String> uploadVideoFile({
    required File file,
    required String subject,
    required String facultyId,
  }) async {
    final fileName = file.path.split('/').last;
    final path = '$subject/${facultyId}_${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _client.storage.from('video-lectures').upload(path, file);
    return _client.storage.from('video-lectures').getPublicUrl(path);
  }

  Future<VideoLectureModel> createVideoLecture({
    required String facultyId,
    required String subject,
    required String title,
    required String videoUrl,
    String? description,
    String? chapter,
    bool visibleToStudents = true,
    String? duration,
  }) async {
    final payload = {
      'faculty_id': facultyId,
      'subject': subject,
      'title': title,
      'video_url': videoUrl,
      'description': description,
      'chapter': chapter,
      'visible_to_students': visibleToStudents,
      'duration': duration,
    };

    final response = await _client.from('video_lectures').insert(payload).select().single();
    return VideoLectureModel.fromJson(response);
  }

  Future<List<VideoLectureModel>> fetchRecentUploads(String facultyId) async {
    final response = await _client
        .from('video_lectures')
        .select()
        .eq('faculty_id', facultyId)
        .order('uploaded_at', ascending: false);

    return (response as List)
        .map((item) => VideoLectureModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}