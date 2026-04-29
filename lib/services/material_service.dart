import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/errors/app_exceptions.dart';
import '../models/study_material_model.dart';

class MaterialService {
  MaterialService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _bucketName = 'study-materials';
  static const String _tableName = 'study_materials';

  Future<String> uploadMaterialFile({
    required dynamic file, // Uint8List or io.File
    required String fileName,
    required String facultyId,
    required String subjectId,
    required String chapterId,
  }) async {
    final path =
        'materials/$facultyId/$subjectId/$chapterId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    try {
      if (file is Uint8List) {
        await _client.storage.from('study-materials').uploadBinary(
          path,
          file,
          fileOptions: const FileOptions(upsert: false),
        );
      } else if (file is io.File) {
        await _client.storage.from('study-materials').upload(
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

  Future<StudyMaterialModel> createStudyMaterial({
    required String facultyId,
    required String subjectId,
    required String chapterId,
    required String title,
    required String storagePath,
    String? description,
    required String materialType,
    int? fileSizeKb,
    required bool isVisible,
  }) async {
    // Deduplication check
    try {
      final existing = await _client
          .from(_tableName)
          .select('id')
          .eq('faculty_id', facultyId)
          .eq('subject_id', subjectId)
          .eq('chapter_id', chapterId)
          .ilike('title', title.trim())
          .maybeSingle();

      if (existing != null) {
        throw DuplicateUploadException('A material with this title already exists in this chapter.');
      }
    } catch (_) {}

    final response = await _client.from(_tableName).insert({
      'faculty_id': facultyId,
      'subject_id': subjectId,
      'chapter_id': chapterId,
      'title': title.trim(),
      'description': description,
      'storage_path': storagePath,
      'material_type': materialType,
      'file_size_kb': fileSizeKb,
    };

    try {
      final response = await _client
          .schema('academy')
          .from('study_materials')
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
    required String materialId,
    required String studentId,
  }) async {
    try {
      await _client.schema('academy').from('content_views').insert({
        'content_id': materialId,
        'content_type': 'material',
        'student_id': studentId,
      });
    } catch (e) {
      // Silently fail as view recording shouldn't block the user
      debugPrint('Error recording material view: $e');
    }
  }
}