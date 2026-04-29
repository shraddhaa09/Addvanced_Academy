import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/announcement_model.dart';

class AnnouncementService {
  final SupabaseClient _client;
  AnnouncementService(this._client);

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

  Future<List<AnnouncementModel>> fetchFacultyAnnouncements(String facultyId) async {
    try {
      final response = await _client
          .schema('academy')
          .from('announcements')
          .select()
          .eq('faculty_id', facultyId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AnnouncementModel.fromJson(json))
          .toList();
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<List<AnnouncementModel>> fetchStudentAnnouncements(String batch) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _client
          .schema('academy')
          .from('announcements')
          .select()
          .eq('target_batch', batch)
          .or('expires_at.is.null,expires_at.gt.$now')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AnnouncementModel.fromJson(json))
          .toList();
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // -------------------------------
  // CRUD
  // -------------------------------

  Future<void> createAnnouncement({
    required String facultyId,
    required String title,
    required String message,
    required String targetBatch,
    String? subject,
    DateTime? expiresAt,
  }) async {
    try {
      await _client.schema('academy').from('announcements').insert({
        'faculty_id': facultyId,
        'title': title,
        'message': message,
        'target_batch': targetBatch,
        'subject': subject,
        'expires_at': expiresAt?.toIso8601String(),
      });
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> updateAnnouncement(String id, Map<String, dynamic> updates) async {
    try {
      await _client
          .schema('academy')
          .from('announcements')
          .update(updates)
          .eq('id', id);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    try {
      await _client.schema('academy').from('announcements').delete().eq('id', id);
    } catch (e) {
      _handleError(e);
    }
  }
}
