import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class VideoService {
  final SupabaseClient _client;
  VideoService(this._client);

  Future<String> uploadVideoFile({
    required String fileName,
    required dynamic file, // File (io) or Uint8List
    required String facultyId,
    required String subjectId,
    required String chapterId,
  }) async {
    final path = 'videos/$facultyId/$subjectId/$chapterId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    try {
      await _client.storage.from('video-lectures').upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: false),
      );
      return path;
    } on StorageException catch (e) {
      throw Exception('Storage upload failed: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected upload error: $e');
    }
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
    int? durationSec,
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
      'duration_sec': durationSec,
    };

    try {
      final response = await _client
          .schema('academy')
          .from('video_lectures')
          .insert(payload)
          .select()
          .single();

      return Map<String, dynamic>.from(response as Map);
    } on PostgrestException catch (e) {
      throw Exception('Database Error: ${e.message} (Code: ${e.code})');
    } catch (e) {
      throw Exception('Unexpected Database Error: $e');
    }
  }
}