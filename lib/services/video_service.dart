import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class VideoService {
  final SupabaseClient _client;
  VideoService(this._client);

  Future<String> uploadVideoFile({
    required File file,
    required String facultyId,
    required String subjectId,
    required String chapterId,
  }) async {
    final fileName = file.path.split('/').last;
    final path = 'videos/$facultyId/$subjectId/$chapterId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('video-lectures').upload(path, file);
    return path;
  }

  Future<Map<String, dynamic>> createVideoLecture({
    required String facultyId,
    required String subjectId,
    required String chapterId,
    required String title,
    required String storagePath,
    String? description,
    required bool isVisible,
    int? fileSizeKb,
    String? duration,
  }) async {
    final payload = {
      'faculty_id': facultyId,
      'subject_id': subjectId,
      'chapter_id': chapterId,
      'title': title,
      'storage_path': storagePath,
      'description': description,
      'is_visible': isVisible,
      'file_size_kb': fileSizeKb,
      'duration': duration,
    };

    final response = await _client.from('video_lectures').insert(payload).select().single();
    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<Map<String, dynamic>>> fetchRecentUploads(String facultyId) async {
    final response = await _client
        .from('v_faculty_uploads')
        .select()
        .eq('faculty_id', facultyId)
        .order('uploaded_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }
}