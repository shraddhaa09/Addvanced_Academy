import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/faculty_upload_model.dart';

class FacultyUploadService {
  final SupabaseClient _client;
  FacultyUploadService(this._client);

  // -------------------------------
  // Internal helpers
  // -------------------------------

  String _resolveTable(String contentType) {
    switch (contentType) {
      case 'video':
        return 'video_lectures';
      case 'material':
        return 'study_materials';
      default:
        throw ArgumentError('Invalid contentType: $contentType');
    }
  }

  void _handleError(dynamic error) {
    if (error is PostgrestException) {
      throw Exception('Database error: ${error.message}');
    } else {
      throw Exception('Unexpected error: $error');
    }
  }

  // -------------------------------
  // Fetch
  // -------------------------------

  Future<List<FacultyUploadModel>> fetchRecentUploads(String facultyId) async {
    try {
      final response = await _client
          .schema('academy')
          .from('v_faculty_uploads')
          .select()
          .eq('faculty_id', facultyId)
          .order('uploaded_at', ascending: false);

      return (response as List)
          .map((json) => FacultyUploadModel.fromJson(json))
          .toList();
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // -------------------------------
  // Delete (safe + verified)
  // -------------------------------

  Future<void> deleteUpload(String id, String contentType) async {
    final table = _resolveTable(contentType);
    debugPrint('[FacultyUploadService.deleteUpload] id=$id table=$table');

    late List<dynamic> response;

    // Step 1: execute the delete and capture any Supabase/network error
    try {
      response = await _client
          .schema('academy')
          .from(table)
          .delete()
          .eq('id', id)
          .select();
      debugPrint('[FacultyUploadService.deleteUpload] rows affected: ${response.length}');
    } on PostgrestException catch (e) {
      debugPrint('[FacultyUploadService.deleteUpload] PostgrestException: ${e.message} | code=${e.code}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      debugPrint('[FacultyUploadService.deleteUpload] Unexpected error: $e');
      throw Exception('Unexpected error while deleting: $e');
    }

    // Step 2: verify something was actually deleted
    // An empty list means RLS blocked it or the row doesn't exist.
    if (response.isEmpty) {
      debugPrint('[FacultyUploadService.deleteUpload] Empty response — likely RLS denial or wrong ID');
      throw Exception(
        'Could not delete "$id" from $table. '
        'Check that the record exists and that your RLS policy allows DELETE.',
      );
    }
  }

  // -------------------------------
  // Update (validated + atomic)
  // -------------------------------

  Future<void> updateUpload({
    required String id,
    required String contentType,
    required String title,
    required String description,
    required bool isVisible,
  }) async {
    final table = _resolveTable(contentType);

    if (title.trim().length < 2) {
      throw Exception('Title must be at least 2 characters');
    }

    try {
      final response = await _client
          .schema('academy')
          .from(table)
          .update({
            'title': title.trim(),
            'description': description.trim(),
            'is_visible': isVisible,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select();

      if (response == null || (response as List).isEmpty) {
        throw Exception('Update failed: Record with ID $id not found in $table or permission denied.');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // -------------------------------
  // Toggle visibility (lightweight update)
  // -------------------------------

  Future<void> toggleVisibility({
    required String id,
    required String contentType,
    required bool isVisible,
  }) async {
    final table = _resolveTable(contentType);

    try {
      final response = await _client
          .schema('academy')
          .from(table)
          .update({
            'is_visible': isVisible,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select();

      if (response == null || (response as List).isEmpty) {
        throw Exception('Toggle failed: Record with ID $id not found in $table or permission denied.');
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
}