import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/study_material_model.dart';

class MaterialService {
  final SupabaseClient _client;

  MaterialService(this._client);

  Future<String> uploadMaterialFile({
    required File file,
    required String subject,
    required String chapter,
    required String facultyId,
  }) async {
    final fileName = file.path.split('/').last;
    final path = '$subject/$chapter/${facultyId}_${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _client.storage.from('study-materials').upload(path, file);
    return _client.storage.from('study-materials').getPublicUrl(path);
  }

  Future<StudyMaterialModel> createStudyMaterial({
    required String facultyId,
    required String subject,
    required String chapter,
    required String title,
    required String fileUrl,
    String? description,
    String? materialType,
    bool visibleToStudents = true,
    String? fileSize,
  }) async {
    final payload = {
      'faculty_id': facultyId,
      'subject': subject,
      'chapter': chapter,
      'title': title,
      'file_url': fileUrl,
      'description': description,
      'material_type': materialType,
      'visible_to_students': visibleToStudents,
      'file_size': fileSize,
    };

    final response = await _client.from('study_materials').insert(payload).select().single();
    return StudyMaterialModel.fromJson(response);
  }

  Future<List<StudyMaterialModel>> fetchRecentMaterials(String facultyId) async {
    final response = await _client
        .from('study_materials')
        .select()
        .eq('faculty_id', facultyId)
        .order('uploaded_at', ascending: false);

    return (response as List)
        .map((item) => StudyMaterialModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}