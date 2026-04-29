import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/faculty_upload_model.dart';

class FacultyUploadService {
  FacultyUploadService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<FacultyUploadModel>> fetchRecentUploads(String facultyId) async {
    final response = await _client
        .from('v_faculty_uploads')
        .select()
        .eq('faculty_id', facultyId)
        .order('uploaded_at', ascending: false);
    return (response as List).map((json) => FacultyUploadModel.fromJson(json)).toList();
  }

  Future<void> deleteUpload(String id, String contentType) async {
    final table = contentType == 'video' ? 'video_lectures' : 'study_materials';
    await _client.from(table).delete().eq('id', id);
  }

  Future<void> updateUpload({
    required String id,
    required String contentType,
    required String title,
    required String description,
    required bool isVisible,
  }) async {
    final table = contentType == 'video' ? 'video_lectures' : 'study_materials';
    await _client.from(table).update({
      'title': title,
      'description': description,
      'is_visible': isVisible,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> toggleVisibility(String id, String contentType, bool isVisible) async {
    final table = contentType == 'video' ? 'video_lectures' : 'study_materials';
    await _client.from(table).update({
      'is_visible': isVisible,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}
