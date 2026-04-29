import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/errors/app_exceptions.dart';
import '../models/video_lecture_model.dart';

class VideoService {
  VideoService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<String> uploadVideoFile({
    required String fileName,
    required Object file, 
    required String facultyId,
    required String subjectId,
    required String chapterId,
  }) async {
    final safeFileName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');

    final path =
        'videos/$facultyId/$subjectId/$chapterId/${DateTime.now().millisecondsSinceEpoch}_$safeFileName';

    try {
      if (file is Uint8List) {
        // Web
        await _client.storage
            .from('video-lectures')
            .uploadBinary(
          path,
          file,
          fileOptions: const FileOptions(upsert: false),
        );
      } else if (file is io.File) {
        // Mobile/Desktop
        await _client.storage
            .from('video-lectures')
            .upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: false),
        );
      } else {
        throw Exception('Unsupported file type: ${file.runtimeType}');
      }

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
    // 1. Deduplication Check
    try {
      final existing = await _client
          .schema('academy')
          .from('video_lectures')
          .select('id')
          .eq('faculty_id', facultyId)
          .eq('subject_id', subjectId)
          .ilike('title', title.trim())
          .maybeSingle();

      if (existing != null) {
        throw DuplicateUploadException('A video with this title already exists in this subject.');
      }
    } on PostgrestException catch (e) {
      debugPrint('Deduplication check failed: $e');
      // Continue if it's just a check failure, let the insert handle constraints
    }

    // 2. Insert
    final payload = {
      'faculty_id': facultyId,
      'subject_id': subjectId,
      'chapter_id': chapterId,
      'title': title.trim(),
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
      // Check for DB-level unique constraint violation (Code 23505)
      if (e.code == '23505') {
        throw DuplicateUploadException('A video with this title already exists in this subject.');
      }
      throw Exception('Database Error: ${e.message} (Code: ${e.code})');
    } catch (e) {
      if (e is DuplicateUploadException) rethrow;
      throw Exception('Unexpected Database Error: $e');
    }
  }

  Future<List<VideoLectureModel>> fetchVideosBySubject(String subjectName) async {
    try {
      final response = await _client
          .schema('academy')
          .from('video_lectures')
          .select()
          .eq('is_visible', true)
          // Since subject_id in table might be a UUID, we might need a join or filter by name if that's what's passed
          // But for now matching the existing screen logic which passes subject name
          .ilike('subject_id', '%$subjectName%') // Temporary hack if subjectId is being used as name
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => VideoLectureModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch videos: $e');
    }
  }

  String getPublicUrl(String storagePath) {
    return _client.storage.from('video-lectures').getPublicUrl(storagePath);
  }

  Future<void> recordView({
    required String videoId,
    required String studentId,
  }) async {
    try {
      await _client.schema('academy').from('content_views').insert({
        'content_id': videoId,
        'content_type': 'video',
        'student_id': studentId,
      });
    } catch (e) {
      debugPrint('Error recording video view: $e');
    }
  }
}