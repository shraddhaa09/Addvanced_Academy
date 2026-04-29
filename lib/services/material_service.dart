import 'dart:typed_data';
import 'dart:io' as io;
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
    required Object file,
    required String fileName,
    required String facultyId,
    required String subjectId,
    required String chapterId,
  }) async {
    final storagePath = _buildStoragePath(
      subjectId: subjectId,
      chapterId: chapterId,
      facultyId: facultyId,
      fileName: fileName,
    );

    try {
      if (file is Uint8List) {
        await _client.storage.from(_bucketName).uploadBinary(
              storagePath,
              file,
              fileOptions: const FileOptions(upsert: false),
            );
      } else if (file is io.File) {
        await _client.storage.from(_bucketName).upload(
              storagePath,
              file,
              fileOptions: const FileOptions(upsert: false),
            );
      } else {
        throw Exception('Unsupported file type');
      }
      return storagePath;
    } on StorageException catch (e) {
      throw Exception('Storage upload failed: ${e.message}');
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
      'is_visible': isVisible,
    }).select().single();

    return StudyMaterialModel.fromJson(response);
  }

  Future<List<StudyMaterialModel>> fetchMaterialsBySubjectAndChapter({
    required String subjectId,
    required String chapterId,
  }) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('subject_id', subjectId)
        .eq('chapter_id', chapterId)
        .eq('is_visible', true)
        .order('uploaded_at', ascending: false);

    return (response as List)
        .map((item) => StudyMaterialModel.fromJson(item))
        .toList();
  }

  String getPublicUrl(String storagePath) {
    return _client.storage.from(_bucketName).getPublicUrl(storagePath);
  }

  String _buildStoragePath({
    required String subjectId,
    required String chapterId,
    required String facultyId,
    required String fileName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeFileName = fileName.trim().replaceAll(RegExp(r'\s+'), '_');
    return '$subjectId/$chapterId/${facultyId}_$timestamp\_$safeFileName';
  }
}
