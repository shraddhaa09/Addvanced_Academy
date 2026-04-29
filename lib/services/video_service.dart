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
    required Object file, // ✅ fixed type
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
      // Silently fail as view recording shouldn't block the user
      debugPrint('Error recording video view: $e');
    }
  }
}