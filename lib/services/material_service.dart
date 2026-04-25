import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class MaterialService {
  final SupabaseClient _client;
  MaterialService(this._client);

  Future<String> uploadMaterialFile({
    required File file,
    required String facultyId,
    required String subjectId,
    required String chapterId,
  }) async {
    final fileName = file.path.split('/').last;
    final path =
        'materials/$facultyId/$subjectId/$chapterId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _client.storage.from('study-materials').upload(path, file);
    return path;
  }

  Future<Map<String, dynamic>> createStudyMaterial({
    required String facultyId,
    required String subjectId,
    required String chapterId,
    required String title,
    required String storagePath,
    String? description,
    required String materialType,
    required bool isVisible,
    int? fileSizeKb,
  }) async {
    final payload = {
      'faculty_id': facultyId,
      'subject_id': subjectId,
      'chapter_id': chapterId,
      'title': title,
      'storage_path': storagePath,
      'description': description,
      'material_type': materialType,
      'is_visible': isVisible,
      'file_size_kb': fileSizeKb,
    };

    final response =
    await _client.from('study_materials').insert(payload).select().single();

    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<Map<String, dynamic>>> fetchRecentMaterials(String facultyId) async {
    final response = await _client
        .from('v_faculty_uploads')
        .select()
        .eq('faculty_id', facultyId)
        .order('uploaded_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }
}